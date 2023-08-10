// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UniformTypeIdentifiers
import AVFoundation

struct MIMEType {
  var value: String
  var fileExtension: String?
  
  init(value: String, fileExtension: String?) {
    self.value = value
    self.fileExtension = fileExtension
  }
  
  private init?(uniformType type: UTType) {
    guard let value = type.preferredMIMEType else {
      return nil
    }
    self.value = value
    self.fileExtension = type.preferredFilenameExtension
  }
  
  static func from(url: URL, userAgent: String? = nil) async -> MIMEType? {
    // Begin a request to get the type
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
    request.addValue("bytes=0-1", forHTTPHeaderField: "Range")
    request.addValue(UUID().uuidString, forHTTPHeaderField: "X-Playback-Session-Id")
    if let userAgent {
      request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
    }
    
    let session = URLSession(configuration: .ephemeral)
    do {
      let (_, response) = try await session.data(for: request)
      session.finishTasksAndInvalidate()
      guard let response = response as? HTTPURLResponse, response.statusCode == 302 || (200...299).contains(response.statusCode), let mimeType = response.mimeType, !mimeType.isEmpty, let type = UTType(mimeType: mimeType) else {
        return nil
      }
      return .init(uniformType: type)
    } catch {
      return nil
    }
  }
  
  init?(url: URL) {
    let pathExtension = url.pathExtension.lowercased()
    if Self.knownMediaExtensions.contains(pathExtension), let mimeType = Self.mimeTypeMap.first(where: { $0.value == pathExtension })?.key {
      self.init(value: mimeType, fileExtension: pathExtension)
      return
    }
    
    guard let uniformType = UTType(filenameExtension: pathExtension),
          AVURLAsset.audiovisualUTTypes.contains(uniformType) else {
      return nil
    }
    
    self.init(uniformType: uniformType)
  }
  
  init?(knownMediaMIMEType: String) {
    let mimeType = knownMediaMIMEType.lowercased()
    if let fileExtension = Self.mimeTypeMap[mimeType] {
      self.init(value: mimeType, fileExtension: fileExtension)
      return
    }
    
    guard let uniformType = UTType(mimeType: knownMediaMIMEType),
          AVURLAsset.audiovisualUTTypes.contains(uniformType) else {
      return nil
    }
    
    self.init(uniformType: uniformType)
  }
  
  init?(data: Data) {
    struct ByteLookup {
      var mimeType: String
      var fileExtension: String?
      var patterns: [(offset: Int, signature: [UInt8])]
      
      init(mimeType: String, fileExtension: String? = nil, offset: Int = 0, signature: [UInt8]) {
        self.mimeType = mimeType
        self.fileExtension = fileExtension
        self.patterns = [(offset, signature)]
      }
      
      init(mimeType: String, fileExtension: String? = nil, patterns: [(offset: Int, signature: [UInt8])]) {
        self.mimeType = mimeType
        self.fileExtension = fileExtension
        self.patterns = patterns
      }
    }
    
    let lookups: [ByteLookup] = [
      .init(mimeType: "video/webm", signature: [0x1A, 0x45, 0xDF, 0xA3]),
//      .init(mimeType: "video/matroska", fileExtension: "mkv", signatures: [0x1A, 0x45, 0xDF, 0xA3]) // Unsupported
      .init(mimeType: "application/ogg", fileExtension: "ogg", signature: [0x4F, 0x67, 0x67, 0x53]),
      .init(mimeType: "audio/x-wav", patterns: [(0, [0x52, 0x49, 0x46, 0x46]), (8, [0x57, 0x41, 0x56, 0x45])]),
      .init(mimeType: "audio/mpeg", fileExtension: "mp4", signature: [0xFF, 0xFB]),
      .init(mimeType: "audio/mpeg", fileExtension: "mp4", signature: [0x49, 0x44, 0x33]),
      .init(mimeType: "audio/flac", signature: [0x66, 0x4C, 0x61, 0x43]),
      .init(mimeType: "video/mp4", offset: 4, signature: [0x66, 0x74, 0x79, 0x70, 0x4D, 0x53, 0x4E, 0x56]),
      .init(mimeType: "video/mp4", offset: 4, signature: [0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D]),
      .init(mimeType: "video/mp4", offset: 4, signature: [0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32]),
      .init(mimeType: "video/mp4", offset: 4, signature: [0x33, 0x67, 0x70, 0x35]),
      .init(mimeType: "video/x-m4v", signature: [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x56]),
      .init(mimeType: "video/quicktime", signature: [0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70]),
      .init(mimeType: "video/x-msvideo", patterns: [(0, [0x52, 0x49, 0x46, 0x46]), (8, [0x41, 0x56, 0x49])]),
      .init(mimeType: "video/x-ms-wmv", signature: [0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9]),
      .init(mimeType: "video/mpeg", signature: [0x00, 0x00, 0x01]), // Maybe
      .init(mimeType: "audio/mpeg", signature: [0x49, 0x44, 0x33]),
      .init(mimeType: "audio/mpeg", signature: [0xFF, 0xFB]),
      .init(mimeType: "audio/m4a", fileExtension: "m4a", signature: [0x4D, 0x34, 0x41, 0x20]),
      .init(mimeType: "audio/m4a", fileExtension: "m4a", offset: 4, signature: [0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41]),
      .init(mimeType: "audio/amr", signature: [0x23, 0x21, 0x41, 0x4D, 0x52, 0x0A]),
      .init(mimeType: "video/x-flv", signature: [0x46, 0x4C, 0x56, 0x01]),
    ]
    
    for lookup in lookups {
      if lookup.patterns.allSatisfy({ pattern in
        [UInt8](data[pattern.offset..<(pattern.offset + pattern.signature.count)]) == pattern.signature
      }) {
        self.init(value: lookup.mimeType, fileExtension: lookup.fileExtension ?? UTType(mimeType: lookup.mimeType)?.preferredFilenameExtension)
        return
      }
    }
    
    self.init(value: "application/x-mpegURL", fileExtension: nil) // application/vnd.apple.mpegurl
  }
  
  static let knownMediaExtensions: Set<String> = [
    "mov",
    "qt",
    "mp4",
    "m4v",
    "m4a",
    "m4b",  // DRM protected
    "m4p",  // DRM protected
    "3gp",
    "3gpp",
    "sdv",
    "3g2",
    "3gp2",
    "caf",
    "wav",
    "wave",
    "bwf",
    "aif",
    "aiff",
    "aifc",
    "cdda",
    "amr",
    "mp3",
    "au",
    "snd",
    "ac3",
    "eac3",
    "flac",
    "aac",
    "mp2",
    "pls",
    "avi",
    "webm",
    "ogg",
    "mpg",
    "mpg4",
    "mpeg",
    "mpg3",
    "wma",
    "wmv",
    "swf",
    "flv",
    "mng",
    "asx",
    "asf",
    "mkv",
  ]
  
  static let mimeTypeMap = [
    "audio/x-wav": "wav",
    "audio/vnd.wave": "wav",
    "audio/aacp": "aacp",
    "audio/mpeg3": "mp3",
    "audio/mp3": "mp3",
    "audio/x-caf": "caf",
    "audio/mpeg": "mp3",  // mpg3
    "audio/x-mpeg3": "mp3",
    "audio/wav": "wav",
    "audio/flac": "flac",
    "audio/x-flac": "flac",
    "audio/mp4": "mp4",
    "audio/x-mpg": "mp3",  // maybe mpg3
    "audio/scpls": "pls",
    "audio/x-aiff": "aiff",
    "audio/usac": "eac3",  // Extended AC3
    "audio/x-mpeg": "mp3",
    "audio/wave": "wav",
    "audio/x-m4r": "m4r",
    "audio/x-mp3": "mp3",
    "audio/amr": "amr",
    "audio/aiff": "aiff",
    "audio/3gpp2": "3gp2",
    "audio/aac": "aac",
    "audio/mpg": "mp3",  // mpg3
    "audio/mpegurl": "mpg",  // actually .m3u8, .m3u HLS stream
    "audio/x-m4b": "m4b",
    "audio/x-m4p": "m4p",
    "audio/x-scpls": "pls",
    "audio/x-mpegurl": "mpg",  // actually .m3u8, .m3u HLS stream
    "audio/x-aac": "aac",
    "audio/3gpp": "3gp",
    "audio/basic": "au",
    "audio/au": "au",
    "audio/snd": "snd",
    "audio/x-m4a": "m4a",
    "audio/x-realaudio": "ra",
    "video/3gpp2": "3gp2",
    "video/quicktime": "mov",
    "video/mp4": "mp4",
    "video/mp4v": "mp4",
    "video/mpg": "mpg",
    "video/mpeg": "mpeg",
    "video/x-mpg": "mpg",
    "video/x-mpeg": "mpeg",
    "video/avi": "avi",
    "video/x-m4v": "m4v",
    "video/mp2t": "ts",
    "application/vnd.apple.mpegurl": "mpg",  // actually .m3u8, .m3u HLS stream
    "video/3gpp": "3gp",
    "text/vtt": "vtt",  // Subtitles format
    "application/mp4": "mp4",
    "application/x-mpegurl": "mpg",  // actually .m3u8, .m3u HLS stream
    "video/webm": "webm",
    "application/ogg": "ogg",
    "video/msvideo": "avi",
    "video/x-msvideo": "avi",
    "video/x-ms-wmv": "wmv",
    "video/x-ms-wma": "wma",
    "application/x-shockwave-flash": "swf",
    "video/x-flv": "flv",
    "video/x-mng": "mng",
    "video/x-ms-asx": "asx",
    "video/x-ms-asf": "asf",
    "video/matroska": "mkv",
  ]
}

extension AVURLAsset {
  /// The set of audiovisual UTType's that are supported by
  static var audiovisualUTTypes: Set<UTType> {
    Set(audiovisualMIMETypes().compactMap { UTType(mimeType: $0) })
  }
  
  static func isMIMETypeSupported(_ mimeType: String) -> Bool {
    guard let type = UTType(mimeType: mimeType) else { return false }
    return audiovisualUTTypes.contains(type)
  }
}
