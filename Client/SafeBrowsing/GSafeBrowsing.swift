// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CommonCrypto
import Shared

private let log = Logger.browserLogger

class SafeBrowsingClient {
    private static let apiKey = "DUMMY_KEY"
    private static let maxBandwidth = 2048
    private static let maxDiskSpace = 4096
    private static let clientId = AppInfo.baseBundleIdentifier
    private static let version = AppInfo.appVersion
    
    private let baseURL = "https://safebrowsing.brave.com"
    private let session = URLSession(configuration: .ephemeral)
    private let database = SafeBrowsingDatabase()
    
    public static let shared = SafeBrowsingClient()
    
    private init() {
    }
    
    func find(_ hashes: [String], _ completion: @escaping (_ isSafe: Bool, Error?) -> Void) {
        let discoveredHashes = database.find(hashes)
        if discoveredHashes.isEmpty {
            return completion(true, nil)
        }
        
        let clientInfo = ClientInfo(clientId: SafeBrowsingClient.clientId,
                                    clientVersion: SafeBrowsingClient.version)
        
        let threatTypes: [ThreatType] = [.malware,
                                         .socialEngineering,
                                         .unwantedSoftware,
                                         .potentiallyHarmfulApplication]
        
        let platformTypes: [PlatformType] = [.any]
        let threatEntryTypes: [ThreatEntryType] = [.url, .exe]
        
        let threatInfo = ThreatInfo(threatTypes: threatTypes,
                                    platformTypes: platformTypes,
                                    threatEntryTypes: threatEntryTypes,
                                    threatEntries: discoveredHashes.map {
                                        return ThreatEntry(hash: $0, url: nil, digest: nil)
                                    }
        )
        
        do {
            let body = FindRequest(client: clientInfo, threatInfo: threatInfo)
            let request = try encode(.post, endpoint: .fullHashes, body: body)
            executeRequest(request, type: FindResponse.self) { response, error in
                if let error = error {
                    return completion(false, error)
                }
                
                if let response = response {
                    if !response.matches.isEmpty {
                        return completion(false, nil)
                    }
                }
                
                completion(true, nil)
            }
        } catch {
            completion(false, error)
        }
    }
    
    func fetch(_ completion: @escaping (Error?) -> Void) {
        let clientInfo = ClientInfo(clientId: SafeBrowsingClient.clientId,
                                    clientVersion: SafeBrowsingClient.version)
        
        let constraints = Constraints(maxUpdateEntries: UInt32(SafeBrowsingClient.maxBandwidth),
                                      maxDatabaseEntries: UInt32(SafeBrowsingClient.maxDiskSpace),
                                      region: "US",
                                      supportedCompressions: [.raw],
                                      language: nil,
                                      deviceLocation: nil)
        
        let lists = [
            ListUpdateRequest(threatType: .malware,
                              platformType: .any,
                              threatEntryType: .url,
                              state: database.getState(.malware),
                              constraints: constraints),
            
            ListUpdateRequest(threatType: .socialEngineering,
                              platformType: .any,
                              threatEntryType: .url,
                              state: database.getState(.socialEngineering),
                              constraints: constraints),
            
            ListUpdateRequest(threatType: .unwantedSoftware,
                              platformType: .any,
                              threatEntryType: .url,
                              state: database.getState(.unwantedSoftware),
                              constraints: constraints)
        ]
        
        do {
            let body = FetchRequest(client: clientInfo, listUpdateRequests: lists)
            let request = try encode(.post, endpoint: .fetch, body: body)
            executeRequest(request, type: FetchResponse.self) { response, error in
                if let error = error {
                    return completion(error)
                }
                
                if let response = response {
                    self.database.update(response, completion: {
                        if let error = $0 {
                            log.error("Safe-Browsing: Error Updating Database: \(error)")
                        }
                    })
                }
                
                completion(nil)
            }
        } catch {
            completion(error)
        }
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
        request.httpBody = try JSONEncoder().encode(body)
        
        return request
    }
    
    @discardableResult
    private func executeRequest<T>(_ request: URLRequest, type: T.Type, completion: @escaping (T?, Error?) -> Void) -> URLSessionDataTask where T: Decodable {
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(nil, error)
            }
            
            guard let data = data else {
                return completion(nil, SafeBrowsingError("Invalid Server Response: No Data"))
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode < 200 || response.statusCode > 299 {
                    do {
                        let error = try JSONDecoder().decode(ResponseError.self, from: data)
                        return completion(nil, SafeBrowsingError(error.message, code: error.code))
                    } catch {
                        return completion(nil, error)
                    }
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

extension URL {
    func canonicalize() -> URL {
        var absoluteString = self.absoluteString
        absoluteString = absoluteString.replacingOccurrences(of: "\t", with: "")
        absoluteString = absoluteString.replacingOccurrences(of: "\r", with: "")
        absoluteString = absoluteString.replacingOccurrences(of: "\n", with: "")
        
        guard var components = URLComponents(string: absoluteString) else {
            return self
        }
        
        if var host = components.host?.removingPercentEncoding {
            //TODO: Handle IP Addresses..
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
                return host
            }()
        }
        
        if var path = URL(string: absoluteString)?.pathComponents.map({ $0.removingPercentEncoding ?? $0 }) {
            components.path = {
                for i in 0..<path.count where path[i] == ".." {
                    path[i] = ""
                    path[i - 1] = ""
                }
                
                return path.filter({ $0 != "." && !$0.isEmpty }).joined(separator: "/").replacingOccurrences(of: "//", with: "/")
            }()
        }
        
        if components.path.isEmpty {
            components.path = "/"
        }
        
        components.fragment = nil
        components.port = nil
        return components.url ?? self
    }
}

extension URL {
    private func calculatePrefixesAndSuffixes() -> [String] {
        // Technically this should be done "TRIE" data structure
        
        //TODO: Fix for IP Address..
        if let hostName = host?.replacingOccurrences(of: "\(scheme ?? "")://", with: "") {
            var hostComponents = hostName.split(separator: ".")
            while hostComponents.count > 5 {
                hostComponents = Array(hostComponents.dropFirst())
            }
            
            var prefixes = Set<String>()
            if var components = URLComponents(string: absoluteString) {
                let urlStringWithoutScheme = { (url: URL) -> String in
                    return url.absoluteString.replacingOccurrences(of: "\(url.scheme ?? "")://", with: "")
                }
                
                prefixes.insert(urlStringWithoutScheme(components.url!))
                
                components.query = nil
                prefixes.insert(urlStringWithoutScheme(components.url!))
                
                components.path = "/"
                prefixes.insert(urlStringWithoutScheme(components.url!))
                
                while hostComponents.count >= 2 {
                    if var components = URLComponents(string: absoluteString) {
                        components.host = hostComponents.joined(separator: ".")
                        prefixes.insert(urlStringWithoutScheme(components.url!))
                        
                        components.query = nil
                        prefixes.insert(urlStringWithoutScheme(components.url!))
                        
                        var pathComponents = self.pathComponents
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
}

extension URL {
    public func hashPrefixes() -> [String] {
        let hash = { (string: String) -> Data in
            if let data = string.data(using: String.Encoding.utf8) {
                let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
                var hash = [UInt8](repeating: 0, count: digestLength)
                _ = data.withUnsafeBytes { CC_SHA256($0.baseAddress, UInt32(data.count), &hash) }
                return Data(bytes: hash, count: digestLength)
            }
            return Data()
        }
        
        return canonicalize().calculatePrefixesAndSuffixes().map({
            hash($0).base64EncodedString()
        })
    }
}
