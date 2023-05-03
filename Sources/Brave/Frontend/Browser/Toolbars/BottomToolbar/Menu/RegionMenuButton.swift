// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import SwiftUI
import BraveUI
import BraveVPN
import GuardianConnect

/// A menu button that provides a shortcut to changing Brave VPN region
struct RegionMenuButton: View {
  /// The region information
  var vpnRegionInfo: GRDRegion?
  /// A closure executed when the region select is clicked
  var regionSelectAction: () -> Void
  
  @State private var isVPNEnabled = BraveVPN.isConnected
  
  var body: some View {
      HStack {
        if isVPNEnabled {
          HStack {
            MenuItemHeaderView(
              icon: vpnRegionInfo?.regionFlag ?? Image(braveSystemName: "leo.globe"),
              title: "VPN Region",
              subtitle: vpnRegionInfo?.settingTitle ?? "Current Setting: Automatic")
            Spacer()
            Image(braveSystemName: "leo.arrow.small-right")
              .foregroundColor(Color(.secondaryBraveLabel))
          }
          .padding(.horizontal, 14)
          .frame(maxWidth: .infinity, minHeight: 48.0, alignment: .leading)
          .background(
            Button(action: {
              regionSelectAction()
            }) {
              Color.clear
            }
              .buttonStyle(TableCellButtonStyle())
          )
          .accessibilityElement()
          .accessibility(addTraits: .isButton)
          .accessibility(label: Text("VPN Region"))
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .NEVPNStatusDidChange)) { _ in
        isVPNEnabled = BraveVPN.isConnected
      }
  }
  
}
