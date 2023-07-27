// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WidgetKit
import SwiftUI
import BraveVPN

struct ToggleVPNWidget: Widget {
  var body: some WidgetConfiguration {
#if swift(>=5.9)
    if #available(iOS 17.0, *) {
      return StaticConfiguration(kind: "ToggleVPNWidget", provider: ToggleVPNWidgetProvider()) { entry in
        ToggleVPNView(entry: entry)
      }
      .supportedFamilies([.systemSmall])
    } else {
      return EmptyWidgetConfiguration()
    }
#else
    EmptyWidgetConfiguration()
#endif
  }
}

#if swift(>=5.9)
@available(iOS 17.0, *)
struct ToggleVPNEntry: TimelineEntry {
  var date: Date = .now
  var state: BraveVPN.State
}

@available(iOS 17.0, *)
struct ToggleVPNWidgetProvider: TimelineProvider {
  typealias Entry = ToggleVPNEntry
  
  func initializeVPN() {
    if !BraveVPN.isInitialized {
      // Fetching details of GRDRegion for Automatic Region selection
      BraveVPN.fetchLastUsedRegionDetail()
      BraveVPN.initialize(customCredential: nil)
    }
  }
  
  func getSnapshot(in context: Context, completion: @escaping (ToggleVPNEntry) -> Void) {
    initializeVPN()
    completion(.init(state: BraveVPN.vpnState))
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<ToggleVPNEntry>) -> Void) {
    initializeVPN()
    completion(.init(entries: [.init(state: BraveVPN.vpnState)], policy: .after(.now.addingTimeInterval(60*60*15))))
  }
  
  func placeholder(in context: Context) -> ToggleVPNEntry {
    .init(date: .now, state: .notPurchased)
  }
}

@available(iOS 17.0, *)
struct ToggleVPNView: View {
  var entry: ToggleVPNEntry
  
  var body: some View {
    VStack {
      switch entry.state {
      case .notPurchased:
        Text("Purchase VPN")
          .widgetURL(URL(string: "brave://buy-vpn"))
      case .purchased(let enabled):
        Text("VPN: \(enabled ? "ON" : "OFF")")
        Toggle(!enabled ? "Connect" : "Disconnect", isOn: enabled, intent: VPNAppIntent())
      case .expired:
        Text("Expired")
          .widgetURL(URL(string: "brave://buy-vpn"))
      }
    }
    .containerBackground(Color.white, for: .widget)
  }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
  ToggleVPNWidget()
} timeline: {
  ToggleVPNEntry(state: .notPurchased)
  ToggleVPNEntry(state: .expired)
  ToggleVPNEntry(state: .purchased(enabled: false))
  ToggleVPNEntry(state: .purchased(enabled: true))
}
#endif
