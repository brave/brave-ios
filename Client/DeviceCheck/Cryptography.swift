// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

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
    
    var error: Unmanaged<CFError>?
    if let data = SecKeyCopyExternalRepresentation(publicKey, &error) {
      return data as Data
    }
    
    if let error = error?.takeUnretainedValue() {
      throw error
    }
    
    return nil
  }
    
  /// Returns the public key in PEM format
  func getPublicKeyExternalRepresentationAsPEM() throws -> String? {
    guard let publicKeyRepresentation = try getPublicKeyExternalRepresentation() else {
      return nil
    }

    //opensource.apple.com/source/security_certtool/security_certtool-55103/src/dumpasn1.cfg
    //OID = 06 07 2A 86 48 CE 3D 02 01
    //Comment = ANSI X9.62 public key type
    //Description = ecPublicKey (1 2 840 10045 2 1)
    let curveOIDHeader: [UInt8] = [0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00]

    var data = Data(bytes: curveOIDHeader, count: curveOIDHeader.count)
    data.append(publicKeyRepresentation)
    
    let result =
    """
    -----BEGIN PUBLIC KEY-----
    \(data.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed]))
    -----END PUBLIC KEY-----
    """
    return result
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
    var error: Unmanaged<CFError>?
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
  public static let accessControlFlags = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.privateKeyUsage], nil) //.biometryAny
  
  /// Determines if a key exists in the keychain without retrieving it
  public class func keyExists(id: String) -> Bool {
    let query: [CFString: Any] = [
      kSecClass: kSecClassKey,
      kSecAttrApplicationTag: id.data(using: .utf8)!,
      kSecMatchLimit: kSecMatchLimitOne,
      kSecReturnRef: kCFBooleanFalse as Any,
      kSecReturnAttributes: kCFBooleanTrue as Any
    ]
    
    var result: CFTypeRef?
    let error = SecItemCopyMatching(query as CFDictionary, &result)
    return error == errSecSuccess || error == errSecInteractionNotAllowed
      && result != nil && CFDictionaryGetCount((result! as! CFDictionary)) > 0 //swiftlint:disable:this force_cast
  }
  
  /// Determines if a key requires biometrics to access
  public class func isKeyRequiringBiometrics(id: String) -> Bool {
    let query: [CFString: Any] = [
      kSecClass: kSecClassKey,
      kSecAttrApplicationTag: id.data(using: .utf8)!,
      kSecMatchLimit: kSecMatchLimitOne,
      kSecReturnRef: kCFBooleanFalse as Any,
      kSecReturnAttributes: kCFBooleanTrue as Any
    ]
    
    var result: CFTypeRef?
    let error = SecItemCopyMatching(query as CFDictionary, &result)
    if error == errSecSuccess || error == errSecInteractionNotAllowed {
      if let result = result as? [String: Any], let accessControl = result[kSecAttrAccessControl as String] as! SecAccessControl? { //swiftlint:disable:this force_cast
        return String(describing: accessControl).contains("bio") //cbio, pbio (.currentBioSet, .presentBioSet)
      }
      return false
    }

    return false
  }
  
  /// Retrieves an existing key from the secure-enclave
  public class func getExistingKey(id: String) throws -> CryptographicKey? {
    let query: [CFString: Any] = [
      kSecClass: kSecClassKey,
      kSecAttrApplicationTag: id.data(using: .utf8)!,
      kSecMatchLimit: kSecMatchLimitOne,
      kSecReturnRef: kCFBooleanTrue as Any
    ]
    
    var result: CFTypeRef?
    let error = SecItemCopyMatching(query as CFDictionary, &result)
    if error == errSecSuccess || error == errSecDuplicateItem || error == errSecInteractionNotAllowed {
      if let res = result {
        return CryptographicKey(key: res as! SecKey, keyId: id) //swiftlint:disable:this force_cast
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
  /// The generated key is a 256-bit RSA ECSEC Key.
  public class func generateKey(id: String,
                                bits: UInt16 = 256,
                                storeInKeychain: Bool = true,
                                secureEnclave: Bool = true,
                                controlFlags: SecAccessControl? = Cryptography.accessControlFlags) throws -> CryptographicKey? {
    
    /*
     // If the key exists and requires biometrics, remove it.
     // Not needed atm but it might be needed in the future when migrating keys.
    if keyExists(id: id) && isKeyRequiringBiometrics(id: id) {
      SecItemDelete([
        kSecClass: kSecClassKey,
        kSecAttrApplicationTag: id.data(using: .utf8)!
      ] as CFDictionary)
    }*/
    
    if let key = try getExistingKey(id: id) {
      return key
    }
    
    let attributes: [CFString: Any] = [
      kSecClass: kSecClassKey,
      kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits: bits,
      kSecAttrCreator: "com.brave.security.cryptography",
      kSecAttrTokenID: (secureEnclave ? kSecAttrTokenIDSecureEnclave : nil) as Any,
      kSecPrivateKeyAttrs: [
        kSecAttrIsPermanent: storeInKeychain,
        kSecAttrApplicationTag: id.data(using: .utf8)!,
        kSecAttrAccessControl: (controlFlags ?? nil) as Any
      ]
    ]
    
    var error: Unmanaged<CFError>?
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
