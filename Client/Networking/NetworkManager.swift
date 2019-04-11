// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Deferred
import Shared

private let log = Logger.browserLogger

class NetworkManager {
    private let session: NetworkSession
    
    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    func dataRequest(with url: URL, completion: @escaping NetworkSessionDataResponse) {
        session.dataRequest(with: url) { data, response, error in
            completion(data, response, error)
        }
    }
    
    func dataRequest(with urlRequest: URLRequest, completion: @escaping NetworkSessionDataResponse) {
        session.dataRequest(with: urlRequest) { data, response, error in
            completion(data, response, error)
        }
    }
    
    func downloadResource(with url: URL, resourceType: NetworkResourceType,
                          retryTimeout: TimeInterval? = 60) -> Deferred<CachedNetworkResource> {
        let completion = Deferred<CachedNetworkResource>()
        
        var request = URLRequest(url: url)
        
        // Makes the request conditional, returns 304 if Etag value did not change.
        let ifNoneMatchHeader = "If-None-Match"
        let fileNotModifiedStatusCode = 304
        
        // Identifier for a specific version of a resource for a HTTP request
        let etagHeader = "Etag"
        
        switch resourceType {
        case .cached(let etag):
            let requestEtag = etag ?? UUID().uuidString
            
            // This cache policy is required to support `If-None-Match` header.
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.addValue(requestEtag, forHTTPHeaderField: ifNoneMatchHeader)
        default: break
        }
        
        session.dataRequest(with: request) { data, response, error -> Void in
            if let err = error {
                log.error(err.localizedDescription)
                if let retryTimeout = retryTimeout {
                    DispatchQueue.main.asyncAfter(deadline: .now() + retryTimeout) {
                        self.downloadResource(with: url, resourceType: resourceType, retryTimeout: retryTimeout).upon { resource in
                            completion.fill(resource)
                        }
                    }
                }
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                log.error("Failed to unwrap http response or data")
                return
            }
            
            switch response.statusCode {
            case 400...499:
                log.error("""
                    Failed to download, status code: \(response.statusCode),\
                    URL:\(String(describing: response.url))
                    """)
            case fileNotModifiedStatusCode:
                log.info("File not modified")
            default:
                let responseEtag = resourceType.isCached() ?
                    response.allHeaderFields[etagHeader] as? String : nil
                
                completion.fill(CachedNetworkResource(data: data, etag: responseEtag))
            }
        }
        
        return completion
    }
}
