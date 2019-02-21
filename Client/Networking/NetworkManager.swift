// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

class NetworkManager {
    private let session: NetworkSession
    
    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }
    
    func dataRequest(fromUrl url: URL, completion: @escaping NetworkSessionDataResponse) {
        session.dataRequest(forUrl: url) { data, response, error in
            
            completion(data, response, error)
        }
    }
    
    func dataRequest(fromUrlRequest urlRequest: URLRequest, completion: @escaping NetworkSessionDataResponse) {
        session.dataRequest(forUrlRequest: urlRequest) { data, response, error in
            
            completion(data, response, error)
        }
    }
}
