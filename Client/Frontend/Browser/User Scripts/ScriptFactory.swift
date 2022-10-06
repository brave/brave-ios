// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

/// An error representing failures in loading scripts
enum ScriptLoadFailure: Error {
  case notFound
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
  
  /// Create a script for the given domain user script
  private func makeScript(for domainUserScript: DomainUserScript) throws -> WKUserScript {
    switch domainUserScript {
    case .braveSearchHelper:
      guard let script = BraveSearchScriptHandler.userScript else {
        assertionFailure("Cannot load script. This should not happen as it's part of the codebase")
        throw ScriptLoadFailure.notFound
      }
      
      return script
      
    case .braveTalkHelper:
      guard let script = BraveTalkScriptHandler.userScript else {
        assertionFailure("Cannot load script. This should not happen as it's part of the codebase")
        throw ScriptLoadFailure.notFound
      }
      
      return script
      
    case .braveSkus:
      guard let script = BraveSkusScriptHandler.userScript else {
        assertionFailure("Cannot load script. This should not happen as it's part of the codebase")
        throw ScriptLoadFailure.notFound
      }
      
      return script
      
    case .bravePlaylistFolderSharingHelper:
      guard let script = PlaylistFolderSharingScriptHandler.userScript else {
        assertionFailure("Cannot load script. This should not happen as it's part of the codebase")
        throw ScriptLoadFailure.notFound
      }
      
      return script
    }
  }
  
  /// Get a script for the `UserScriptType`.
  ///
  /// Scripts can be cached on two levels:
  /// - On the unmodified source file (per `ScriptSourceType`)
  /// - On the modfied source file (per `UserScriptType`)
  func makeScript(for domainType: UserScriptType) throws -> WKUserScript {
    // First check for and return cached value
    if let script = cachedDomainScriptsSources[domainType] {
      return script
    }
    
    let resultingScript: WKUserScript
    
    switch domainType {
    case .siteStateListener:
      guard let script = SiteStateListenerScriptHandler.userScript else {
        assertionFailure("Cannot load script. This should not happen as it's part of the codebase")
        throw ScriptLoadFailure.notFound
      }
      
      resultingScript = script
      
    case .farblingProtection(let etld):
      var source = try makeScriptSource(of: .farblingProtection)
      let randomConfiguration = RandomConfiguration(etld: etld)
      let fakeParams = try FarblingProtectionHelper.makeFarblingParams(from: randomConfiguration)
      source = source.replacingOccurrences(of: "$<farbling_protection_args>", with: fakeParams)
      resultingScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page)
      
    case .nacl:
      let source = try makeScriptSource(of: .nacl)
      resultingScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false, in: .page)
      
    case .domainUserScript(let domainUserScript):
      resultingScript = try self.makeScript(for: domainUserScript)
      
    case .engineScript(_, let source, _):
      resultingScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: .page)
    }
    
    cachedDomainScriptsSources[domainType] = resultingScript
    return resultingScript
  }
}
