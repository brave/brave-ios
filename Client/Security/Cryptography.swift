// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import DeviceCheck

/// An error class representing an error that has occurred when handling encryption
public struct CryptographyError: Error {
    //The error domain
    public let domain: String
    
    //The error code
    public let code: Int32
    
    //A description of the error
    public let description: String?
    
    init(code: Int32, description: String? = nil) {
        self.domain = "com.brave.security.cryptography.error"
        self.code = code
        self.description = description
    }
}

/// A class representing a cryptographic key.
public struct CryptographicKey {
    private let key: SecKey
    private let keyId: String
    
    public init(key: SecKey, keyId: String) {
        self.key = key
        self.keyId = keyId
    }
    
    /// Returns the private key
    public func getPrivateKey() -> SecKey {
        return key
    }
    
    /// Returns the public key
    public func getPublicKey() -> SecKey? {
        return SecKeyCopyPublicKey(key)
    }
    
    /// Returns the public key in ASN.1 format
    public func getPublicKeyExternalRepresentation() throws -> Data? {
        guard let publicKey = getPublicKey() else {
            throw CryptographyError(code: -1, description: "Cannot retrieve public key")
        }
        
        var error: Unmanaged<CFError>? = nil
        if let data = SecKeyCopyExternalRepresentation(publicKey, &error) {
            return data as Data
        }
        
        if let error = error?.takeUnretainedValue() {
            throw error
        }
        
        return nil
    }
    
    /// Deletes the key from the secure-enclave and keychain
    @discardableResult
    public func delete() -> Error? {
        let error = SecItemDelete([
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keyId.data(using: .utf8)!
        ] as CFDictionary)
        
        if error == errSecSuccess || error == errSecItemNotFound {
            return nil
        }
        
        return CryptographyError(code: error)
    }
    
    /// Signs a "message" with the key and returns the signature
    public func sign(message: String) throws -> Data {
        
        var error: Unmanaged<CFError>? = nil
        let signature = SecKeyCreateSignature(key,
                                              .ecdsaSignatureMessageX962SHA256,
                                              message.data(using: .utf8)! as CFData,
                                              &error)
        
        if let error = error?.takeUnretainedValue() {
            throw error as Error
        }
        
        guard let result = signature as Data? else {
            throw CryptographyError(code: -1, description: "Cannot sign message with cryptographic key.")
        }
        
        return result
    }
}

/// A class used for generating cryptographic keys
public class Cryptography {

    /// The access control flags for any keys generated
    public static let accessControlFlags = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.privateKeyUsage, .biometryAny], nil)
    
    /// Retrieves an existing key from the secure-enclave
    public class func getExistingKey(id: String) throws -> CryptographicKey? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: id.data(using: .utf8)!,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnRef: kCFBooleanTrue as Any
        ]
        
        var result: CFTypeRef? = nil
        let error = SecItemCopyMatching(query as CFDictionary, &result)
        if error == errSecSuccess || error == errSecDuplicateItem || error == errSecInteractionNotAllowed {
            if let res = result {
                return CryptographicKey(key: res as! SecKey, keyId: id)
            }
            return nil
        }
        
        if error == errSecItemNotFound {
            return nil
        }
        
        throw CryptographyError(code: error)
    }
    
    /// Generates a new key and stores it in the secure-enclave
    /// If a key with the specified ID already exists, it retrieves the existing key instead
    public class func generateKey(id: String,
                                  bits: UInt16 = 256,
                                  storeInKeychain: Bool = true,
                                  secureEnclave: Bool = true,
                                  controlFlags: SecAccessControl? = Cryptography.accessControlFlags) throws -> CryptographicKey? {
        
        if let key = try getExistingKey(id: id) {
            return key
        }
        
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: bits,
            kSecAttrCreator: "com.brave.security.cryptography",
            kSecAttrTokenID: (secureEnclave ? kSecAttrTokenIDSecureEnclave : nil) as Any,
            kSecPrivateKeyAttrs: [kSecAttrIsPermanent: storeInKeychain,
                                  kSecAttrApplicationTag: id.data(using: .utf8)!,
                                  kSecAttrAccessControl : (controlFlags ?? nil) as Any
            ]
        ]
        
        var error: Unmanaged<CFError>? = nil
        let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error)
        
        if let error = error?.takeUnretainedValue() {
            throw error as Error
        }
        
        guard let pKey = key else {
            throw CryptographyError(code: -1, description: "Cannot generate cryptographic key.")
        }
        
        return CryptographicKey(key: pKey, keyId: id)
    }
}

class DeviceCheckFlow {
    func sampleFlow() {
        DCDevice.current.generateToken { data, error in
            if let error = error {
                return //TODO: Handle Error..
            }
            
            guard let deviceCheckToken = data?.base64EncodedString() else {
                return //TODO: Handle Error..
            }
            
            do {
                guard let privateKey = try Cryptography.generateKey(id: "com.brave.device.check.private.key") else {
                    throw CryptographyError(code: -1, description: "Unable to generate private key")
                }
                
                guard let publicKeyData = try privateKey.getPublicKeyExternalRepresentation()?.base64EncodedString() else {
                    throw CryptographyError(code: -1, description: "Unable to retrieve public key")
                }
                
                let signature = try privateKey.sign(message: publicKeyData + deviceCheckToken).base64EncodedString()
                
                //TODO: Send Signature, PublicKeyData, DeviceCheckToken to the server..
                
                //Part 2:
                let challengeNoonce = "...Retrieved from server..."
                let challengeSignature = try privateKey.sign(message: challengeNoonce).base64EncodedString()
                
                //TODO: Send challengeSignature to the server for verification..
            } catch {
                print(error) //TODO: Handle Error..
            }
        }
    }
}
