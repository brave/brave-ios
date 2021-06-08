// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Combine
import Shared
import BraveShared
import WebKit

private let log = Logger.browserLogger

// A helper class to handle Brave Search fallback needs.
class BraveSearchManager: NSObject {
    private let fallbackProviderURLString = "https://www.google.com/search"
    
    /// Brave Search query details which are passed to the fallback provider.
    struct BackupQuery: Codable {
        let found: Bool
        let country: String?
        let language: String?
        let safesearch: String?
    }
    
    /// URL of the Brave Search request we performed.
    /// Contains a query and endpoint(prod or staging)
    private let url: URL
    /// What did we search for using Brave Search
    private let query: String
    /// BraveSearch cookies are used to pass search settings we saved on the website
    /// such as whether to use search fallback, should safe search be performed etc.
    private let domainCookies: [HTTPCookie]
    
    /// The result we got from querying the fallback search engine.
    var fallbackQueryResult: String?
    /// Whether the call to the fallback search engine is pending.
    /// This is used to determine at what point of the web navigation we should inject the results.
    var fallbackQueryResultsPending = false
    
    private var cancellables: Set<AnyCancellable> = []
    private static var cachedCredentials: URLCredential?
    
    static func isValidURL(_ url: URL) -> Bool {
        let validURLs = AppConstants.buildChannel.isPublic ?
            ["search.brave.com"] : ["search.brave.com", "search-dev.brave.com"]
        
        return validURLs.contains(url.host ?? "")
    }
    
    init?(url: URL, cookies: [HTTPCookie]) {
        if !Self.isValidURL(url) {
            return nil
        }
        
        // Check if the request has a valid query string to check against.
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItem = components.valueForQuery("q") else { return nil }
        
        self.url = url
        self.query = queryItem
        self.domainCookies = cookies.filter { $0.domain == url.host }
        if domainCookies.first(where: { $0.name == "fallback" })?.value != "1" {
            return nil
        }
    }
    
    /// A call is made to the Brave Search api with query we performed.
    /// It returns  details that are used in call to the fallback search engine.
    func shouldUseFallback(completion: @escaping (BackupQuery?) -> Void) {
        guard var canAnswerURLComponents =
                URLComponents(string: url.domainURL.absoluteString) else {
            completion(nil)
            return
        }
        
        canAnswerURLComponents.scheme = "https"
        canAnswerURLComponents.path = "/api/can_answer"
        canAnswerURLComponents.queryItems = [.init(name: "q", value: query)]
        
        guard let url = canAnswerURLComponents.url else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 5)

        let cookieStorage = HTTPCookieStorage()
        domainCookies.forEach { cookieStorage.setCookie($0) }
        
        let domainCookies = domainCookies.filter { $0.domain == canAnswerURLComponents.host }
        let headers = HTTPCookie.requestHeaderFields(with: domainCookies)
        headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
        
        // Important, URLSessionDelegate must have been implemented here
        // to handle request authentication.
        session
            .dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse,
                      response.statusCode >= 200 && response.statusCode < 300 else {
                    throw "Invalid response"
                }
     
                return output.data
            }
            .decode(type: BackupQuery.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { status in
                switch status {
                case .failure(let error):
                    log.error("shouldUseFallback error: \(error)")
                    // No subsequent call to backup search engine is made in case of error.
                    // The pending status has to be cancelled.
                    completion(nil)
                case .finished:
                    // Completion is called on `receiveValue`.
                    break
                }
            }, receiveValue: { canAnswer in
                completion(canAnswer)
            })
            .store(in: &cancellables)
        
        session.finishTasksAndInvalidate()
    }
    
    /// Perform a backup search using an alternative search engine, gets results back as html source.
    func backupSearch(with backupQuery: BackupQuery,
                      completion: @escaping (String) -> Void) {
        
        guard var components = URLComponents(string: fallbackProviderURLString) else { return }
        
        var queryItems: [URLQueryItem] = [
            .init(name: "q", value: query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))]
        
        if let language = backupQuery.language {
            queryItems.append(.init(name: "hl", value: language))
        }
        
        if let country = backupQuery.country {
            queryItems.append(.init(name: "gl", value: country))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else { return }
        var request = URLRequest(url: url, timeoutInterval: 5)
        
        // Must be set, without it the fallback results may be not retrieved correctly.
        request.addValue(UserAgent.userAgentForDesktopMode, forHTTPHeaderField: "User-Agent")
        
        URLSession(configuration: .ephemeral)
            .dataTaskPublisher(for: request)
            .tryMap { output -> String in
                guard let response = output.response as? HTTPURLResponse,
                      let contentType = response.value(forHTTPHeaderField: "Content-Type"),
                      response.statusCode >= 200 && response.statusCode < 300 else {
                    throw "Invalid response"
                }
                
                // For some reason sometimes no matter what headers are set, ISO encoding is returned
                // we check for iso and fallback to utf8 by default.
                let encoding: String.Encoding =
                    contentType.contains("ISO-8859-1") ? .isoLatin1 : .utf8
                
                guard let stringFromData = String(data: output.data, encoding: encoding) else {
                    throw "Failed to decode string from data"
                }
                
                return stringFromData.javaScriptEscapedString
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    log.error("Error: \(error)")
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] data in
                self?.fallbackQueryResult = data
                completion(data)
            })
            .store(in: &cancellables)
    }
}

// MARK: - URLSessionDataDelegate
// The BraveSearch feature can be hidden behind an authentication system.
// This code helps passing all auth info to the requests we make.
extension BraveSearchManager: URLSessionDataDelegate {
    
    private func findLoginsForProtectionSpace(profile: Profile, challenge: URLAuthenticationChallenge, completion: @escaping (URLCredential?) -> Void) {
        profile.logins.getLoginsForProtectionSpace(challenge.protectionSpace) >>== { cursor in
            guard cursor.count >= 1 else {
                completion(nil)
                return
            }

            let logins = cursor.asArray()
            var credentials: URLCredential?

            if logins.count > 1 {
                credentials = (logins.find { login in
                    (login.protectionSpace.`protocol` == challenge.protectionSpace.`protocol`) && !login.hasMalformedHostname
                })?.credentials
            } else if logins.count == 1, logins.first?.protectionSpace.`protocol` != challenge.protectionSpace.`protocol` {
                credentials = logins.first?.credentials
            } else {
                credentials = logins.first?.credentials
            }
            
            completion(credentials)
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let validURLs = AppConstants.buildChannel.isPublic ?
            ["search.brave.com"] : ["search.brave.com", "search-dev.brave.com"]
        if !validURLs.contains(challenge.protectionSpace.host) {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // -- Handle Authentication --
        
        // Too many failed attempts
        if challenge.previousFailureCount >= 3 {
            completionHandler(.rejectProtectionSpace, nil)
            return
        }
        
        if let credentials = BraveSearchManager.cachedCredentials {
            completionHandler(.useCredential, credentials)
            return
        }

        if let proposedCredential = challenge.proposedCredential,
           !(proposedCredential.user?.isEmpty ?? true),
           challenge.previousFailureCount == 0 {
            completionHandler(.useCredential, proposedCredential)
            return
        }

        // There is only ever ONE profile and all tabs share it afaict
        let profile = { () -> Profile? in
            if Thread.current.isMainThread {
                return (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.profile
            }
            
            return DispatchQueue.main.sync {
                (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.profile
            }
        }()
        
        // Lookup the credentials
        // If there is no profile or the challenge is not an auth challenge, reject the challenge
        guard let profile = profile else {
            completionHandler(.rejectProtectionSpace, nil)
            return
        }
        
        self.findLoginsForProtectionSpace(profile: profile, challenge: challenge, completion: { credential in
            if let credential = credential {
                BraveSearchManager.cachedCredentials = credential
                
                completionHandler(.useCredential, credential)
                return
            }
            
            completionHandler(.rejectProtectionSpace, nil)
        })
        return
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
}
