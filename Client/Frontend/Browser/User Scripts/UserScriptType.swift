// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

/// An enum representing a specific (modified) variation of a local script replacing any dynamic variables.
enum UserScriptType: Hashable {
  /// A script that informs iOS of site state changes
  case siteStateListener
  /// A symple encryption library to be used by other scripts
  case nacl
  /// This type does farbling protection and is customized for the provided eTLD+1
  /// Has a dependency on `nacl`
  case farblingProtection(etld: String)
  /// Scripts specific to certain domains
  case domainUserScript(DomainUserScript)

  /// Return a source typ for this script type
  var sourceType: ScriptSourceType {
    switch self {
    case .siteStateListener:
      return .siteStateListener
    case .farblingProtection:
      return .farblingProtection
    case .domainUserScript(let domainUserScript):
      switch domainUserScript {
      case .braveSearchHelper:
        return .braveSearchHelper
      case .braveTalkHelper:
        return .braveTalkHelper
      case .bravePlaylistFolderSharingHelper:
        return .bravePlaylistFolderSharingHelper
      case .braveSkus:
        return .braveSkus
      case .youtubeAdblock:
        return .youtubeAdblock
      }
    case .nacl:
      return .nacl
    }
  }

  /// The order in which we want to inject the scripts
  var order: Int {
    switch self {
    case .siteStateListener: return 0
    case .nacl: return 1
    case .farblingProtection: return 2
    case .domainUserScript: return 3
    }
  }

  var injectionTime: WKUserScriptInjectionTime {
    switch self {
    case .siteStateListener, .farblingProtection, .domainUserScript, .nacl:
      return .atDocumentStart
    }
  }

  var forMainFrameOnly: Bool {
    switch self {
    case .siteStateListener, .farblingProtection, .domainUserScript, .nacl:
      return false
    }
  }

  var contentWorld: WKContentWorld {
    switch self {
    case .siteStateListener:
      return .defaultClient
    case .farblingProtection, .domainUserScript, .nacl:
      return .page
    }
  }
}
