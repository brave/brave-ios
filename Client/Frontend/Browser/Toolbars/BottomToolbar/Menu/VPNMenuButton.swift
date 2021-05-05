// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
#if canImport(SwiftUI)
import SwiftUI
#endif

struct VPNMenuButton: View {
    var icon: UIImage
    var title: String
    var vpnProductInfo: VPNProductInfo
    var displayVPNDestination: (UIViewController) -> Void
    
    @State private var isVPNStatusChanging: Bool = BraveVPN.reconnectPending
    @State private var isErrorShowing: Bool = false
    
    private var isVPNEnabled: Binding<Bool> {
        Binding(
            get: { BraveVPN.isConnected },
            set: { toggleVPN($0) }
        )
    }
    
    private func toggleVPN(_ enabled: Bool) {
        let vpnState = BraveVPN.vpnState
        
        if !VPNProductInfo.isComplete {
            isErrorShowing = true
            // Reattempt to connect to the App Store to get VPN prices.
            vpnProductInfo.load()
            return
        }
        isVPNStatusChanging = true
        switch BraveVPN.vpnState {
        case .notPurchased, .purchased, .expired:
            guard let vc = vpnState.enableVPNDestinationVC else { return }
            displayVPNDestination(vc)
        case .installed:
            // Do not modify UISwitch state here, update it based on vpn status observer.
            enabled ? BraveVPN.reconnect() : BraveVPN.disconnect()
        }
    }
    
    var body: some View {
        Button(action: { toggleVPN(!BraveVPN.isConnected) }) {
            HStack {
                MenuItemHeaderView(icon: icon, title: title)
                Spacer()
                if isVPNStatusChanging {
                    Text("Loading")
                }
                Toggle("", isOn: isVPNEnabled)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 48.0, alignment: .leading)
        }
        .buttonStyle(TableButtonStyle())
        .alert(isPresented: $isErrorShowing) {
            Alert(
                title: Text(verbatim: Strings.VPN.errorCantGetPricesTitle),
                message: Text(verbatim: Strings.VPN.errorCantGetPricesBody),
                dismissButton: .default(Text(verbatim: Strings.OKString))
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .NEVPNStatusDidChange)) { _ in
            isVPNStatusChanging = false
        }
    }
}
