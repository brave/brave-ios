// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AppIntents
import BraveVPN
import WidgetKit
import Preferences

@available(iOS 16.0, *)
struct VPNAppIntent: AppIntent {
  static var title: LocalizedStringResource { "Toggle VPN" }
  static var isDiscoverable: Bool { false }
  
  func perform() async throws -> some IntentResult {
    let vpnProductInfo = VPNProductInfo()
    
    vpnProductInfo.load()
    BraveVPN.initialize(customCredential: nil)
    
    try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 1000)
    
    if !BraveVPN.isConnected {
      await withCheckedContinuation { continuation in
        BraveVPN.reconnect { _ in
          continuation.resume()
        }
      }
    } else {
      BraveVPN.disconnect()
      try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
    }
    return .result()
  }
}
