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

class BraveSearchManager: NSObject {
    struct CanAnswerResponse: Codable {
        let found: Bool
    }
    
    /// URL of the Brave Search request.
    private let url: URL
    private let query: String
    
    var queryResult: String?
    
    private var cancellables: Set<AnyCancellable> = []
    private static var cachedCredentials: URLCredential?
    
    static func isValidURL(_ url: URL) -> Bool {
        let validURLs = AppConstants.buildChannel.isPublic ?
            ["search.brave.com"] : ["search.brave.com", "search-dev.brave.com"]
        
        return validURLs.contains(url.host ?? "")
    }
    
    init?(url: URL) {
        // Check if request is accessed from valid Brave Search domains
        let validURLs = AppConstants.buildChannel.isPublic ?
            ["search.brave.com"] : ["search.brave.com", "search-dev.brave.com"]
        
        if !Self.isValidURL(url) {
            return nil
        }
        
        // Check if the request has a valid query string to check against.
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItem = components.valueForQuery("q") else { return nil }
        
        self.url = url
        self.query = queryItem
    }
    
    func shouldUseFallback(cookies: [HTTPCookie], completion: @escaping (Bool) -> Void) {
        let url = URL(string: "\(url.domainURL)/api/can_answer?q=\(query)")!
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 5)

        // Doesn't work because this cookie storage is created right there. It is local, not permanent
        let cookieStorage = HTTPCookieStorage()
        cookies.forEach { cookieStorage.setCookie($0) }
        
        // does not work for some reason
        //let domainCookies = cookieStorage.cookies(for: url) ?? []
        let domainCookies = cookies.filter { $0.domain == url.host }
        let headers = HTTPCookie.requestHeaderFields(with: domainCookies)
        headers.forEach {
            request.setValue($0.key, forHTTPHeaderField: $0.value)
        }
        
        URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
            .dataTaskPublisher(for: request)
            .tryMap { output -> CanAnswerResponse in
                guard let response = output.response as? HTTPURLResponse,
                      response.statusCode >= 200 && response.statusCode < 300 else {
                    throw "Invalid response"
                }
     
                let canAnswerResponse = try JSONDecoder().decode(CanAnswerResponse.self, from: output.data)
                
                return canAnswerResponse
            }
            .sink(receiveCompletion: { status in
                switch status {
                case .failure(let error):
                    log.error("shouldUseFallback error: \(error)")
                    completion(false)
                case .finished:
                    // Completion is called on `receiveValue`.
                    break
                }
            }, receiveValue: { data in
                print("data.found: \(data.found)")
                completion(data.found)
            })
            .store(in: &cancellables)
    }
    
    func backupSearch(completion: @escaping (String) -> Void) {
        
        guard var components = URLComponents(string: "https://www.google.com") else { return }
        // TODO: Pass correct country ang language params
        components.queryItems = [.init(name: "q", value: query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)),
                                 .init(name: "hl", value: "en"),
                                 .init(name: "gl", value: "us")]
        
        guard let url = components.url else { return }
        let request = URLRequest(url: url, timeoutInterval: 3)
        
        URLSession(configuration: .ephemeral)
            .dataTaskPublisher(for: request)
            .tryMap { output -> String in
                guard let response = output.response as? HTTPURLResponse,
                      let contentType = response.value(forHTTPHeaderField: "Content-Type"),
                      response.statusCode >= 200 && response.statusCode < 300 else {
                    throw "Invalid response"
                }
                
                // For some reason sometimes no matter what headers are set, ISO encoding is returned
                // instead of utf, we check for that to decode it correctly.
                let encoding: String.Encoding =
                    contentType.contains("ISO-8859-1") ? .isoLatin1 : .utf8
                
                guard let stringFromData = String(data: output.data, encoding: encoding) else {
                    throw "Failed to decode string from data"
                }
                
                return stringFromData.javaScriptEscapedString
            }
            .eraseToAnyPublisher()
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
                self?.queryResult = data
                completion(data)
            })
            .store(in: &cancellables)
    }
}

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
