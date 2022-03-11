// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import CryptoKit
import GameplayKit

/// An error representing failures in loading scripts
enum ScriptLoadFailure: Error {
  case notFound
}

/// An enum representing the unmodified local scripts stored in the application.
///
/// - Warning: Some of these scripts are not usable "as-is". Rather, you should be using `UserScriptType`.
enum ScriptSourceType {
  /// A simple encryption library found here:
  /// https://www.npmjs.com/package/tweetnacl
  case nacl
  
  /// This script farbles certian system methods to output slightly randomized output.
  /// This script has a dependency on `nacl`.
  ///
  /// This script has the following dynamic variables:
  /// - `$<fudge_factor>`: A random value between 0.99 and 1
  case farblingProtection
  
  /// A YouTube ad blocking script
  case youtubeAdBlock
  case archive
  case braveSearchHelper
  case braveTalkHelper
  
  fileprivate var fileName: String {
    switch self {
    case .nacl: return "nacl.min"
    case .farblingProtection: return "FarblingProtection"
    case .youtubeAdBlock: return "YoutubeAdblock"
    case .archive: return "ArchiveIsCompat"
    case .braveSearchHelper: return "BraveSearchHelper"
    case .braveTalkHelper: return "BraveTalkHelper"
    }
  }
  
  fileprivate func loadScript() throws -> String {
    guard let path = Bundle.main.path(forResource: fileName, ofType: "js") else {
      assertionFailure("Cannot load script. This should not happen as it's part of the codebase")
      throw ScriptLoadFailure.notFound
    }
    
    return try String(contentsOfFile: path)
  }
}

/// An enum representing a specific (modified) variation of a local script replacing any dynamic variables.
enum UserScriptType: Hashable {
  /// This type does farbling protection and is customized for the provided ETLD+1
  /// Has a dependency on `nacl`
  case farblingProtection(etld: String)
  /// Scripts specific to certain domains
  case domainUserScript(DomainUserScript)
  /// A symple encryption library to be used by other scripts
  case nacl
  
  /// Return a source typ for this script type
  var sourceType: ScriptSourceType {
    switch self {
    case .farblingProtection:
      return .farblingProtection
    case .domainUserScript(let domainUserScript):
      switch domainUserScript {
      case .youtubeAdBlock:
        return .youtubeAdBlock
      case .archive:
        return .archive
      case .braveSearchHelper:
        return .braveSearchHelper
      case .braveTalkHelper:
        return .braveTalkHelper
      }
    case .nacl:
      return .nacl
    }
  }
  
  /// The order in which we want to inject the scripts
  var order: Int {
    switch self {
    case .nacl: return 0
    case .farblingProtection: return 1
    case .domainUserScript: return 2
    }
  }
  
  var injectionTime: WKUserScriptInjectionTime {
    switch self {
    case .farblingProtection, .domainUserScript, .nacl:
      return .atDocumentStart
    }
  }
  
  var forMainFrameOnly: Bool {
    switch self {
    case .farblingProtection, .domainUserScript, .nacl:
      return false
    }
  }
  
  var contentWorld: WKContentWorld {
    switch self {
    case .farblingProtection, .domainUserScript:
      return .page
    case .nacl:
      return .page
    }
  }
}

/// A class that helps in the aid of creating and caching scripts.
class ScriptFactory {
  /// A shared instance to be shared throughout the app.
  ///
  /// - Note: Perhaps we will move this to the tab to be managed on a tab basis.
  static let shared = ScriptFactory()
  
  /// Ensures that the message handlers cannot be invoked by the page scripts
  public static let messageHandlerTokenString: String = {
    return UUID().uuidString.replacingOccurrences(of: "-", with: "", options: .literal)
  }()
  
  /// This contains cahced script sources for a script type. Avoids reading from disk.
  private var cachedScriptSources: [ScriptSourceType: String]
  
  /// This contains cached altered scripts that are ready to be inected. Avoids replacing strings.
  private var cachedDomainScriptsSources: [UserScriptType: WKUserScript]
  
  init() {
    cachedScriptSources = [:]
    cachedDomainScriptsSources = [:]
  }
  
  /// Clear some caches in case we need to.
  ///
  /// Should only really be called in a memory warning scenario.
  func clearCaches() {
    cachedScriptSources = [:]
    cachedDomainScriptsSources = [:]
    SeedManager.shared.clearCache()
  }
  
  /// Returns a script source by loading a file or returning cached data
  private func makeScriptSource(of type: ScriptSourceType) throws -> String {
    if let source = cachedScriptSources[type] {
      return source
    } else {
      let source = try type.loadScript()
      cachedScriptSources[type] = source
      return source
    }
  }
  
  /// Get a script for the `UserScriptType`.
  ///
  /// Scripts can be cached on two levels:
  /// - On the unmodified source file (per `ScriptSourceType`)
  /// - On the modfied source file (per `UserScriptType`)
  func makeScript(for domainType: UserScriptType) throws -> WKUserScript {
    var source = try makeScriptSource(of: domainType.sourceType)
    
    // First check for and return cached value
    if let script = cachedDomainScriptsSources[domainType] {
      return script
    }
    
    switch domainType {
    case .farblingProtection(let etld):
      let seed = SeedManager.shared.getSeed(forETLD: etld)
      // From the seed, let's generate a fudge factor between 0.99 and 1
      // `GKMersenneTwisterRandomSource` gives us a value between 0.0 and 1.0,
      // so we convert it to a value between 0.99 and 1.
      // It's important that this value is between 0.99 and 1 (especially less than 1)
      // As we are multiplying it by values betwen -1 and 1 and if the value is too small
      // It will manipulate the values too much and make it noticible to the user and if
      // it is greater than 1 it has the potential to be out of the appropriate range giving us JS errors.
      let randomSource = GKMersenneTwisterRandomSource(seed: seed)
      let fudgeFactor = 0.99 + (randomSource.nextUniform() / 100)
      
      source = source
        .replacingOccurrences(of: "$<fudge_factor>", with: "\(fudgeFactor)", options: .literal)
      
    case .nacl:
      // No modifications needed
      break
      
    case .domainUserScript(let domainUserScript):
      switch domainUserScript {
      case .youtubeAdBlock:
        // Verify that the application itself is making a call to the JS script instead of other scripts on the page.
        // This variable will be unique amongst scripts loaded in the page.
        // When the script is called, the token is provided in order to access the script variable.
        let securityToken = UserScriptManager.securityTokenString
        
        source = source
          .replacingOccurrences(of: "$<prunePaths>", with: "ABSPP\(securityToken)", options: .literal)
          .replacingOccurrences(of: "$<findOwner>", with: "ABSFO\(securityToken)", options: .literal)
          .replacingOccurrences(of: "$<setJS>", with: "ABSSJ\(securityToken)", options: .literal)
        
      case .archive:
        // No modifications needed
        break
        
      case .braveSearchHelper:
        let securityToken = UserScriptManager.securityTokenString
        let messageToken = "BSH\(UserScriptManager.messageHandlerTokenString)"
        
        source = source
          .replacingOccurrences(of: "$<brave-search-helper>", with: messageToken, options: .literal)
          .replacingOccurrences(of: "$<security_token>", with: securityToken)
        
      case .braveTalkHelper:
        let securityToken = UserScriptManager.securityTokenString
        let messageToken = "BT\(UserScriptManager.messageHandlerTokenString)"
        
        source = source
          .replacingOccurrences(of: "$<brave-talk-helper>", with: messageToken, options: .literal)
          .replacingOccurrences(of: "$<security_token>", with: securityToken)
      }
    }
    
    let userScript = WKUserScript.create(source: source, injectionTime: domainType.injectionTime, forMainFrameOnly: domainType.forMainFrameOnly, in: domainType.contentWorld)
    cachedDomainScriptsSources[domainType] = userScript
    return userScript
  }
}

/// Class responsible for creating and caching seeds.
///
/// These seeds are used by scripts to randomize output in a situation where output has to be the same for the same ETLD but different for different ETLDs
private class SeedManager {
  /// The shared instance of the SeedManager
  ///
  /// The seed manager is shared because we need the seeds to be persisted across different tabs and while the application is active.
  /// We can easily drop the shared instance as the sessionKey is a static variable. But for now this simplifies things a lot as we don't have a need for instances.
  static let shared = SeedManager()
  
  /// This is used to encode the domain key (i.e. the ETLD+1).
  ///
  /// This key should be the same for the lifecycle of the app. Hence we use a static variable.
  /// Not strictly necessary at this point because the `SeedManager` is a shared instance.
  private static let sessionKey = SymmetricKey(size: .bits256)
  
  /// Cached seeds per etld. Results in less hashing.
  private var seeds: [String: UInt64]
  
  init(seeds: [String: UInt64] = [:]) {
    self.seeds = seeds
  }
  
  /// Clear all the stored seeds
  func clearCache() {
    seeds = [:]
  }
  
  /// Returns a seed for the given etld. Seeds are cached per ETLD so each ETLD returns the same seed
  func getSeed(forETLD etld: String) -> UInt64 {
    // Return an existing seed if we have it
    guard seeds[etld] == nil else {
      return seeds[etld]!
    }
    
    // Sign the etld using our session key
    let signed = Self.signedKey(forETLD: etld).hexString
    
    // We need to represent the signed value as an UInt64.
    let seed = seed(from: signed)
    seeds[etld] = seed
    return seed
  }
  
  /// Hash the string value into a `UInt64` representation to be used as a seed.
  private func seed(from value: String) -> UInt64 {
    // First we hash the string to have an `Int` value
    let hashValue = value.hashValue
    
    // And then we reinterpret cast it into a UInt64
    // This works because Int uses 64 bits so their capacities are the same.
    return withUnsafePointer(to: hashValue) {
      $0.withMemoryRebound(to: UInt64.self, capacity: 1) {
        $0.pointee
      }
    }
  }
  
  /// Signs this given value using a static session key.
  private static func signedKey(forETLD etld: String) -> Data {
    let signature = HMAC<SHA256>.authenticationCode(for: Data(etld.utf8), using: sessionKey)
    return Data(signature)
  }
}

private extension Data {
  var hexString: String {
    map({ String(format: "%02hhx", $0) }).joined()
  }
}
