// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared

protocol ASN1Node: CustomStringConvertible {
}

struct ASN1 {
  struct Sequence: ASN1Node {
    let values: [ASN1Node]
    
    var description: String {
      "Sequence: {\(values)}"
    }
  }
  
  struct Set: ASN1Node {
    let values: [ASN1Node]  // Set<ASN1Node>
    
    var description: String {
      "Set: {\(values)}"
    }
  }

  struct ObjectIdentifier: ASN1Node {
    let data: Data
    
    var description: String {
      do {
        return "ObjectIdentifier: \(try BraveCertificateUtils.oid_to_absolute_oid(oid: Array(data)))"
      } catch {
        return "ObjectIdentifier: \(data)"
      }
    }
  }

  struct OctetString: ASN1Node {
    let data: Any  // Data OR ANS1Node
    
    var description: String {
      "OctetString: \(data)"
    }
  }

  struct BitString: ASN1Node {
    let data: Data
    
    var description: String {
      "BitString: [...\(data.count)]"
    }
  }
  
  struct UTF8String: ASN1Node {
    let string: String
    
    var description: String {
      "\(string)"
    }
  }
  
  struct PrintableString: ASN1Node {
    let string: String
    
    var description: String {
      "\(string)"
    }
  }
  
  struct IA5String: ASN1Node {
    let string: String
    
    var description: String {
      "\(string)"
    }
  }

  struct Integer: ASN1Node {
    let data: Data
    
    var description: String {
      if data.count == MemoryLayout<UInt8>.size {
        return "\(UInt8(littleEndian: data.withUnsafeBytes { $0.pointee }))"
      } else if data.count == MemoryLayout<UInt16>.size {
        return "\(UInt16(littleEndian: data.withUnsafeBytes { $0.pointee }))"
      } else if data.count == MemoryLayout<UInt32>.size {
        return "\(UInt32(littleEndian: data.withUnsafeBytes { $0.pointee }))"
      } else if data.count == MemoryLayout<UInt64>.size {
        return "\(UInt64(littleEndian: data.withUnsafeBytes { $0.pointee }))"
      } else {
        return "\(data)"
      }
    }
  }
  
  struct Boolean: ASN1Node {
    let value: Bool
    
    var description: String {
      "\(value)"
    }
  }

  struct Null: ASN1Node {
    var description: String {
      "null"
    }
  }
  
  struct UTCDate: ASN1Node {
    let date: Date
    
    var description: String {
      "\(date)"
    }
  }
  
  struct ContextSpecific: ASN1Node {
    let index: Int
    let value: ASN1Node
    
    var description: String {
      "[\(index)]: \(value)"
    }
  }
}

struct ASN1Parser {
//  enum ASN1Node {
//    case sequence(values: [ASN1Node])
//    case objectIdentifier(data: Data)
//    case octetString(data: Data)
//    case bitString(data: Data)
//    case integer(data: Data)
//    case null
//  }
  
  func parse(data: Data) throws -> ASN1Node {
    return try parseNode(reader: Reader(data: data))
  }
  
  private func parseNode(reader: Reader) throws -> ASN1Node {
    let tagId = try reader.read(count: 1)[0]
    
    switch tagId {
      // Sequence
      case 0x30:
        let length = try reader.readLength()
        let data = try reader.read(count: length)
        return ASN1.Sequence(values: try parseSequence(data: data))
      
      // Set
      case 0x31:
        let length = try reader.readLength()
        let data = try reader.read(count: length)
        return ASN1.Set(values: try parseSet(data: data))
    
      // Object Identifier
      case 0x06:
//        let length = try reader.readLength()
//        let data = try reader.read(count: length)
//        return ASN1.ObjectIdentifier(data: data)
        return ASN1.ObjectIdentifier(data: try reader.readOID())
      
      // Octet String
      case 0x04:
        let length = try reader.readLength()
        let data = try reader.read(count: length)
      
        do {
          return ASN1.OctetString(data: try parse(data: data))
        } catch {
          return ASN1.OctetString(data: data)
        }
      
      // Bit String
      case 0x03:
        let length = try reader.readLength()
        _ = try reader.read(count: 1) // BitString has `0x00` reserved after `Length`
        let data = try reader.read(count: length - 1)
        return ASN1.BitString(data: data)
      
      // UTF-8 String
      case 0x0C:
        let length = try reader.readLength()
        let data = try reader.read(count: length)
        return ASN1.UTF8String(string: String(data: data, encoding: .utf8)!)
      
      // PrintableString
      case 0x13:
        let length = try reader.readLength()
        let data = try reader.read(count: length)
        return ASN1.PrintableString(string: String(data: data, encoding: .ascii)!)  // No idea encoding
      
      // IA5String
      case 0x16:
        let length = try reader.readLength()
        let data = try reader.read(count: length)
        return ASN1.IA5String(string: String(data: data, encoding: .ascii)!)
      
      // UTC Time
      case 0x17:
        let length = Int(try reader.read(count: 1)[0])
        let data = try reader.read(count: length)
        let dateString = String(data: data, encoding: .ascii)!
      
        let formatter = DateFormatter()
        let formats = ["yyMMddHHmmZ", "yyMMddHHmm+hh'mm'",
                       "YYMMddHHmm-hh'mm'", "yyMMddHHmmssZ",
                       "yyMMddHHmmss+hh'mm'", "yyMMddHHmmss-HH'mm'"]
        
      for format in formats {
        formatter.dateFormat = format
        if let date = formatter.date(from: dateString) {
          return ASN1.UTCDate(date: date)
        }
      }
      
      throw Reader.ReaderError.unknownType
      
      // Boolean
      case 0x01:
        let length = try reader.readLength()
        let data = try reader.read(count: length)
        return ASN1.Boolean(value: data[0] == 0xFF)
      
      // Integer
      case 0x02:
        let length = try reader.readLength()
        let data = try reader.read(count: length)
        return ASN1.Integer(data: data)
      
      // Null
      case 0x05:
        _ = try reader.read(count: 1)
        return ASN1.Null()
      
      // Context-Specific Simple Tag
      case 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
           0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F,
           0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99,
           0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F:
        throw Reader.ReaderError.unknownType
      
      // Context-Specific Structured Tag
      case 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9,
           0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF,
           0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9,
           0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF:
        let index = tagId - 0xA0
        let length = try reader.readLength()
        let data = try reader.read(count: length)
        return try ASN1.ContextSpecific(index: Int(index), value: parse(data: data))
      
      default:
        throw Reader.ReaderError.unknownType
    }
  }
  
  private func parseSequence(data: Data) throws -> [ASN1Node] {
    let reader = Reader(data: data)
    var values = [ASN1Node]()
    while reader.hasMoreContent {
      let node = try parseNode(reader: reader)
      values.append(node)
    }
    return values
  }
  
  private func parseSet(data: Data) throws -> [ASN1Node] /* Set<ASN1Node> */ {
    let reader = Reader(data: data)
    var values = [ASN1Node]()
    while reader.hasMoreContent {
      let node = try parseNode(reader: reader)
      values.append(node)
    }
    return values
  }
  
  private class Reader {
    private let data: Data
    private var offset: Int
    var hasMoreContent: Bool {
      data.count > offset
    }
    
    enum ReaderError: String, Error {
      case insufficientData
      case unknownType
    }
    
    init(data: Data) {
      self.data = data
      self.offset = 0
    }
    
    func read(count: Int) throws -> Data {
      if count == 0 {
        return Data()
      }
      
      if count + offset > data.count {
        throw ReaderError.insufficientData
      }
      
      defer { offset += count }
      return data.subdata(in: offset..<offset + count)
    }
    
    // Read Length of the Tag-Length-Value
    // See: docs.microsoft.com/en-us/windows/win32/seccertenroll/about-encoded-length-and-value-bytes
    func readLength() throws -> Int {
      let length = try Int(read(count: 1)[0])
      if length & 0x80 == 0 {
        // Current byte = length
        return length
      }
      
      // Next bytes = length
      let data = try read(count: length & 0x7F)
      var actualLength = 0
      for byte in data {
        actualLength = (actualLength << 8) | Int(byte)
      }
      return Int(actualLength)
    }
    
    func readOID() throws -> Data {
      let length = try self.readLength()
      let dataOffset = self.offset + length
      
      self.offset = 0
      return try self.read(count: dataOffset)
    }
  }
}
