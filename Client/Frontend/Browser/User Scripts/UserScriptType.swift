// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

/// An enum representing a specific (modified) variation of a local script replacing any dynamic variables.
enum UserScriptType: Hashable {
  /// This type does farbling protection and is customized for the provided eTLD+1
  /// Has a dependency on `nacl`
  case farblingProtection(etld: String)
  /// Scripts specific to certain domains
  case domainUserScript(DomainUserScript)
  /// A symple encryption library to be used by other scripts
  case nacl
  /// A script that detects if we're at an amp page and redirects the user to the original (canonical) version if available.
  ///
  /// - Note: This script is only a smaller part (2 of 3) of de-amping.
  /// The first part is handled by an ad-block rule and enabled via a `deAmpEnabled` boolean in `AdBlockStats`
  /// The third part is handled by debouncing amp links and handled by debouncing logic
  case deAMP

  /// Return a source typ for this script type
  var sourceType: ScriptSourceType {
    switch self {
    case .farblingProtection:
      return .farblingProtection
    case .deAMP:
      return .deAMP
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
    case .deAMP: return 1
    case .farblingProtection: return 2
    case .domainUserScript: return 3
    }
  }

  var injectionTime: WKUserScriptInjectionTime {
    switch self {
    case .farblingProtection, .domainUserScript, .nacl, .deAMP:
      return .atDocumentStart
    }
  }

  var forMainFrameOnly: Bool {
    switch self {
    case .farblingProtection, .domainUserScript, .nacl:
      return false
    case .deAMP:
      return true
    }
  }

  var contentWorld: WKContentWorld {
    switch self {
    case .farblingProtection, .domainUserScript, .nacl:
      return .page
    case .deAMP:
      return .defaultClient
    }
  }
}
