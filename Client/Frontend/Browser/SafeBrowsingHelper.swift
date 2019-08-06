// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct SafeBrowsingHelper {
    /// Types of threats.
    enum ThreatType: String, Codable {
        case unspecified = "THREAT_TYPE_UNSPECIFIED"
        case malware = "MALWARE"
        case socialEngineering = "SOCIAL_ENGINEERING"
        case unwantedSoftware = "UNWANTED_SOFTWARE"
        case potentiallyHarmfulApplication = "POTENTIALLY_HARMFUL_APPLICATION"
    }
    
    /// Types of platforms.
    enum PlatformType: String, Codable {
        /// Unknown platform.
        case unknown = "PLATFORM_TYPE_UNSPECIFIED"
        
        /// Threat posed to Windows.
        case windows = "WINDOWS"
        
        /// Threat posed to Linux.
        case linux = "LINUX"
        
        /// Threat posed to Android.
        case android = "ANDROID"
        
        /// Threat posed to OS X.
        case osx = "OSX"
        
        /// Threat posed to iOS.
        case ios = "IOS"
        
        /// Threat posed to at least one of the defined platforms.
        case `any` = "ANY_PLATFORM"
        
        /// Threat posed to all defined platforms.
        case all = "ALL_PLATFORMS"
        
        /// Threat posed to Chrome.
        case chrome = "CHROME"
    }
    
    /// Types of entries that pose threats.
    /// Threat lists are collections of entries of a single type.
    enum ThreatEntryType: String, Codable {
        case unspecified = "THREAT_ENTRY_TYPE_UNSPECIFIED"
        case url = "URL"
        case exe = "EXECUTABLE"
    }
    
    /// The client metadata associated with Safe Browsing API requests.
    struct ClientInfo: Codable {
        /// A client ID that (hopefully) uniquely identifies the client implementation of the Safe Browsing API.
        let clientId: String
        
        /// The version of the client implementation.
        let clientVersion: String
    }
    
    /// An individual threat; for example, a malicious URL or its hash representation.
    /// Only one of these fields should be set.
    struct ThreatEntry: Codable {
        /// A hash prefix, consisting of the most significant 4-32 bytes of a SHA256 hash.
        /// This field is in binary format. For JSON requests, hashes are base64-encoded.
        ///
        /// A base64-encoded string.
        let hash: String?
        
        /// A URL.
        let url: String?
        
        /// The digest of an executable in SHA256 format.
        /// The API supports both binary and hex digests.
        /// For JSON requests, digests are base64-encoded.
        ///
        /// A base64-encoded string.
        let digest: String?
    }
    
    /// A single metadata entry.
    struct MetadataEntry: Codable {
        /// The metadata entry key.
        /// For JSON requests, the key is base64-encoded.
        ///
        /// A base64-encoded string.
        let key: String
        
        /// The metadata entry value.
        /// For JSON requests, the value is base64-encoded.
        ///
        ///A base64-encoded string.
        let value: String
    }
    
    /// The metadata associated with a specific threat entry.
    /// The client is expected to know the metadata key/value pairs
    /// associated with each threat type.
    struct ThreatEntryMetadata: Codable {
        let entries: [MetadataEntry]
    }
    
    /// The information regarding one or more threats that a client
    /// submits when checking for matches in threat lists.
    struct ThreatInfo: Codable {
        /// The threat types to be checked.
        let threatTypes: [ThreatType]
        
        /// The platform types to be checked.
        let platformTypes: [PlatformType]
        
        /// The entry types to be checked.
        let threatEntryTypes: [ThreatEntryType]
        
        /// The threat entries to be checked.
        let threatEntries: [ThreatEntry]
    }
    
    /// A match when checking a threat entry in the Safe Browsing threat lists.
    struct ThreatMatch: Codable {
        
        /// The threat type matching this threat.
        let threatType: ThreatType
        
        /// The platform type matching this threat.
        let platformType: PlatformType
        
        /// The threat entry type matching this threat.
        let threatEntryType: ThreatEntryType
        
        /// The threat matching this threat.
        let threat: ThreatEntry
        
        /// Optional metadata associated with this threat.
        let threatEntryMetadata: ThreatEntryMetadata?
        
        /// The cache lifetime for the returned match.
        /// Clients must not cache this response for more than this duration to avoid false positives.
        ///
        /// A duration in seconds with up to nine fractional digits, terminated by 's'.
        /// Example: "3.5s".
        let cacheDuration: String
    }
    
    struct Request: Codable {
        let client: ClientInfo
        let threatInfo: ThreatInfo
    }
    
    struct Response: Codable {
        let matches: [ThreatMatch]
        
        init() {
            matches = []
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.matches = try container.decodeIfPresent([ThreatMatch].self, forKey: .matches) ?? []
        }
    }
    
    struct ResponseError: Codable {
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
    
    private class SafeBrowsingError: NSError {
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
    
    @discardableResult
    public static func threatMatches(urls: [URL], session: URLSession = .shared, _ completion: @escaping (Response, Error?) -> Void) throws -> URLSessionDataTask {
        
        let apiKey = "AIzaSyDeglae_dQQyQuRNk1jPq5R5--jBy21H5o"
        
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
                                    threatEntries: urls.map {
                                        ThreatEntry(hash: nil, url: $0.absoluteString, digest: nil)
            }
        )
        
        let requestInfo = Request(client: clientInfo,
                                  threatInfo: threatInfo)
        
        let request = try { () throws -> URLRequest in
            guard !apiKey.isEmpty else {
                throw SafeBrowsingError("Invalid API Key")
            }
            
            guard let url = URL(string: "https://safebrowsing.googleapis.com/v4/threatMatches:find?key=\(apiKey)") else {
                throw SafeBrowsingError("Invalid Safe-Browsing URL")
            }
            
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            request.httpMethod = "POST"
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.87 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = try JSONEncoder().encode(requestInfo)
            return request
            }()
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(Response(), error)
            }
            
            guard let data = data else {
                return completion(Response(), SafeBrowsingError("Invalid Server Response: No Data"))
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode < 200 || response.statusCode > 299 {
                    do {
                        let error = try JSONDecoder().decode(ResponseError.self, from: data)
                        return completion(Response(), SafeBrowsingError(error.message, code: error.code))
                    } catch {
                        return completion(Response(), error)
                    }
                }
            }
            
            do {
                let response = try JSONDecoder().decode(Response.self, from: data)
                completion(response, nil)
            } catch {
                completion(Response(), error)
            }
        }
        task.resume()
        return task
    }
}
