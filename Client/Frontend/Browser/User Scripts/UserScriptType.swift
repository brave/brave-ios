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
  /// A set of engine scripts for all subframes
  case engineSubframeScript(url: URL, source: String)
  /// An engine script on the main frame
  case engineScript(url: URL, source: String, order: Int)

  /// The order in which we want to inject the scripts
  var order: Int {
    switch self {
    case .siteStateListener: return 0
    case .nacl: return 1
    case .farblingProtection: return 2
    case .domainUserScript: return 3
    case .engineSubframeScript: return 4
    case .engineScript(_, _, let order): return 5 + order
    }
  }
}
