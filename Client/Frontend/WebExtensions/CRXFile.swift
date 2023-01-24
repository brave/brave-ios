// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CryptoKit

struct CRXFile {
  // A CRX₃ file is a binary file of the following format:
  // [4 octets]: "Cr24", a magic number.
  // [4 octets]: The version of the *.crx file format used (currently 3).
  // [4 octets]: N, little-endian, the length of the header section.
  // [N octets]: The header (the binary encoding of a CrxFileHeader).
  // [M octets]: The ZIP archive.
  // Clients should reject CRX₃ files that contain an N that is too large for the
  // client to safely handle in memory.
  struct MagicHeader {
    static let kCrxFileHeaderMagic = "Cr24"
    static let kCrxDiffFileHeaderMagic = "CrOD"
    static let kCrxFileHeaderMagicSize = 4
    static let kSignatureContext = "CRX3 SignedData"
  }
  
  struct IDUtil {
    // First 16 bytes of SHA256 hashed public key.
    static let kIdSize = 16
    
    // Converts a normal hexadecimal string into the alphabet used by extensions.
    // We use the characters 'a'-'p' instead of '0'-'f' to avoid ever having a
    // completely numeric host, since some software interprets that as an IP
    // address.
    private static func convertHexadecimalToIDAlphabet(_ id: String) -> String {
      func HexToInt(_ ch: Character) -> Int {
        guard ch.unicodeScalars.count == 1,
              let ch = ch.unicodeScalars.first?.value else {
          return -1
        }
        
        if ch >= 0x30 && ch <= 0x39 {
          return Int(ch - 0x30)
        }
          
        if ch >= 0x41 && ch <= 0x46 {
          return Int((ch - 0x41) + 10)
        }
          
        if ch >= 0x61 && ch <= 0x66 {
          return Int((ch - 0x61) + 10)
        }
        
        return -1
      }
      
      var result = ""
      for ch in id {
        let val = HexToInt(ch)
        if val == -1 {
          result += "a"
        } else {
          result += String(Unicode.Scalar(0x61 + val)!)
        }
      }
      return result
    }
    
    static func generateId(_ input: Data) -> String {
      let hash = [UInt8](SHA256.hash(data: input))
      return generateIdFromHash([UInt8](hash[0..<kIdSize]))
    }
    
    static func generateIdFromHex(_ input: String) -> String {
      return convertHexadecimalToIDAlphabet(input)
    }
    
    static func generateIdFromHash(_ hash: [UInt8]) -> String {
      assert(hash.count >= kIdSize)
      if hash.count < kIdSize {
        return ""
      }
      
      return convertHexadecimalToIDAlphabet(hash.hexEncodedString)
    }
    
    static func hashedIdInHex(_ id: String) -> String {
      if let data = id.data(using: .utf8) {
        let hash = [UInt8](Insecure.SHA1.hash(data: data))
        assert(hash.count == Insecure.SHA1.byteCount)
        return hash.hexEncodedString
      }
      return ""
    }
    
    static func maybeNormalizePath(path: String) -> String {
      // Only useful to normalize path on Windows...
      return path
    }
    
    static func isValidId(id: String) -> Bool {
      if id.count != kIdSize * 2 {
        return false
      }
      
      for c in id {
        let ch = c.lowercased()
        if ch < "a" || ch > "p" {
          return false
        }
      }
      return true
    }
  }
}
