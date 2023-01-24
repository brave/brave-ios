// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

private struct AnyCodingKey: CodingKey {
  var stringValue: String
  var intValue: Int?

  init?(intValue: Int) {
    self.stringValue = "\(intValue)"
    self.intValue = intValue
  }

  init?(stringValue: String) {
    self.stringValue = stringValue
  }
}

// MARK: - Encoding

extension KeyedEncodingContainer {
  mutating func encodeAny(_ value: Any, forKey key: KeyedEncodingContainer<K>.Key) throws {
    if let array = value as? [Any] {
      var container = nestedUnkeyedContainer(forKey: key)
      try container.encodeAny(array)
    } else if let dict = value as? [String: Any] {
      var container = nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
      try container.encodeAny(dict)
    } else {
      if value is NSNull {
        try encodeNil(forKey: key)
      } else if let value = value as? Bool {
        try encode(value, forKey: key)
      } else if let value = value as? Int {
        try encode(value, forKey: key)
      } else if let value = value as? Int8 {
        try encode(value, forKey: key)
      } else if let value = value as? Int16 {
        try encode(value, forKey: key)
      } else if let value = value as? Int32 {
        try encode(value, forKey: key)
      } else if let value = value as? Int64 {
        try encode(value, forKey: key)
      } else if let value = value as? Float {
        try encode(value, forKey: key)
      } else if let value = value as? Double {
        try encode(value, forKey: key)
      } else if let value = value as? String {
        try encode(value, forKey: key)
      } else if let value = value as? [Any] {
        try encodeAny(value, forKey: key)
      } else if let value = value as? [String: Any] {
        try encodeAny(value, forKey: key)
      } else {
        throw EncodingError.invalidValue(value, .init(codingPath: codingPath,
                                                      debugDescription: "Serialization Failed"))
      }
    }
  }
  
  mutating func encodeAny(_ value: [Any], forKey key: KeyedEncodingContainer<K>.Key) throws {
    var container = nestedUnkeyedContainer(forKey: key)
    try container.encodeAny(value)
  }
  
  mutating func encodeAny(_ value: [String: Any], forKey key: KeyedEncodingContainer<K>.Key) throws {
    var container = nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)
    try container.encodeAny(value)
  }
  
  mutating func encodeAnyIfPresent(_ value: Any?, forKey key: KeyedEncodingContainer<K>.Key) throws {
    if let value = value {
      try encodeAny(value, forKey: key)
    }
  }
  
  mutating func encodeAnyIfPresent(_ value: [Any]?, forKey key: KeyedEncodingContainer<K>.Key) throws {
    if let value = value {
      try encodeAny(value, forKey: key)
    }
  }
  
  mutating func encodeAnyIfPresent(_ value: [String: Any]?, forKey key: KeyedEncodingContainer<K>.Key) throws {
    if let value = value {
      try encodeAny(value, forKey: key)
    }
  }
  
  fileprivate mutating func encodeAny(_ value: [String: Any]) throws {
    try value.forEach({ (key, value) in
      guard let key = K(stringValue: key) else {
        throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "Serialization Failed"))
      }
      
      try encodeAny(value, forKey: key)
    })
  }
}

extension UnkeyedEncodingContainer {
  mutating func encodeAny(_ value: [Any]) throws {
    for value in value {
      if value is NSNull {
        try encodeNil()
      } else if let value = value as? Bool {
        try encode(value)
      } else if let value = value as? Int {
        try encode(value)
      } else if let value = value as? Int8 {
        try encode(value)
      } else if let value = value as? Int16 {
        try encode(value)
      } else if let value = value as? Int32 {
        try encode(value)
      } else if let value = value as? Int64 {
        try encode(value)
      } else if let value = value as? Float {
        try encode(value)
      } else if let value = value as? Double {
        try encode(value)
      } else if let value = value as? String {
        try encode(value)
      } else if let value = value as? [Any] {
        var container = nestedUnkeyedContainer()
        try container.encodeAny(value)
      } else if let value = value as? [String: Any] {
        var container = nestedContainer(keyedBy: AnyCodingKey.self)
        try container.encodeAny(value)
      } else {
        throw EncodingError.invalidValue(value, .init(codingPath: codingPath,
                                                      debugDescription: "Serialization Failed"))
      }
    }
  }
  
  mutating func encodeAnyIfPresent(_ value: [Any]?) throws {
    if let value = value {
      try encodeAny(value)
    }
  }
}

extension SingleValueEncodingContainer {
  mutating func encodeAny(_ value: Any) throws {
    if value is NSNull {
      try encodeNil()
    } else if let value = value as? Bool {
      try encode(value)
    } else if let value = value as? Int {
      try encode(value)
    } else if let value = value as? Int8 {
      try encode(value)
    } else if let value = value as? Int16 {
      try encode(value)
    } else if let value = value as? Int32 {
      try encode(value)
    } else if let value = value as? Int64 {
      try encode(value)
    } else if let value = value as? Float {
      try encode(value)
    } else if let value = value as? Double {
      try encode(value)
    } else if let value = value as? String {
      try encode(value)
    } else if let value = value as? [Any] {
      try encodeAny(value)
    } else if let value = value as? [String: Any] {
      try encodeAny(value)
    } else {
      throw EncodingError.invalidValue(value, .init(codingPath: codingPath,
                                                    debugDescription: "Serialization Failed"))
    }
  }
  
  mutating func encodeAnyIfPresent(_ value: Any?) throws {
    if let value = value {
      try encodeAny(value)
    }
  }
}

// MARK: - Decoding

extension KeyedDecodingContainer {
  func decodeAny(_ type: Any.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> Any {
    if try decodeNil(forKey: key) {
      return NSNull()
    } else if let value = try? decode(Bool.self, forKey: key) {
      return value
    } else if let value = try? decode(Int.self, forKey: key) {
      return value
    } else if let value = try? decode(Int8.self, forKey: key) {
      return value
    } else if let value = try? decode(Int16.self, forKey: key) {
      return value
    } else if let value = try? decode(Int32.self, forKey: key) {
      return value
    } else if let value = try? decode(Int64.self, forKey: key) {
      return value
    } else if let value = try? decode(Float.self, forKey: key) {
      return value
    } else if let value = try? decode(Double.self, forKey: key) {
      return value
    } else if let value = try? decode(String.self, forKey: key) {
      return value
    } else if let value = try? decodeAny([Any].self, forKey: key) {
      return value
    } else if let value = try? decodeAny([String: Any].self, forKey: key) {
      return value
    } else {
      throw DecodingError.dataCorrupted(.init(codingPath: codingPath,
                                              debugDescription: "Deserialization Failed"))
    }
  }
  
  func decodeAny(_ type: [Any].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [Any] {
    var values = try nestedUnkeyedContainer(forKey: key)
    return try values.decodeAny(type)
  }
  
  func decodeAny(_ type: [String: Any].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [String: Any] {
    try nestedContainer(keyedBy: AnyCodingKey.self, forKey: key).decodeAny(type)
  }
  
  func decodeAnyIfPresent(_ type: Any.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> Any? {
    return contains(key) ? try decodeAny(type, forKey: key) : nil
  }
  
  func decodeAnyIfPresent(_ type: [Any].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [Any]? {
    return contains(key) ? try decodeAny(type, forKey: key) : nil
  }
  
  func decodeAnyIfPresent(_ type: [String: Any].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [String: Any]? {
    return contains(key) ? try decodeAny(type, forKey: key) : nil
  }
  
  fileprivate func decodeAny(_ type: [String: Any].Type) throws -> [String: Any] {
    var result: [String: Any] = [:]
    for key in allKeys {
      result[key.stringValue] = try decodeAny(Any.self, forKey: key)
    }
    return result
  }
}

extension UnkeyedDecodingContainer {
  mutating func decodeAny(_ type: [Any].Type) throws -> [Any] {
    var result: [Any] = []
    while !isAtEnd {
      if try decodeNil() {
        result.append(NSNull())
      } else if let value = try? decode(Bool.self) {
        result.append(value)
      } else if let value = try? decode(Int.self) {
        result.append(value)
      } else if let value = try? decode(Int8.self) {
        result.append(value)
      } else if let value = try? decode(Int16.self) {
        result.append(value)
      } else if let value = try? decode(Int32.self) {
        result.append(value)
      } else if let value = try? decode(Int64.self) {
        result.append(value)
      } else if let value = try? decode(Float.self) {
        result.append(value)
      } else if let value = try? decode(Double.self) {
        result.append(value)
      } else if let value = try? decode(String.self) {
        result.append(value)
      } else if var container = try? nestedUnkeyedContainer(),
                let value = try? container.decodeAny([Any].self) {
        result.append(value)
      } else if let container = try? nestedContainer(keyedBy: AnyCodingKey.self),
                let value = try? container.decodeAny([String: Any].self) {
        result.append(value)
      } else {
        throw DecodingError.dataCorrupted(.init(codingPath: codingPath,
                                                debugDescription: "Deserialization Failed"))
      }
    }
    return result
  }
}

extension SingleValueDecodingContainer {
  func decodeAny(_ type: Any.Type) throws -> Any {
    if decodeNil() {
      return NSNull()
    } else if let value = try? decode(Bool.self) {
      return value
    } else if let value = try? decode(Int.self) {
      return value
    } else if let value = try? decode(Int8.self) {
      return value
    } else if let value = try? decode(Int16.self) {
      return value
    } else if let value = try? decode(Int32.self) {
      return value
    } else if let value = try? decode(Int64.self) {
      return value
    } else if let value = try? decode(Float.self) {
      return value
    } else if let value = try? decode(Double.self) {
      return value
    } else if let value = try? decode(String.self) {
      return value
    } else if let value = try? decodeAny([Any].self) {
      return value
    } else if let value = try? decodeAny([String: Any].self) {
      return value
    } else {
      throw DecodingError.dataCorrupted(.init(codingPath: codingPath,
                                              debugDescription: "Deserialization Failed"))
    }
  }
}
