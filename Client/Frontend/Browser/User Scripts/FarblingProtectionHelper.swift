// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// A class that helps in creating farbling data
class FarblingProtectionHelper {
  /// Variables representing the prefix of a randomly generated strings used as the plugin name
  private static let pluginNameFirstParts: [String?] = [
    "Chrome", "Chromium", "Brave", "Web", "Browser",
    "OpenSource", "Online", "JavaScript", "WebKit",
    "Web-Kit", "WK", nil
  ]

  /// Variables representing the middle of a randomly generated strings used as the plugin name
  private static let pluginNameSecondParts: [String?] = [
    "PDF", "Portable Document Format",
    "portable-document-format", "document", "doc",
    "PDF and PS", "com.adobe.pdf", nil
  ]

  /// Variables representing the suffix of a randomly generated strings used as the plugin name
  private static let pluginNameThirdParts: [String?] = [
    "Viewer", "Renderer", "Display", "Plugin",
    "plug-in", "plug in", "extension", nil
  ]

  /// Generate fake plugin data to be injected into the farbling protection script
  static func makeFakePluginData(from randomManager: RandomManager) -> String {
    var generator = ARC4RandomNumberGenerator(seed: randomManager.seed)
    let pluginCount = Int.random(in: 1...3, using: &generator)

    // Generate 1 to 3 fake plugins
    let fakePlugins = (0..<pluginCount).map { pluginIndex -> JSDataType in
      let mimeTypesCount = Int.random(in: 1...3, using: &generator)

      // Generate 1 to 3 fake mime types
      let mimeTypes = (0..<mimeTypesCount).map { mimeTypeIndex -> JSDataType in
        return .object([
          "suffixes": .string("pdf"),
          "type": .string("application/pdf"),
          "description": .string(randomPluginName(from: &generator))
        ])
      }

      return .object([
        "name": .string(randomPluginName(from: &generator)),
        "filename": .string(""),
        "description": .string(randomPluginName(from: &generator)),
        "mimeTypes": .array(mimeTypes)
      ])
    }

    // Convert the object into a string and return it
    let fakeData: JSDataType = .array(fakePlugins)
    return String(describing: fakeData)
  }

  /// Generate a random string using a prefix, middle and suffix where any of those may be empty.
  /// - Note: May result in an empty string.
  static func randomPluginName<T: RandomNumberGenerator>(from generator: inout T) -> String {
    return [
      pluginNameFirstParts.randomElement(using: &generator) ?? nil,
      pluginNameSecondParts.randomElement(using: &generator) ?? nil,
      pluginNameThirdParts.randomElement(using: &generator) ?? nil
    ].compactMap({ $0 }).joined(separator: " ")
  }
}
