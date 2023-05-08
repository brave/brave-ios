// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

/// An enum representing a specific (modified) variation of a local script replacing any dynamic variables.
enum UserScriptType: Hashable {
  /// An object used to setup the selectors poller script
  struct SelectorsPollerSetup: Hashable, Encodable {
    struct StyleSelectorEntry: Hashable, Encodable {
      let selector: String
      var rules: Set<String>
    }
    
    /// The url of the frame this script belongs to
    ///
    /// We need this to control which script gets executed on which frame
    /// on the JS side since we cannot control this on the iOS side
    let frameURL: URL
    /// Determines if we hide first party content or not. This is controlled via agressive or standard mode
    /// Standard mode may unhide 1p content for certain filter lists.
    let hideFirstPartyContent: Bool
    /// This value come from the engine. In most cases this is false.
    let genericHide: Bool
    /// The delay on which to start polling on.
    let firstSelectorsPollingDelayMs: Int?
    /// After a while of using the mutation observer we switch to selectors polling.
    /// This is purely an optimizaiton
    let switchToSelectorsPollingThreshold: Int?
    /// We can add a delay when sending new classes and ids
    let fetchNewClassIdRulesThrottlingMs: Int?
    /// These are agressive hide selectors that will get automatically processed when the script loads.
    /// Agressive selectors may never be unhidden even on standard mode
    let agressiveSelectors: Set<String>
    /// These are standard hide selectors that will get automatically processed when the script loads.
    /// Standard selectors may be unhidden on standard mode if they contain 1p content
    let standardSelectors: Set<String>
    /// These are hide selectors that will get automatically processed when the script loads.
    let styleSelectors: Set<StyleSelectorEntry>
  }
  
  struct EngineScriptConfiguration: Hashable {
    /// on the JS side since we cannot control this on the iOS side
    let frameURL: URL
    /// Tells us if this script is for the main frame. then we can decide if we inject it to all frames or just the main frame
    let isMainFrame: Bool
    /// The script source
    let source: String
    /// The order in which the script is injected relative to other engine scripts
    let order: Int
    /// We need to pass this setting over to the javascript code
    let isDeAMPEnabled: Bool
  }
  
  /// A script that informs iOS of site state changes
  case siteStateListener
  /// A symple encryption library to be used by other scripts
  case nacl
  /// This type does farbling protection and is customized for the provided eTLD+1
  /// Has a dependency on `nacl`
  case farblingProtection(etld: String)
  /// Scripts specific to certain domains
  case domainUserScript(DomainUserScript)
  /// An engine script on the main frame
  case engineScript(EngineScriptConfiguration)

  /// The order in which we want to inject the scripts
  var order: Int {
    switch self {
    case .nacl: return 0
    case .farblingProtection: return 1
    case .domainUserScript: return 2
    case .siteStateListener: return 3
    case .engineScript(let configuration): return 4 + configuration.order
    }
  }
}
