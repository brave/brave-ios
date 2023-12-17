// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import SwiftUI
import BraveUI
import Preferences

/// A menu button that provides a shortcut to toggling Night Mode
struct NightModeMenuButton: View {
  @ObservedObject private var nightMode = Preferences.General.nightModeEnabled

  var body: some View {
    HStack {
      MenuItemHeaderView(
        icon: Image(braveSystemName: "leo.theme.dark"),
        title: Strings.NightMode.settingsTitle)
      Spacer()
      Toggle("", isOn: $nightMode.value)
        .labelsHidden()
        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
    }
    .padding(.horizontal, 14)
    .frame(maxWidth: .infinity, minHeight: 48.0)
    .background(
      Button(action: {
        Preferences.General.nightModeEnabled.value.toggle()
      }) {
        Color.clear
      }
      .buttonStyle(TableCellButtonStyle())
    )
    .accessibilityElement()
    .accessibility(addTraits: .isButton)
    .accessibility(label: Text(Strings.NightMode.settingsTitle))
  }
}
