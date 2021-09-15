// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

private let REQUEST_KEY_PRIVILEGED = "privileged"

/**
 Request that is allowed to load local resources.

 Pages running on the local server have same origin access all resources
 on the server, so we need to prevent arbitrary web pages from accessing
 these resources. We do so by explicitly requiring "privileged" requests
 in our navigation policy when loading local resources.

 Be careful: creating a privileged request for an arbitrary URL provided
 by the page will break this model. Only use a privileged request when
 needed, and when you are sure the URL is from a trustworthy source!
 **/
public class PrivilegedRequest: NSMutableURLRequest {
    private static let key = "brave_prv"
    private static let value = UUID().uuidString.replacingOccurrences(of: "-", with: "")

    override init(url URL: URL, cachePolicy: NSURLRequest.CachePolicy, timeoutInterval: TimeInterval) {
        let modifyURL = { (url: URL) -> URL in
            if PrivilegedRequest.isWebServerRequest(url: url),
               let url = PrivilegedRequest.store(url: url) {
                return url
            }
            return url
        }

        super.init(url: modifyURL(URL), cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        setPrivileged()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setPrivileged()
    }

    private func setPrivileged() {
        URLProtocol.setProperty(true, forKey: REQUEST_KEY_PRIVILEGED, in: self)
    }

    private static func store(url: URL) -> URL? {
        guard var components = URLComponents(string: url.absoluteString) else { return nil }

        var queryItems = components.queryItems ?? []
        if var item = queryItems.find({ $0.name == PrivilegedRequest.key }) {
            item.value = PrivilegedRequest.value
        } else {
            let queryItem = URLQueryItem(name: PrivilegedRequest.key,
                                         value: PrivilegedRequest.value)
            queryItems.append(queryItem)
        }

        components.queryItems = queryItems
        return components.url
    }

    public static func removePrivileges(url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let items = components.queryItems else { return url }

        components.queryItems = items.filter { $0.name != PrivilegedRequest.key }
        if let items = components.queryItems,
            items.isEmpty {
            components.queryItems = nil
        }
        return components.url
    }

    public static func isPrivileged(url: URL?) -> Bool {
        if let value = url?.getQuery()[PrivilegedRequest.key],
           !value.isEmpty,
           value == PrivilegedRequest.value {
            return true
        }
        return false
    }

    public static func isWebServerRequest(url: URL) -> Bool {
        url.absoluteString.hasPrefix("http://localhost:\(AppConstants.webServerPort)/")
    }
}

extension URLRequest {
    public var isPrivileged: Bool {
        if PrivilegedRequest.isPrivileged(url: url) {
            return true
        }

        return URLProtocol.property(forKey: REQUEST_KEY_PRIVILEGED, in: self) != nil
    }
}
