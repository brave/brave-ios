// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import Shared

struct WebAuthnRegisterRequest {
    var username: String
    var userId: String
    
    var rpId: String
    var rpName: String
    
    var pubKeyAlg: Int
    var residentKey: Bool
    
    var challenge: String
    
    enum CodingKeys: String, CodingKey {
        case username
        case userId
        case rpId
        case rpName
        case pubKeyAlg
        case residentKey
    }
    
    enum RequestKeys: String, CodingKey {
        case publicKey
    }
    
    enum PublicKeyDictionaryKeys: String, CodingKey {
        case user
        case rp
        case pubKeyCredParams
        case challenge
        case authenticatorSelection
    }
    
    enum UserKeys: String, CodingKey {
        case name
        case id
    }

    enum pubKeyCredParams: String, CodingKey {
        case alg
    }
}

private struct PubKeyCredParams: Codable {
    var alg: Int
    var type: String
}

private struct AuthenticatorSelection: Codable {
    var requireResidentKey: Bool?
    var userVerification: String?
}

extension WebAuthnRegisterRequest: Decodable {
    init(from decoder: Decoder) throws {
        let request = try decoder.container(keyedBy: RequestKeys.self)
        let publicKeyDictionary = try request.nestedContainer(keyedBy: PublicKeyDictionaryKeys.self, forKey: .publicKey)
       
        let userDictionary = try publicKeyDictionary.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        
        username = try userDictionary.decode(String.self, forKey: .name)
        userId = try userDictionary.decode(String.self, forKey: .id)
        
        let rpDictionary = try publicKeyDictionary.nestedContainer(keyedBy: UserKeys.self, forKey: .rp)
        rpId = try rpDictionary.decodeIfPresent(String.self, forKey: .id) ?? ""
        rpName = try rpDictionary.decode(String.self, forKey: .name)
        
        let pubKeyCredParamsArray = try publicKeyDictionary.decode([PubKeyCredParams].self, forKey: .pubKeyCredParams)
        let pubKeyCredParam = pubKeyCredParamsArray.first
        
        // -7 (ECC) or -257 (RSA)
        pubKeyAlg = pubKeyCredParam?.alg ?? -7
        
        if let authenticatorSelection = try publicKeyDictionary.decodeIfPresent(AuthenticatorSelection.self, forKey: .authenticatorSelection) {
            residentKey = authenticatorSelection.requireResidentKey ?? false
        } else {
            residentKey = false
        }
        
        challenge = try publicKeyDictionary.decode(String.self, forKey: .challenge)
    }
}
