// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import SwiftUI
import BraveUI
import BraveShared

/// A menu button that provides a shortcut to toggling Night Mode
struct NightModeMenuButton: View {
    @StateObject var nightModePreferences = Preferences.General.nightModeEnabled
    @State private var isNightModeEnabled: Bool = Preferences.General.nightModeEnabled.value
    
    var changeNightModePreference: (Bool) -> Void
    
    private var isNightModeEnabledBinding: Binding<Bool> {
        Binding(
            get: { isNightModeEnabled },
            set: { toggleNightMode($0) }
        )
    }
    
    private func toggleNightMode(_ enabled: Bool) {
        changeNightModePreference(enabled)
    }
    
    private var actionToggle: some View {
        Group {
            let toggle = Toggle("Action Toggle", isOn: isNightModeEnabledBinding)
            toggle
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
    }
    
    var body: some View {
        HStack {
            MenuItemHeaderView(
                icon: UIImage(systemName: "moon")?.template ?? UIImage(),
                title: Strings.NightMode.settingsTitle,
                subtitle: Strings.NightMode.settingsDescription)
            Spacer()
            actionToggle
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 48.0, alignment: .leading)
        .background(
            Button(action: { toggleNightMode(!Preferences.General.nightModeEnabled) }) {
                Color.clear
            }
            .buttonStyle(TableCellButtonStyle())
        )
        .accessibilityElement()
        .accessibility(addTraits: .isButton)
        .accessibility(label: Text("Night Mode"))
        .onChange(of: nightModePreferences.value) { enabled in
            isNightModeEnabled = enabled
        }
    }
}
