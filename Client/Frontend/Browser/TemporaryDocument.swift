/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Deferred
import Shared

private let temporaryDocumentOperationQueue = OperationQueue()

class BATEphemeralCookieStorage: HTTPCookieStorage {
    private var _allCookies: [String: HTTPCookie]
    private let queue = DispatchQueue(label: "org.bat.cookie.storage.queue")
    
    private var allCookies: [String: HTTPCookie] {
        get {
            dispatchPrecondition(condition: DispatchPredicate.onQueue(self.queue))
            return self._allCookies
        }
        set {
            dispatchPrecondition(condition: DispatchPredicate.onQueue(self.queue))
            self._allCookies = newValue
        }
    }

    override init() {
        _allCookies = [:]
        super.init()
        cookieAcceptPolicy = .always
    }
    
    override var cookies: [HTTPCookie]? {
        return Array(self.queue.sync { self.allCookies.values })
    }
    
    override func setCookie(_ cookie: HTTPCookie) {
        self.queue.sync {
            guard cookieAcceptPolicy != .never else { return }
            
            let key = cookie.domain + cookie.path + cookie.name
            if allCookies.index(forKey: key) != nil {
                allCookies.updateValue(cookie, forKey: key)
            } else {
                allCookies[key] = cookie
            }
            
            let expired = allCookies.filter { (_, value) in
                value.expiresDate != nil && value.expiresDate!.timeIntervalSinceNow < 0
            }
            
            for key in expired.keys {
                self.allCookies.removeValue(forKey: key)
            }
        }
    }
    
    override func deleteCookie(_ cookie: HTTPCookie) {
        self.queue.sync {
            let key = cookie.domain + cookie.path + cookie.name
            self.allCookies.removeValue(forKey: key)
        }
    }
    
    override func removeCookies(since date: Date) {
        self.queue.sync {
            let cookiesSinceDate = self.allCookies.values.filter {
                if let creationDate = $0.properties?[HTTPCookiePropertyKey(rawValue: "created")] as? Double {
                    return creationDate >  date.timeIntervalSinceReferenceDate
                }
                return false
            }
            
            for cookie in cookiesSinceDate {
                let key = cookie.domain + cookie.path + cookie.name
                self.allCookies.removeValue(forKey: key)
            }
        }
    }
    
    override func cookies(for url: URL) -> [HTTPCookie]? {
        guard let host = url.host?.lowercased() else { return nil }
        return Array(self.queue.sync(execute: { allCookies }).values.filter {
            guard $0.domain.hasPrefix(".") else { return host == $0.domain }
            return host == $0.domain.dropFirst() || host.hasSuffix($0.domain)
        })
    }
    
    override func setCookies(_ cookies: [HTTPCookie], for url: URL?, mainDocumentURL: URL?) {
        guard cookieAcceptPolicy != .never else { return }
        guard let urlHost = url?.host?.lowercased() else { return }
        
        if mainDocumentURL != nil && cookieAcceptPolicy == .onlyFromMainDocumentDomain {
            guard let mainDocumentHost = mainDocumentURL?.host?.lowercased() else { return }
            guard mainDocumentHost.hasSuffix(urlHost) else { return }
        }
        
        let validCookies = cookies.filter {
            guard $0.domain.hasPrefix(".") else { return urlHost == $0.domain }
            return urlHost == $0.domain.dropFirst() || urlHost.hasSuffix($0.domain)
        }
        
        for cookie in validCookies {
            setCookie(cookie)
        }
    }
    
    override var cookieAcceptPolicy: HTTPCookie.AcceptPolicy {
        get {
            return .always
        }
        
        set {
            
        }
    }
    
    override func sortedCookies(using sortOrder: [NSSortDescriptor]) -> [HTTPCookie] {
        return queue.sync {
            let cookies = Array(allCookies.values) as NSArray
            return cookies.sortedArray(using: sortOrder) as? [HTTPCookie] ?? []
        }
    }
    
    override var description: String {
        return "Ephemeral <BATMemoryCookieStorage cookies count:\(cookies?.count ?? 0)>"
    }
    
    func apply(to request: URLRequest) -> URLRequest {
        if let url = request.url, let cookies = self.cookies(for: url) {
            var headers = request.allHTTPHeaderFields ?? [:]
            HTTPCookie.requestHeaderFields(with: cookies).forEach({
                headers.updateValue($0.value, forKey: $0.key)
            })
            
            var result = request
            result.allHTTPHeaderFields = headers
            return result
        }
        
        return request
    }
}

class TemporaryDocument: NSObject {
    fileprivate let request: URLRequest
    fileprivate let filename: String

    fileprivate var session: URLSession?

    fileprivate var downloadTask: URLSessionDownloadTask?
    fileprivate var localFileURL: URL?
    fileprivate var pendingResult: Deferred<URL>?
    fileprivate let cookieStorage = BATEphemeralCookieStorage()

    init(preflightResponse: URLResponse, request: URLRequest) {
        self.request = request
        self.filename = preflightResponse.suggestedFilename ?? "unknown"

        super.init()

        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: temporaryDocumentOperationQueue).then {
            $0.configuration.httpCookieStorage = self.cookieStorage
            $0.configuration.httpCookieAcceptPolicy = .always
            $0.configuration.httpShouldSetCookies = true
        }
    }

    deinit {
        // Delete the temp file.
        if let url = localFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func setCookies(_ cookies: [HTTPCookie]?) {
        cookies?.forEach({
            self.cookieStorage.setCookie($0)
        })
    }

    func getURL() -> Deferred<URL> {
        if let url = localFileURL {
            let result = Deferred<URL>()
            result.fill(url)
            return result
        }

        if let result = pendingResult {
            return result
        }

        let result = Deferred<URL>()
        pendingResult = result
        
        downloadTask = session?.downloadTask(with: self.cookieStorage.apply(to: self.request))
        downloadTask?.resume()

        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        return result
    }
}

extension TemporaryDocument: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        ensureMainThread {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }

        // If we encounter an error downloading the temp file, just return with the
        // original remote URL so it can still be shared as a web URL.
        if error != nil, let remoteURL = request.url {
            pendingResult?.fill(remoteURL)
            pendingResult = nil
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TempDocs")
        let url = tempDirectory.appendingPathComponent(filename)

        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.removeItem(at: url)

        do {
            try FileManager.default.moveItem(at: location, to: url)
            localFileURL = url
            pendingResult?.fill(url)
            pendingResult = nil
        } catch {
            // If we encounter an error downloading the temp file, just return with the
            // original remote URL so it can still be shared as a web URL.
            if let remoteURL = request.url {
                pendingResult?.fill(remoteURL)
                pendingResult = nil
            }
        }
    }
}
