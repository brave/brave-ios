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

class BraveSearchManager {
    struct CanAnswerResponse: Codable {
        let found: Bool
    }
    
    /// URL of the Brave Search request.
    private let url: URL
    private let query: String
    
    var queryResult: String?
    
    private var cancellables: Set<AnyCancellable> = []
    
    static func isValidURL(_ url: URL) -> Bool {
        let validURLs = AppConstants.buildChannel.isPublic ?
            ["search.brave.com"] : ["search.brave.com", "search-dev.brave.com"]
        
        return validURLs.contains(url.host ?? "")
    }
    
    static func credentials(for url: URL) -> [String: URLCredential]? {
        let protectionSpace = URLProtectionSpace(host: url.domainURL.baseDomain ?? url.domainURL.host ?? url.domainURL.absoluteString,
                                                 port: 443,
                                                 protocol: "https",
                                                 realm: "Restricted",
                                                 authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
        return URLCredentialStorage.shared.credentials(for: protectionSpace)
    }
    
    static func handleAuthChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let authMethod = challenge.protectionSpace.authenticationMethod
        if authMethod == NSURLAuthenticationMethodDefault || authMethod == NSURLAuthenticationMethodHTTPBasic || authMethod == NSURLAuthenticationMethodHTTPDigest {
            
            // Use previous credentials
            if let proposedCredential = challenge.proposedCredential {
                if !(proposedCredential.user?.isEmpty ?? true) && challenge.previousFailureCount == 0 {
                    completionHandler(.useCredential, proposedCredential)
                    return
                }
            }
            
            // Remove bad credentials
            if challenge.previousFailureCount > 0, let proposedCredential = challenge.proposedCredential {
                URLCredentialStorage.shared.remove(proposedCredential, for: challenge.protectionSpace)
            }
            
            if let credentials = URLCredentialStorage.shared.credentials(for: challenge.protectionSpace) {
                if credentials.count == 1, let credential = credentials.first?.value {
                    completionHandler(.useCredential, credential)
                    return
                }
                
                // Destroy all credentials. There should only ever be ONE set stored
                credentials.forEach({
                    URLCredentialStorage.shared.remove($0.value, for: challenge.protectionSpace)
                })
            }
            
            let alert = UIAlertController(title: challenge.protectionSpace.host,
                                       message: "This page requires authentication",
                                       preferredStyle: .alert)
            alert.addTextField {
                $0.placeholder = "User"
            }
            
            alert.addTextField {
                $0.placeholder = "Password"
                $0.isSecureTextEntry = true
            }
            
            alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { _ in
                guard let user = alert.textFields?.first?.text,
                      let password = alert.textFields?.last?.text else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    return
                }
                
                // User CANNOT contain a colon
                guard !user.contains(":") else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                    return
                }
                
                let credential = URLCredential(user: user, password: password, persistence: .forSession) // permanent?
                
                // Store the credential potentially. If it doesn't work and challenge failed, we'll destroy it anyway.
                URLCredentialStorage.shared.setDefaultCredential(credential, for: challenge.protectionSpace)
                completionHandler(.useCredential, credential)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                completionHandler(.cancelAuthenticationChallenge, nil)
            }))
            
            (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.present(alert, animated: true, completion: nil)
        }
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
        
        // There should NEVER be more than one credential, if there is, we have a problem storing failed credentials
        // Add the credentials we have to the Authorization header of the request
        if let credentials = BraveSearchManager.credentials(for: url),
           credentials.count == 1,
           let credentialPair = credentials.first {
            
            let user = credentialPair.value.user ?? credentialPair.key
            let password = credentialPair.value.password ?? ""
            
            let auth = String(format: "%@:%@", user, password).toBase64()
            request.addValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        }
        
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
        
        URLSession(configuration: .ephemeral)
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
