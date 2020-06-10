// Copyright (c) 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at https://mozilla.org/MPL/2.0/. */

import Foundation
import CommonCrypto
import Shared

private let log = Logger.browserLogger

extension SafeBrowsing {
    enum SafeBrowsingResult {
        case safe
        case dangerous(ThreatType)
        case unknown
    }

    class SafeBrowsingClient {
        private static let apiKey = "DUMMY_KEY"
        private static let maxBandwidth = 2048 //Maximum amount of results we can process per threat-type
        private static let maxDatabaseEntries = 250000 //Maximum amount of entries our database can hold per threat-type
        private static let clientId = AppInfo.baseBundleIdentifier
        private static let version = AppInfo.appVersion
        
        //This user-agent is only used for communicating with Brave's proxy server so that it knows iOS is making the request.
        //Therefore, we don't care if the user is in Desktop mode or not.
        private let userAgent = UserAgent.mobile
        private let baseURL = "https://safebrowsing.brave.com"
        private let session = URLSession(configuration: .ephemeral)
        private let database = SafeBrowsingDatabase()
        private let cache = SafeBrowsingCache()
        
        public static let shared = SafeBrowsingClient()
        
        private init() {
            database.scheduleUpdate { [weak self] in
                self?.fetch {
                    if let error = $0 {
                        log.error(error)
                    }
                }
            }
        }
        
        func find(_ hashes: [String], _ completion: @escaping (_ isSafe: SafeBrowsingResult, Error?) -> Void) {
            let group = DispatchGroup()
            var potentiallyBadHashes = [String: [ThreatType]]()
            var definitelyBadHashes = [String: [ThreatType]]()
            
            for fullHash in hashes {
                group.enter()
                self.database.find(fullHash) { hash in
                    
                    if hash.isEmpty {
                        return group.leave()
                    }
                    
                    let result = self.cache.find(fullHash)
                    switch result.cacheResult {
                    case .positive:
                        if var threats = definitelyBadHashes[fullHash] {
                            threats.append(contentsOf: result.threats)
                        } else {
                            definitelyBadHashes.updateValue(result.threats, forKey: fullHash)
                        }
                        
                    case .negative:
                        return group.leave()
                        
                    case .miss:
                        if var threats = potentiallyBadHashes[hash] {
                            threats.append(contentsOf: result.threats)
                        } else {
                            potentiallyBadHashes.updateValue(result.threats, forKey: hash)
                        }
                    }
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .global(qos: .background)) {
                if !self.database.canFind() {
                    if !potentiallyBadHashes.isEmpty {
                        completion(.unknown, nil)
                        return
                    }
                    
                    completion(definitelyBadHashes.isEmpty ? .safe : self.classify(hashes: definitelyBadHashes), nil)
                    return
                }
                
                if potentiallyBadHashes.isEmpty {
                    completion(definitelyBadHashes.isEmpty ? .safe : self.classify(hashes: definitelyBadHashes), nil)
                    return
                }
                
                let clientInfo = ClientInfo(clientId: SafeBrowsingClient.clientId,
                                            clientVersion: SafeBrowsingClient.version)
                
                let threatTypes: [ThreatType] = [.malware,
                                                 .socialEngineering,
                                                 .unwantedSoftware,
                                                 .potentiallyHarmfulApplication]
                
                let platformTypes: [PlatformType] = [.ios]
                let threatEntryTypes: [ThreatEntryType] = [.url, .exe]
                
                let threatInfo = ThreatInfo(threatTypes: threatTypes,
                                            platformTypes: platformTypes,
                                            threatEntryTypes: threatEntryTypes,
                                            threatEntries: potentiallyBadHashes.map {
                                                return ThreatEntry(hash: $0.key, url: nil, digest: nil)
                    }
                )
                
                do {
                    let body = FindRequest(client: clientInfo, threatInfo: threatInfo)
                    let request = try self.encode(.post, endpoint: .fullHashes, body: body)
                    self.executeRequest(request, type: FindResponse.self) { [weak self] response, error in
                        guard let self = self else { return }
                        
                        if error != nil {
                            self.database.enterBackoffMode(.find)
                        }
                        
                        DispatchQueue.global(qos: .background).async {
                            if let error = error {
                                completion(definitelyBadHashes.isEmpty ? .unknown : self.classify(hashes: definitelyBadHashes), error)
                                return
                            }
                            
                            if let response = response {
                                self.cache.update(body, response)
                                
                                if !response.matches.isEmpty {
                                    //Positive Results
                                    response.matches.forEach { match in
                                        if let hash = match.threat.hash, hashes.contains(hash) {
                                            if var threats = definitelyBadHashes[hash] {
                                                threats.append(match.threatType)
                                            } else {
                                                definitelyBadHashes.updateValue([match.threatType], forKey: hash)
                                            }
                                        }
                                    }
                                }
                                completion(definitelyBadHashes.isEmpty ? .safe : self.classify(hashes: definitelyBadHashes), nil)
                                return
                            }
                            completion(definitelyBadHashes.isEmpty ? .unknown : self.classify(hashes: definitelyBadHashes), nil)
                            return
                        }
                    }
                } catch {
                    DispatchQueue.global(qos: .background).async {
                        completion(definitelyBadHashes.isEmpty ? .unknown : self.classify(hashes: definitelyBadHashes), error)
                    }
                }
            }
        }
        
        func fetch(_ completion: @escaping (Error?) -> Void) {
            if !database.canUpdate() {
                completion(SafeBrowsingError("Database already up to date"))
                return
            }
            
            let clientInfo = ClientInfo(clientId: SafeBrowsingClient.clientId,
                                        clientVersion: SafeBrowsingClient.version)
            
            let constraints = Constraints(maxUpdateEntries: UInt32(SafeBrowsingClient.maxBandwidth),
                                          maxDatabaseEntries: UInt32(SafeBrowsingClient.maxDatabaseEntries),
                                          region: Locale.current.regionCode ?? "US",
                                          supportedCompressions: [.raw],
                                          language: nil,
                                          deviceLocation: nil)
            
            let lists = [
                ListUpdateRequest(threatType: .malware,
                                  platformType: .ios,
                                  threatEntryType: .url,
                                  state: database.getState(.malware),
                                  constraints: constraints),
                
                ListUpdateRequest(threatType: .socialEngineering,
                                  platformType: .ios,
                                  threatEntryType: .url,
                                  state: database.getState(.socialEngineering),
                                  constraints: constraints),
                
                ListUpdateRequest(threatType: .potentiallyHarmfulApplication,
                                  platformType: .ios,
                                  threatEntryType: .url,
                                  state: database.getState(.potentiallyHarmfulApplication),
                                  constraints: constraints)
            ]
            
            do {
                let body = FetchRequest(client: clientInfo, listUpdateRequests: lists)
                let request = try encode(.post, endpoint: .fetch, body: body)
                executeRequest(request, type: FetchResponse.self) { [weak self] response, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.database.enterBackoffMode(.update)
                        self.database.scheduleUpdate { [weak self] in
                            self?.fetch {
                                if let error = $0 {
                                    log.error(error)
                                }
                            }
                        }
                        completion(error)
                        return
                    }
                    
                    if let response = response {
                        var didError = false
                        self.database.update(response, completion: {
                            if let error = $0 {
                                log.error("Safe-Browsing: Error Updating Database: \(error)")
                                didError = true
                            }
                        })
                        
                        self.database.scheduleUpdate { [weak self] in
                            self?.fetch(completion)
                        }
                        
                        if !didError {
                            self.cache.purge()
                        }
                        
                        completion(didError ? SafeBrowsingError("Safe-Browsing: Error Updating Database") : nil)
                        return
                    }
                    
                    completion(nil)
                }
            } catch {
                completion(error)
            }
        }
        
        private func classify(hashes: [String: [ThreatType]]) -> SafeBrowsingResult {
            var isUnspecified = false
            var isMalware = false
            var isSocialEngineering = false
            var isUnwantedSoftware = false
            var isPotentiallyHarmful = false
            
            //Short Circuit Classification of Threats
            hashes.values.flatMap({ $0 }).forEach {
                isUnspecified = isUnspecified || $0 == .unspecified
                isMalware = isMalware || $0 == .malware
                isSocialEngineering = isSocialEngineering || $0 == .socialEngineering
                isUnwantedSoftware = isUnwantedSoftware || $0 == .unwantedSoftware
                isPotentiallyHarmful = isPotentiallyHarmful || $0 == .potentiallyHarmfulApplication
            }
            
            //Return the order of highest severity first..
            if isMalware {
                return .dangerous(.malware)
            }
            
            if isSocialEngineering {
                return .dangerous(.socialEngineering)
            }
            
            if isUnwantedSoftware {
                return .dangerous(.unwantedSoftware)
            }
            
            if isPotentiallyHarmful {
                return .dangerous(.potentiallyHarmfulApplication)
            }
            
            return .dangerous(.unspecified)
        }
        
        private func encode<T>(_ method: RequestType, endpoint: Endpoint, body: T) throws -> URLRequest where T: Encodable {
            
            let urlPath = "\(baseURL)\(endpoint.rawValue)?key=\(SafeBrowsingClient.apiKey)"
            
            guard let url = URL(string: urlPath) else {
                throw SafeBrowsingError("Invalid Request")
            }
            
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            request.httpBody = try JSONEncoder().encode(body)
            
            return request
        }
        
        @discardableResult
        private func executeRequest<T>(_ request: URLRequest, type: T.Type, completion: @escaping (T?, Error?) -> Void) -> URLSessionDataTask where T: Decodable {
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, SafeBrowsingError("Invalid Server Response: No Data"))
                    return
                }
                
                if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                    do {
                        let error = try JSONDecoder().decode(ResponseError.self, from: data)
                        completion(nil, SafeBrowsingError(error.message, code: error.code))
                        return
                    } catch {
                        completion(nil, error)
                        return
                    }
                }
                
                do {
                    let response = try JSONDecoder().decode(type, from: data)
                    completion(response, nil)
                } catch {
                    completion(nil, error)
                }
            }
            task.resume()
            return task
        }
        
        private enum RequestType: String {
            case get = "GET"
            case post = "POST"
        }
        
        private enum Endpoint: String {
            case fetch = "/v4/threatListUpdates:fetch"
            case fullHashes = "/v4/fullHashes:find"
        }
    }
    
    /// iOS URL and URLComponents conform to RFC-1808 URL spec.
    /// However, iOS is not only out-dated, but it is NOT fully spec compliant.
    /// `https://evil.com/foo;` is a VALID URL and when escaped, it should be `https://evil.com/foo;`
    /// However, iOS encodes the `;` (semi-colon) character (a reserved character for path delimiter) which is WRONG..
    /// iOS `URL` and `URLComponents` encodes it as `https://evil.com/foo%3B` (this is wrong)
    /// Every other framework that conforms to RFC-3986 will NOT escape the path (this is correct).
    private static func specURLEscape(url: URL) -> URL {
        
        //Recursively unescape all escape sequences in the URL.
        //`http://host.com/%2525252525` will unescape to `http://host.com/%     `
        //1024 is the maximum stack depth for decoding chosen by me..
        //otherwise we will be infinitely decoding/unescaping since the `% ` is still found in the URL path.
        let unescape = { (url: String) -> String in
            var url = url
            for _ in 0..<1024 {
                let escapedURL = url.removingPercentEncoding
                if let escapedURL = escapedURL, escapedURL == url {
                    return escapedURL
                }
                
                if escapedURL == nil {
                    return url
                }
                url = escapedURL ?? url
            }
            return ""
        }
        
        let normalizedURL = unescape(url.absoluteString)
        if !normalizedURL.isEmpty {
            var buffer = [UInt8]()
            let characters = Array(normalizedURL.utf8)
            
            //Escapes a URL as per spec.
            //Same reasoning as above where URLComponents is wrong.
            //0x20 = space (ascii table)
            //0x7E = DEL (ascii table)
            //0x23 = #
            //0x25 = %
            for c in characters {
                if c < 0x20 || c > 0x7F || c == 0x20 || c == 0x23 || c == 0x25 {
                    buffer.append(contentsOf: Array(String(format: "%%%02x", c).utf8))
                } else {
                    buffer.append(c)
                }
            }
            
            return URL(string: String(bytes: buffer, encoding: .utf8) ?? url.absoluteString) ?? url
        }
        return url
    }
    
    private static func isValidIPAddress(string: String) -> Bool {
        //IPv6
        var sin6 = sockaddr_in6()
        if string.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
            return true
        }
        
        //IPv4
        var sin = sockaddr_in()
        if string.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
            return true
        }

        return false
    }

    //Converts an IPAddress from any valid format into IPv4's standard dotted notation.
    //IPAddresses can be decimal, hex, octal, and standard dotted notation format.
    private static func parseIPAddress(host: String) -> String {
        var host = host
        while host.hasSuffix(" ") {
            host.removeLast()
        }
        
        //Valid IP address regex.
        //IPv4 can be in standard dot notation, hex notation, octal notation, decimal notation.
        //IPv6 will have `[]` in the host.
        if host.range(of: #"^(?i)((?:0x[0-9a-f]+|[0-9\.])+)$"#, options: .regularExpression) == nil {
            return host
        }
        
        let parts = host.split(separator: ".")
        if parts.count > 4 { //IP addresses can have up to 4 octaves for 32-bit IPv4.
            return host
        }
        
        let canonicalize = {(string: String, components: Int) -> String in
            if components <= 0 || components >= 5 {
                return ""
            }
            
            if var component = UInt32(string) {
                var result = [String](repeating: "", count: components)
                for i in stride(from: components, to: 0, by: -1) {
                    result[i - 1] = String(Int(component) & 0xFF) //Clamp to 255 each octave.
                    component = component >> 8 //Shift to the next octave
                }
                return result.joined(separator: ".")
            }
            return ""
        }
        
        var result = [String](repeating: "", count: parts.count)
        for (i, component) in parts.enumerated() {
            if i == parts.count - 1 {
                result[i] = canonicalize(String(component), 5 - parts.count)
            } else {
                result[i] = canonicalize(String(component), 1)
            }
            
            if result[i] == "" {
                return ""
            }
        }
        
        return result.joined(separator: ".")
    }
    
    public static func canonicalize(url: URL) -> URL {
        var absoluteString = url.absoluteString
        
        if !absoluteString.contains("://") {
            absoluteString = "http://\(absoluteString)"
        }
        
        absoluteString = absoluteString.replacingOccurrences(of: "\t", with: "")
        absoluteString = absoluteString.replacingOccurrences(of: "\r", with: "")
        absoluteString = absoluteString.replacingOccurrences(of: "\n", with: "")
        
        guard var components = URLComponents(string: absoluteString) else {
            return url
        }
        
        if var host = components.host?.removingPercentEncoding {
            components.host = {
                host = host.lowercased()
                
                while true {
                    if host.hasPrefix(".") {
                        host.removeFirst(1)
                        continue
                    }
                    
                    if host.hasSuffix(".") {
                        host.removeLast(1)
                        continue
                    }
                    
                    break
                }
                
                let IPHost = SafeBrowsing.parseIPAddress(host: host)
                return IPHost.count > 0 ? IPHost : host
            }()
        }
        
        if var path = URL(string: absoluteString)?.pathComponents.map({ $0.removingPercentEncoding ?? $0 }) {
            components.path = {
                for i in 0..<path.count where path[i] == ".." {
                    path[i] = ""
                    path[i - 1] = ""
                }
                
                return path.filter { $0 != "." && !$0.isEmpty }.joined(separator: "/").replacingOccurrences(of: "//", with: "/")
            }()
        }
        
        if components.path.isEmpty {
            components.path = "/"
        }
        
        if absoluteString.hasSuffix("/") && !components.path.hasSuffix("/") {
            components.path += "/"
        }
        
        components.fragment = nil
        components.port = nil
        return SafeBrowsing.specURLEscape(url: components.url ?? url)
    }
    
    public static func calculatePrefixesAndSuffixes(_ url: URL) -> [String] {
        // Technically this should be done "TRIE" data structure

        if let hostName = url.host?.replacingOccurrences(of: "\(url.scheme ?? "")://", with: "") {
            var isIPAddress = false
            
            //If the host is IPv6, parse the IP by dropping the container prefix and suffix.
            if hostName.hasPrefix("[") && hostName.hasSuffix("]") {
                var newHost = hostName
                newHost.removeFirst()
                newHost.removeLast()
                isIPAddress = isValidIPAddress(string: newHost)
            } else {
                isIPAddress = isValidIPAddress(string: hostName)
            }
            
            var hostComponents = isIPAddress ? [hostName] : hostName.split(separator: ".").map { String($0) }
            while !isIPAddress && hostComponents.count > 5 {
                hostComponents = Array(hostComponents.dropFirst())
            }
            
            var prefixes = Set<String>()
            if var components = URLComponents(string: url.absoluteString) {
                let urlStringWithoutScheme = { (url: URL) -> String in
                    return url.absoluteString.replacingOccurrences(of: "\(url.scheme ?? "")://", with: "")
                }
                
                prefixes.insert(urlStringWithoutScheme(components.url!))
                
                components.query = nil
                prefixes.insert(urlStringWithoutScheme(components.url!))
                
                components.path = "/"
                prefixes.insert(urlStringWithoutScheme(components.url!))
                
                while hostComponents.count >= 2 {
                    if var components = URLComponents(string: url.absoluteString) {
                        components.host = hostComponents.joined(separator: ".")
                        prefixes.insert(urlStringWithoutScheme(components.url!))
                        
                        components.query = nil
                        prefixes.insert(urlStringWithoutScheme(components.url!))
                        
                        var pathComponents = url.pathComponents
                        while !pathComponents.isEmpty {
                            components.path = pathComponents.joined(separator: "/").replacingOccurrences(of: "//", with: "/")
                            prefixes.insert(urlStringWithoutScheme(components.url!))
                            
                            pathComponents = pathComponents.dropLast()
                        }
                    }
                    
                    hostComponents.removeFirst(1)
                }
            }
            
            return Array(prefixes)
        }
        return []
    }
    
    public static func hashPrefixes(_ url: URL) -> [String] {
        let hash = { (string: String) -> Data in
            if let data = string.data(using: String.Encoding.utf8) {
                let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
                var hash = [UInt8](repeating: 0, count: digestLength)
                _ = data.withUnsafeBytes { CC_SHA256($0.baseAddress, UInt32(data.count), &hash) }
                return Data(bytes: hash, count: digestLength)
            }
            return Data()
        }
        
        return calculatePrefixesAndSuffixes(canonicalize(url: url)).map {
            hash($0).base64EncodedString()
        }
    }
}
