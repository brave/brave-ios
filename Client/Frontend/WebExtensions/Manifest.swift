// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct WebExtensionManifest: Codable {
  // Required
  let manifestVersion: Double
  let name: String
  let version: String
  let updateUrl: String

  // Recommended
  let action: Action?
  let defaultLocale: String?
  let description: String?
  let icons: Icons?

  // Optional
  let author: [String: Any]?
  let automation: String?
  let background: Background?

  let permissions: [String]?

  struct Action: Codable {

  }

  struct Icons: Codable {

  }

  struct Background: Codable {
    // Required
    let serviceWorker: String?

    // Optional
    let type: String?
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    manifestVersion = try container.decode(Double.self, forKey: .manifestVersion)
    name = try container.decode(String.self, forKey: .name)
    version = try container.decode(String.self, forKey: .version)
    updateUrl = try container.decode(String.self, forKey: .updateUrl)
    
    action = try container.decodeIfPresent(Action.self, forKey: .action)
    defaultLocale = try container.decodeIfPresent(String.self, forKey: .defaultLocale)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    icons = try container.decodeIfPresent(Icons.self, forKey: .icons)
    
    do {
      author = try container.decodeAnyIfPresent([String: Any].self, forKey: .author)
    } catch {
      if let name = try container.decodeIfPresent(String.self, forKey: .author) {
        author = ["name": name]
      } else {
        author = nil
      }
    }
    automation = try container.decodeIfPresent(String.self, forKey: .automation)
    background = try container.decodeIfPresent(Background.self, forKey: .background)
    permissions = try container.decodeIfPresent([String].self, forKey: .permissions)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(manifestVersion, forKey: .manifestVersion)
    try container.encode(name, forKey: .name)
    try container.encode(version, forKey: .version)
    try container.encode(updateUrl, forKey: .updateUrl)
    try container.encodeIfPresent(action, forKey: .action)
    try container.encodeIfPresent(defaultLocale, forKey: .defaultLocale)
    try container.encodeIfPresent(description, forKey: .description)
    try container.encodeIfPresent(icons, forKey: .icons)
    try container.encodeAnyIfPresent(author, forKey: .author)
    try container.encodeIfPresent(automation, forKey: .automation)
    try container.encodeIfPresent(background, forKey: .background)
    try container.encodeIfPresent(permissions, forKey: .permissions)
  }

  private enum CodingKeys: String, CodingKey {
    case manifestVersion = "manifest_version"
    case name
    case version
    case updateUrl = "update_url"

    case action
    case defaultLocale = "default_locale"
    case description
    case icons

    case author
    case automation
    case background
    case permissions
  }
}

struct WebExtensionDetails: Codable {
  let id: String
  let manifest: WebExtensionManifest
  let iconUrl: String?  // Optional
  let localizedName: String  // Optional
  let locale: String?  // Optional
  let appInstallBubble: Bool  // Optional
  let enableLauncher: Bool  // Optional
  let authUser: String?  // Optional
  let esbAllowlist: Bool  // Optional
  let additionalProperties: [String: Any]?  // Arbitrary properties
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let manifestString = try container.decode(String.self, forKey: .manifest)

    id = try container.decode(String.self, forKey: .id)
    manifest = try JSONDecoder().decode(WebExtensionManifest.self, from: manifestString.data(using: .utf8)!)
    iconUrl = try container.decodeIfPresent(String.self, forKey: .iconUrl) ?? ""
    localizedName = try container.decodeIfPresent(String.self, forKey: .localizedName) ?? ""
    locale = try container.decodeIfPresent(String.self, forKey: .locale)
    appInstallBubble = try container.decodeIfPresent(Bool.self, forKey: .appInstallBubble) ?? false
    enableLauncher = try container.decodeIfPresent(Bool.self, forKey: .enableLauncher) ?? false
    authUser = try container.decodeIfPresent(String.self, forKey: .authUser)
    esbAllowlist = try container.decodeIfPresent(Bool.self, forKey: .esbAllowlist) ?? false
    additionalProperties = try container.decodeAnyIfPresent([String: Any].self, forKey: .additionalProperties)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(manifest, forKey: .manifest)
    try container.encode(iconUrl, forKey: .iconUrl)
    try container.encode(localizedName, forKey: .localizedName)
    try container.encode(locale, forKey: .locale)
    try container.encode(appInstallBubble, forKey: .appInstallBubble)
    try container.encode(enableLauncher, forKey: .enableLauncher)
    try container.encode(authUser, forKey: .authUser)
    try container.encode(esbAllowlist, forKey: .esbAllowlist)
    try? container.encodeAnyIfPresent(additionalProperties, forKey: .additionalProperties)
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case manifest
    case iconUrl
    case localizedName
    case locale
    case appInstallBubble
    case enableLauncher
    case authUser = "authuser"
    case esbAllowlist
    case additionalProperties
  }
}

struct WebExtensionInfo: Codable {
  let id: String
  let manifest: String
  let iconUrl: String?  // Optional
  let localizedName: String  // Optional
  let locale: String?  // Optional
  let appInstallBubble: Bool  // Optional
  let enableLauncher: Bool  // Optional
  let authUser: String?  // Optional
  let esbAllowlist: Bool  // Optional
  let additionalProperties: [String: Any]?  // Arbitrary properties
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    manifest = try container.decode(String.self, forKey: .manifest)
    iconUrl = try container.decodeIfPresent(String.self, forKey: .iconUrl) ?? ""
    localizedName = try container.decodeIfPresent(String.self, forKey: .localizedName) ?? ""
    locale = try container.decodeIfPresent(String.self, forKey: .locale)
    appInstallBubble = try container.decodeIfPresent(Bool.self, forKey: .appInstallBubble) ?? false
    enableLauncher = try container.decodeIfPresent(Bool.self, forKey: .enableLauncher) ?? false
    authUser = try container.decodeIfPresent(String.self, forKey: .authUser)
    esbAllowlist = try container.decodeIfPresent(Bool.self, forKey: .esbAllowlist) ?? false
    additionalProperties = try container.decodeAnyIfPresent([String: Any].self, forKey: .additionalProperties)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(manifest, forKey: .manifest)
    try container.encode(iconUrl, forKey: .iconUrl)
    try container.encode(localizedName, forKey: .localizedName)
    try container.encode(locale, forKey: .locale)
    try container.encode(appInstallBubble, forKey: .appInstallBubble)
    try container.encode(enableLauncher, forKey: .enableLauncher)
    try container.encode(authUser, forKey: .authUser)
    try container.encode(esbAllowlist, forKey: .esbAllowlist)
    try? container.encodeAnyIfPresent(additionalProperties, forKey: .additionalProperties)
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case manifest
    case iconUrl
    case localizedName
    case locale
    case appInstallBubble
    case enableLauncher
    case authUser = "authuser"
    case esbAllowlist
    case additionalProperties
  }
}
