// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Security
import CryptoKit

struct AlgorithmIdentifier {
  let algorithm: String  // OBJECT IDENTIFIER (06 - Type is OBJECT IDENTIFIER), Length: Byte
  let parameters: String  // ANY DEFINED BY algorithm OPTIONAL
}

struct SubjectPublicKeyInfo {  // SEQUENCE: 30 - Type is SEQUENCE, Length: Byte
  let algorithm: AlgorithmIdentifier  // AlgorithmIdentifier
  let subjectPublicKey: String  // BIT STRING
}

enum VerifierFormat {
  /// Accept only Crx3.
  case crx3
  /// Accept only Crx3 with a test or production
  case testWithPublisherProof
  /// publisher proof.
  case publisherProof
}

enum VerifierResult {
  /// The file verifies as a correct full CRX file.
  case okFull
  /// The file verifies as a correct differential CRX file.
  case okDelta
  /// Cannot open the CRX file.
  case fileNotReadable
  /// Failed to parse or understand CRX header.
  case headerInvalid
  /// Expected hash is not well-formed.
  case expecedHashInvalid
  /// The file's actual hash != the expected hash.
  case fileHashFailed
  /// A signature or key is malformed.
  case signatureInitializationFailed
  /// A signature doesn't match.
  case signatureVerificationFailed
  /// RequireKeyProof was unsatisfied.
  case requiredProofMissing
}

/// Verifies the CRX3 Format
/// This could be done with Brave-Core
/// However, tests show the BraveCore code is thousands of times slower
/// This code runs in 2ms, BraveCore version runs in 3 minutes
class CRXVerifier {
  private class SignatureVerifierSHA256 {
    private let key: SecKey
    private let algorithm: SecKeyAlgorithm
    private let signature: Data
    private var hash = SHA256()
    
    enum Algorithm {
      case rsaPKCS1SHA256
      case ecdsaSHA256
    }
    
    init?(algorithm: Algorithm, signature: Data, key: Data) {
      var error: Unmanaged<CFError>?
      let publicKey: SecKey?
      
      self.signature = signature
      
      switch algorithm {
      case .rsaPKCS1SHA256:
        self.algorithm = .rsaSignatureDigestPKCS1v15SHA256
        publicKey = SecKeyCreateWithData(key as CFData,
                                         [kSecAttrKeyType: kSecAttrKeyTypeRSA,
                                          kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary,
                                         &error)
        
      case .ecdsaSHA256:
        self.algorithm = .ecdsaSignatureDigestX962SHA256
        
        guard let res = try? ASN1Parser().parse(data: key) as? ASN1.Sequence else {
          return nil
        }
        
        guard let keyBitString = res.values.compactMap({ $0 as? ASN1.BitString }).first?.data else {
          return nil
        }
        
        // Supposed to really be ECDSA (but it's not available on iOS, and this seems to work fine)
        // Instead we use kSecAttrKeyTypeECSECPrimeRandom or kSecAttrKeyTypeEC :l
        publicKey = SecKeyCreateWithData(keyBitString as CFData,
                                         [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                                          kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary,
                                         &error)
      }
      
      if let error = error {
        print(error.takeRetainedValue())
      }
      
      guard let key = publicKey,
            error == nil else {
        return nil
      }
      
      self.key = key
    }
    
    func update<D: DataProtocol>(data: D) {
      hash.update(data: data)
    }
    
    func verifyFinal() -> Bool {
      var error: Unmanaged<CFError>?
      let hashedData = Data(hash.finalize())
      let result = SecKeyVerifySignature(key,
                                         algorithm,
                                         hashedData as CFData,
                                         signature as CFData, &error)
      if let error = error {
        print(error.takeRetainedValue())
      }
      return result
    }
  }
  
  // The SHA256 hash of the DER SPKI "ecdsa_2017_public" Crx3 key.
  private static let kPublisherKeyHash: [UInt8] = [
      0x61, 0xf7, 0xf2, 0xa6, 0xbf, 0xcf, 0x74, 0xcd, 0x0b, 0xc1, 0xfe,
      0x24, 0x97, 0xcc, 0x9b, 0x04, 0x25, 0x4c, 0x65, 0x8f, 0x79, 0xf2,
      0x14, 0x53, 0x92, 0x86, 0x7e, 0xa8, 0x36, 0x63, 0x67, 0xcf]

  // The SHA256 hash of the DER SPKI "ecdsa_2017_public" Crx3 test key.
  private static let kPublisherTestKeyHash: [UInt8] = [
      0x6c, 0x46, 0x41, 0x3b, 0x00, 0xd0, 0xfa, 0x0e, 0x72, 0xc8, 0xd2,
      0x5f, 0x64, 0xf3, 0xa6, 0x17, 0x03, 0x0d, 0xde, 0x21, 0x61, 0xbe,
      0xb7, 0x95, 0x91, 0x95, 0x83, 0x68, 0x12, 0xe9, 0x78, 0x1e]
  
  private static func saturatedCast<T: FixedWidthInteger & UnsignedInteger,
                      U: FixedWidthInteger & SignedInteger>(_ val: T) -> U {
    let value = Double(val) + 0.5
    return U(value < 0.0 ? 0.0 : (value > Double(U.max) ? Double(U.max) : value))
  }
  
  private static func UInt32FromLittleEndian(bytes: [UInt8]) -> UInt32 {
    UInt32(bytes[3]) << 24 | UInt32(bytes[2]) << 16 | UInt32(bytes[1]) << 8 | UInt32(bytes[0])
  }
  
  private static func UInt32FromBigEndian(bytes: [UInt8]) -> UInt32 {
    UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
  }
  
  private static func readMagicNumber(file: FileHandle) -> String {
    do {
      if let data = try file.read(upToCount: 4), data.count == 4 {
        return String(data: data, encoding: .utf8) ?? ""
      }
    } catch {
      print(error)
    }
    return ""
  }
  
  private static func readFileVersion(file: FileHandle) -> UInt32 {
    do {
      if let data = try file.read(upToCount: 4), data.count == 4 {
        return UInt32FromLittleEndian(bytes: [UInt8](data))
      }
    } catch {
      print(error)
    }
    return 0
  }
  
  private static func readAndHashBuffer<T: HashFunction>(buffer: inout [UInt8], file: FileHandle, hash: inout T) -> Int32 {
    do {
      if let data = try file.read(upToCount: buffer.count) {
        data.copyBytes(to: &buffer, count: data.count)
        if data.count > 0 {
          hash.update(data: data)
        }
        return Int32(data.count)
      }
    } catch {
      print(error)
    }
    return 0
  }
  
  private static func readAndHashLittleEndianUInt32<T: HashFunction>(file: FileHandle, hash: inout T) -> UInt32 {
    var buffer = [UInt8](repeating: 0, count: 4)
    if readAndHashBuffer(buffer: &buffer, file: file, hash: &hash) != buffer.count {
      return UInt32.max
    }
    return UInt32FromLittleEndian(bytes: buffer)
 }
  
  private static func readHashAndVerifyArchive<T: HashFunction>(file: FileHandle, hash: inout T, verifiers: inout [SignatureVerifierSHA256]) -> Bool {
    var buffer = [UInt8](repeating: 0, count: 1 << 12)
    var len: Int32 = 0

    while true {
      len = readAndHashBuffer(buffer: &buffer, file: file, hash: &hash)
      if len <= 0 {
        break
      }
      
      for i in 0..<verifiers.count {
        verifiers[i].update(data: [UInt8](buffer[0..<Int(len)]))
      }
    }
    
    for i in 0..<verifiers.count {
      if !verifiers[i].verifyFinal() {
        return false
      }
    }
    
    return len == 0
  }
  
  private static func verifyCrx3<Hash: HashFunction>(file: FileHandle,
                                                     hash: inout Hash,
                                                     requiredKeyHashes: [[UInt8]],
                                                     publicKey: inout String,
                                                     crxId: inout String,
                                                     compressedVerifiedContents: inout [UInt8],
                                                     requirePublisherKey: Bool,
                                                     acceptPublisherTestKey: Bool) -> VerifierResult {
    
    // Parse [header-size] and [header].
    let headerSize: Int = saturatedCast(readAndHashLittleEndianUInt32(file: file, hash: &hash))
    if headerSize == Int.max {
      return .headerInvalid
    }
    
    var headerBytes = [UInt8](repeating: 0, count: headerSize)
    if readAndHashBuffer(buffer: &headerBytes, file: file, hash: &hash) != UInt32(headerSize) {
      return .headerInvalid
    }
    
    guard let header = try? CrxFile_CrxFileHeader(serializedData: Data(bytes: headerBytes, count: headerSize)) else {
      return .headerInvalid
    }
    
    // Parse [verified_contents].
    if header.hasVerifiedContents {
      compressedVerifiedContents = [UInt8](header.verifiedContents)
    }
    
    // Parse [signed-header].
    guard let signedHeaderData = try? CrxFile_SignedData(serializedData: header.signedHeaderData) else {
      return .headerInvalid
    }
    
    let crxIdEncoded = signedHeaderData.crxID
    let declaredCrxId = CRXFile.IDUtil.generateIdFromHex(crxIdEncoded.hexEncodedString)
    
    // Create a little-endian representation of [signed-header-size].
    let signedHeaderSize = header.signedHeaderData.count
    let headerSizeOctets = [
      UInt8(signedHeaderSize),
      UInt8(signedHeaderSize >> 8),
      UInt8(signedHeaderSize >> 16),
      UInt8(signedHeaderSize >> 24)
    ]

    // Create a set of all required key hashes.
    var requiredKeySet = Set<[UInt8]>(requiredKeyHashes)
    let proofTypes = [
      (first: header.sha256WithRsa,
       second: SignatureVerifierSHA256.Algorithm.rsaPKCS1SHA256),
      (first: header.sha256WithEcdsa,
       second: SignatureVerifierSHA256.Algorithm.ecdsaSHA256)
    ]
    
    var publicKeyBytes = Data()
    var verifiers = [SignatureVerifierSHA256]()
    
    let publisherKey = kPublisherKeyHash
    var publisherKeyTest: [UInt8]?
    if acceptPublisherTestKey {
      publisherKeyTest = kPublisherTestKeyHash
    }
    
    var foundPublisherKey = false

    // Initialize all verifiers and update them with
    // [prefix][signed-header-size][signed-header].
    // Clear any elements of required_key_set that are encountered, and watch for
    // the developer key.
    for proofType in proofTypes {
      for proof in proofType.first {
        let key = proof.publicKey
        let signature = proof.signature
        
        if CRXFile.IDUtil.generateId(key) == declaredCrxId {
          publicKeyBytes = key
        }
        
        let keyHash = [UInt8](SHA256.hash(data: key))
        requiredKeySet.remove(keyHash)
        
        assert(acceptPublisherTestKey == (publisherKeyTest != nil))
        
        foundPublisherKey = foundPublisherKey || keyHash == publisherKey ||
                            (acceptPublisherTestKey && keyHash == publisherKeyTest)
        
        guard let verifier = SignatureVerifierSHA256(algorithm: proofType.second,
                                                     signature: signature,
                                                     key: key) else {
          return .signatureInitializationFailed
        }
        
        verifier.update(data: CRXFile.MagicHeader.kSignatureContext.utf8CString.map({ UInt8($0) }))
        verifier.update(data: headerSizeOctets)
        verifier.update(data: header.signedHeaderData)
        verifiers.append(verifier)
      }
    }
    
    if publicKeyBytes.isEmpty || !requiredKeySet.isEmpty {
      return .requiredProofMissing
    }
    
    if requirePublisherKey && !foundPublisherKey {
      return .requiredProofMissing
    }
    
    // Update and finalize the verifiers with [archive].
    if !readHashAndVerifyArchive(file: file, hash: &hash, verifiers: &verifiers) {
      return .signatureVerificationFailed
    }
    
    publicKey = publicKeyBytes.base64EncodedString()
    crxId = declaredCrxId
    return .okFull
  }
  
  static func verify(crxPath: String,
                     format: VerifierFormat,
                     requiredKeyHashes: [[UInt8]],
                     requiredFileHash: [UInt8],
                     publicKey: inout String,
                     crxId: inout String,
                     compressedVerifiedContents: inout [UInt8]) -> VerifierResult {
    
    var publicKeyLocal = ""
    var crxIdLocal = ""
    
    guard let file = try? FileHandle(forReadingFrom: URL(fileURLWithPath: crxPath)) else {
      return .fileNotReadable
    }
    
    defer { try? file.close() }
    
    var fileHash = SHA256()
    
    // Magic Number
    var diff = false
    var buffer = [UInt8](repeating: 0, count: CRXFile.MagicHeader.kCrxFileHeaderMagicSize)
    if let data = try? file.read(upToCount: CRXFile.MagicHeader.kCrxFileHeaderMagicSize),
       data.count == CRXFile.MagicHeader.kCrxFileHeaderMagicSize {
      data.copyBytes(to: &buffer, count: CRXFile.MagicHeader.kCrxFileHeaderMagicSize)
    } else {
      return .headerInvalid
    }
    
    if let magicNumber = String(bytes: buffer, encoding: .utf8) {
      if magicNumber == CRXFile.MagicHeader.kCrxDiffFileHeaderMagic {
        diff = true
      } else if magicNumber != CRXFile.MagicHeader.kCrxFileHeaderMagic {
        return .headerInvalid
      }
    } else {
      return .headerInvalid
    }
    
    fileHash.update(data: buffer)
    
    // Version number.
    let version = readAndHashLittleEndianUInt32(file: file, hash: &fileHash)
    var result: VerifierResult = .headerInvalid
    if version == 3 {
      let requirePublisherKey = format == .publisherProof || format == .testWithPublisherProof
      result = verifyCrx3(file: file,
                          hash: &fileHash,
                          requiredKeyHashes: requiredKeyHashes,
                          publicKey: &publicKeyLocal,
                          crxId: &crxIdLocal,
                          compressedVerifiedContents: &compressedVerifiedContents,
                          requirePublisherKey: requirePublisherKey,
                          acceptPublisherTestKey: format == .testWithPublisherProof)
    }
    
    if result != .okFull {
      return result
    }
    
    // Finalize file hash.
    let digest = fileHash.finalize()
    if !requiredFileHash.isEmpty {
      if requiredFileHash.count != SHA256.byteCount {
        return .expecedHashInvalid
      }
      
      if !digest.elementsEqual(requiredFileHash) {
        return .fileHashFailed
      }
    }
    
    // All is well. Set the out-params and return.
    publicKey = publicKeyLocal
    crxId = crxIdLocal
    return diff ? .okDelta : .okFull
  }
}
