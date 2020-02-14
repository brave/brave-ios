// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CommonCrypto

private enum ThreatType: String, Codable, CaseIterable {
    case unspecified = "THREAT_TYPE_UNSPECIFIED"
    case malware = "MALWARE"
    case socialEngineering = "SOCIAL_ENGINEERING"
    case unwantedSoftware = "UNWANTED_SOFTWARE"
    case potentiallyHarmfulApplication = "POTENTIALLY_HARMFUL_APPLICATION"
}

private enum PlatformType: String, Codable, CaseIterable {
    case unknown = "PLATFORM_TYPE_UNSPECIFIED"
    case ios = "IOS"
    case `any` = "ANY_PLATFORM"
    case all = "ALL_PLATFORMS"
}

private enum ThreatEntryType: String, Codable, CaseIterable {
    case unspecified = "THREAT_ENTRY_TYPE_UNSPECIFIED"
    case url = "URL"
    case exe = "EXECUTABLE"
}

private enum CompressionType: String, Codable, CaseIterable {
    case unspecified = "COMPRESSION_TYPE_UNSPECIFIED"
    case raw = "RAW"
    case rice = "RICE"
}

private enum ResponseType: String, Codable, CaseIterable {
    case unspecified = "RESPONSE_TYPE_UNSPECIFIED"
    case partialUpdate = "PARTIAL_UPDATE"
    case fullUpdate = "FULL_UPDATE"
}

private struct ClientInfo: Codable {
    let clientId: String
    let clientVersion: String
}

private struct Constraints: Codable {
    let maxUpdateEntries: UInt32?
    let maxDatabaseEntries: UInt32?
    let region: String
    let supportedCompressions: [CompressionType]
    let language: String?
    let deviceLocation: String?
}

private struct ListUpdateRequest: Codable {
    let threatType: ThreatType
    let platformType: PlatformType
    let threatEntryType: ThreatEntryType
    let state: String
    let constraints: Constraints
}

private struct RawHashes: Codable {
    let prefixSize: UInt8
    let rawHashes: String
}

private struct RawIndices: Codable {
    let indices: [UInt32]
}

private struct RiceDeltaEncoding: Codable {
    let firstValue: String
    let riceParameter: UInt8
    let numEntries: UInt32
    let encodedData: String
}

private struct ThreatEntrySet: Codable {
    let compressionType: CompressionType
    let rawHashes: RawHashes
    let rawIndices: RawIndices?
    let riceHashes: RiceDeltaEncoding?
    let riceIndices: RiceDeltaEncoding?
}

private struct ThreatEntry: Codable {
    let hash: String?
    let url: String?
    let digest: String?
}

private struct ThreatInfo: Codable {
    let threatTypes: [ThreatType]
    let platformTypes: [PlatformType]
    let threatEntryTypes: [ThreatEntryType]
    let threatEntries: [ThreatEntry]
}

private struct MetadataEntry: Codable {
    let key: String
    let value: String
}

private struct ThreatEntryMetadata: Codable {
    let entries: [MetadataEntry]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.entries = try container.decodeIfPresent([MetadataEntry].self, forKey: .entries) ?? []
    }
}

private struct ThreatMatch: Codable {
    let threatType: ThreatType
    let platformType: PlatformType
    let threatEntryType: ThreatEntryType
    let threat: ThreatEntry
    let threatEntryMetadata: ThreatEntryMetadata?
    let cacheDuration: String
}

private struct Checksum: Codable {
    let sha256: String
}

private struct ListUpdateResponse: Codable {
    let threatType: ThreatType
    let threatEntryType: ThreatEntryType
    let platformType: PlatformType
    let responseType: ResponseType
    let additions: [ThreatEntrySet]
    let removals: [ThreatEntrySet]
    let newClientState: String
    let checksum: Checksum
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.threatType = try container.decode(ThreatType.self, forKey: .threatType)
        self.threatEntryType = try container.decode(ThreatEntryType.self, forKey: .threatEntryType)
        self.platformType = try container.decode(PlatformType.self, forKey: .platformType)
        self.responseType = try container.decode(ResponseType.self, forKey: .responseType)
        self.additions = try container.decodeIfPresent([ThreatEntrySet].self, forKey: .additions) ?? []
        self.removals = try container.decodeIfPresent([ThreatEntrySet].self, forKey: .removals) ?? []
        self.newClientState = try container.decode(String.self, forKey: .newClientState)
        self.checksum = try container.decode(Checksum.self, forKey: .checksum)
    }
}

private struct FetchRequest: Codable {
    let client: ClientInfo
    let listUpdateRequests: [ListUpdateRequest]
}

private struct FetchResponse: Codable {
    let listUpdateResponses: [ListUpdateResponse]
    let minimumWaitDuration: String
}

private struct FindRequest: Codable {
    let client: ClientInfo
    let threatInfo: ThreatInfo
}

private struct FindResponse: Codable {
    let matches: [ThreatMatch]
    let negativeCacheDuration: String
    
    init() {
        matches = []
        negativeCacheDuration = "0s"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.matches = try container.decodeIfPresent([ThreatMatch].self, forKey: .matches) ?? []
        self.negativeCacheDuration = try container.decodeIfPresent(String.self, forKey: .negativeCacheDuration) ?? "0s"
    }
}

private struct ResponseError: Codable {
    let code: Int
    let message: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NestedKeys.self)
        let errorContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .error)
        
        self.code = try errorContainer.decode(Int.self, forKey: .code)
        self.message = try errorContainer.decode(String.self, forKey: .message)
    }
    
    private enum NestedKeys: String, CodingKey {
        case error
    }
}

class SafeBrowsingError: NSError {
    public init(_ message: String, code: Int = -1) {
        super.init(domain: "SafeBrowsingError", code: code, userInfo: [
            NSLocalizedDescriptionKey: message,
            NSLocalizedFailureErrorKey: message
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

private class SafeBrowsingDatabase {
    private var malwareThreats = [String]()
    private var socialEngineeringThreats = [String]()
    private var unwantedSoftwareThreats = [String]()
    private var unspecifiedThreats = [String]()
    private var harmfulApplicationThreats = [String]()
    
    private var states = [ThreatType: String]()
    
    public func getState(_ threatType: ThreatType) -> String {
        return states[threatType] ?? ""
    }
    
    public func setState(_ state: String, _ threatType: ThreatType) {
        states[threatType] = state
    }
    
    public var isEmpty: Bool {
        return unspecifiedThreats.isEmpty &&
            malwareThreats.isEmpty &&
            unwantedSoftwareThreats.isEmpty &&
            socialEngineeringThreats.isEmpty &&
            harmfulApplicationThreats.isEmpty
    }
    
    public func add(_ entry: String, _ threatType: ThreatType) {
        switch threatType {
        case .unspecified:
            let index = indexOf(array: unspecifiedThreats, predicate: { $0 < entry })
            unspecifiedThreats.insert(entry, at: index)
            
        case .malware:
            let index = indexOf(array: malwareThreats, predicate: { $0 < entry })
            malwareThreats.insert(entry, at: index)
            
        case .unwantedSoftware:
            let index = indexOf(array: unwantedSoftwareThreats, predicate: { $0 < entry })
            unwantedSoftwareThreats.insert(entry, at: index)
            
        case .socialEngineering:
            let index = indexOf(array: socialEngineeringThreats, predicate: { $0 < entry })
            socialEngineeringThreats.insert(entry, at: index)
            
        case .potentiallyHarmfulApplication:
            let index = indexOf(array: harmfulApplicationThreats, predicate: { $0 < entry })
            harmfulApplicationThreats.insert(entry, at: index)
        }
    }
    
    public func remove(index: Int, _ threatType: ThreatType) {
        switch threatType {
        case .unspecified:
            unspecifiedThreats.remove(at: index)
            
        case .malware:
            malwareThreats.remove(at: index)
            
        case .unwantedSoftware:
            unwantedSoftwareThreats.remove(at: index)
            
        case .socialEngineering:
            socialEngineeringThreats.remove(at: index)
            
        case .potentiallyHarmfulApplication:
            harmfulApplicationThreats.remove(at: index)
        }
    }
    
    public func removeAll(_ threatType: ThreatType) {
        switch threatType {
        case .unspecified:
            unspecifiedThreats.removeAll()
            
        case .malware:
            malwareThreats.removeAll()
            
        case .unwantedSoftware:
            unwantedSoftwareThreats.removeAll()
            
        case .socialEngineering:
            socialEngineeringThreats.removeAll()
            
        case .potentiallyHarmfulApplication:
            harmfulApplicationThreats.removeAll()
        }
    }
    
    public func findThreats(_ entry: String) -> [ThreatType] {
        var threatTypes = [ThreatType]()
        
        if unspecifiedThreats.firstIndex(of: entry) != nil {
            threatTypes.append(.unspecified)
        }
        
        if malwareThreats.firstIndex(of: entry) != nil {
            threatTypes.append(.malware)
        }
        
        if unwantedSoftwareThreats.firstIndex(of: entry) != nil {
            threatTypes.append(.unwantedSoftware)
        }
        
        if socialEngineeringThreats.firstIndex(of: entry) != nil {
            threatTypes.append(.socialEngineering)
        }
        
        if harmfulApplicationThreats.firstIndex(of: entry) != nil {
            threatTypes.append(.potentiallyHarmfulApplication)
        }
        
        return threatTypes
    }
    
    public func findHashes(_ entry: String) -> [String] {
        var threatTypes = Set<String>()
        
        if let index = unspecifiedThreats.firstIndex(of: entry) {
            threatTypes.insert(unspecifiedThreats[index])
        }
        
        if let index = malwareThreats.firstIndex(of: entry) {
            threatTypes.insert(malwareThreats[index])
        }
        
        if let index = unwantedSoftwareThreats.firstIndex(of: entry) {
            threatTypes.insert(unwantedSoftwareThreats[index])
        }
        
        if let index = socialEngineeringThreats.firstIndex(of: entry) {
            threatTypes.insert(socialEngineeringThreats[index])
        }
        
        if let index = harmfulApplicationThreats.firstIndex(of: entry) {
            threatTypes.insert(harmfulApplicationThreats[index])
        }
        
        return Array(threatTypes)
    }
    
    private func indexOf<Element>(array: [Element], predicate: (Element) -> Bool) -> Int {
        let index = search(array: array, predicate: predicate)
        return index >= 0 ? index : 0
    }
    
    private func search<Element>(array: [Element], predicate: (Element) -> Bool) -> Int {
        var low = array.startIndex
        var high = array.endIndex
        while low != high {
            let mid = array.index(low, offsetBy: array.distance(from: low, to: high) / 2)
            if predicate(array[mid]) {
                low = array.index(after: mid)
            } else {
                high = mid
            }
        }
        return -1
    }
}

public class SafeBrowsingClient {
    private static let apiKey = "DUMMY_KEY"
    private let baseURL = "https://safebrowsing.brave.com"
    private let session = URLSession(configuration: .ephemeral)
    private let database = SafeBrowsingDatabase()
    
    public static let shared = SafeBrowsingClient()
    
    public func find(_ hashes: [String], _ completion: @escaping (_ isSafe: Bool, Error?) -> Void) {
        var discoveredHashes = hashes.flatMap({ database.findHashes($0) })
        if discoveredHashes.isEmpty && !database.isEmpty {
            return completion(true, nil)
        }
        
        // If for some reason the database is empty, we should at least make the call to the API.
        // As a fallback just in case, we use the prefixes
        if discoveredHashes.isEmpty {
            discoveredHashes = hashes
        }
        
        let threatTypes: [ThreatType] = [.malware,
                                         .socialEngineering,
                                         .unwantedSoftware,
                                         .potentiallyHarmfulApplication]
        
        let platformTypes: [PlatformType] = [.any]
        let threatEntryTypes: [ThreatEntryType] = [.url, .exe]
        
        let clientInfo = ClientInfo(clientId: "com.brave.safebrowsing", clientVersion: "1.0")
        
        let threatInfo = ThreatInfo(threatTypes: threatTypes,
                                    platformTypes: platformTypes,
                                    threatEntryTypes: threatEntryTypes,
                                    threatEntries: discoveredHashes.map {
                                        return ThreatEntry(hash: $0, url: nil, digest: nil)
                                    }
        )
        
        let body = FindRequest(client: clientInfo,
                               threatInfo: threatInfo)
        
        do {
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
    
    public func fetch(_ completion: @escaping (Error?) -> Void) {
        // Create some constraints
        let constraints = Constraints(maxUpdateEntries: 2048, //limit bandwidth
            maxDatabaseEntries: 4096, //limit disk space
            region: "US",
            supportedCompressions: [.raw],
            language: nil, //"eng"
            deviceLocation: nil) //"US"
        
        // Not sure what types or regions the brave-browser uses - Brandon T.
        
        // Create the threat types
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
        
        let clientInfo = ClientInfo(clientId: "com.brave.safebrowsing", clientVersion: "1.0")
        let body = FetchRequest(client: clientInfo, listUpdateRequests: lists)
        
        do {
            let request = try encode(.post, endpoint: .fetch, body: body)
            executeRequest(request, type: FetchResponse.self) { response, error in
                if let error = error {
                    return completion(error)
                }
                
                if let response = response {
                    response.listUpdateResponses.forEach({
                        self.database.setState($0.newClientState, $0.threatType)
                        
                        if $0.responseType == .fullUpdate {
                            self.database.removeAll($0.threatType)
                        }
                    })
                    
                    response.listUpdateResponses.forEach({ update in
                        update.additions.forEach({
                            if let hash = Data(base64Encoded: $0.rawHashes.rawHashes) {
                                let strideSize = Int($0.rawHashes.prefixSize)
                                
                                for i in stride(from: 0, to: hash.count, by: strideSize) {
                                    let startIndex = hash.index(hash.startIndex, offsetBy: i)
                                    let endIndex = hash.index(startIndex, offsetBy: strideSize)
                                    
                                    let subData = hash.subdata(in: startIndex..<endIndex)
                                    self.database.add(subData.base64EncodedString(), update.threatType)
                                }
                            }
                        })
                        
                        update.removals.forEach({
                            $0.rawIndices?.indices.reversed().forEach({
                                self.database.remove(index: Int($0), update.threatType)
                            })
                        })
                    })
                }
                
                completion(nil)
            }
        } catch {
            completion(error)
        }
    }
    
    private func encode<T>(_ method: RequestType, endpoint: Endpoint, body: T) throws -> URLRequest where T: Encodable {
        let urlPath = "\(baseURL)\(endpoint.rawValue)?key=\(type(of: self).apiKey)"
        
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
    private func canonicalize() -> URL {
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
    public func hashPrefixes(lengthInBytes: Int = 4) -> [String] {
        let hash = { (string: String) -> Data in
            if let data = string.data(using: String.Encoding.utf8) {
                let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
                var hash = [UInt8](repeating: 0, count: digestLength)
                _ = data.withUnsafeBytes { CC_SHA256($0.baseAddress, UInt32(data.count), &hash) }
                return Data(bytes: hash, count: digestLength)
            }
            return Data()
        }
        
        return canonicalize().calculatePrefixesAndSuffixes().compactMap({ prefix -> String? in
            if case let hash = hash(prefix), !hash.isEmpty {
                let endIndex = hash.index(hash.startIndex, offsetBy: MemoryLayout<UInt8>.size * lengthInBytes)
                return hash.subdata(in: hash.startIndex..<endIndex).base64EncodedString()
            }
            
            return nil
        })
    }
}
