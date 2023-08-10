// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveStrings
import Preferences
import BraveUI
import Data

struct PrivateTabsView: View {
  @ObservedObject var privateBrowsingOnly = Preferences.Privacy.privateBrowsingOnly
  var tabManager: TabManager?

  var body: some View {
    Form {
      Section(
        header: Text(Strings.TabsSettings.privateTabsSettingsTitle.uppercased()),
        footer: privateBrowsingOnly.value ? Text("") : Text(Strings.TabsSettings.persistentPrivateBrowsingDescription)) {
        if !privateBrowsingOnly.value {
          OptionToggleView(title: Strings.TabsSettings.persistentPrivateBrowsingTitle,
                           option: Preferences.Privacy.persistentPrivateBrowsing) { newValue in
            Task { @MainActor in
              if newValue {
                tabManager?.saveAllTabs()
              } else {
                if let tabs = tabManager?.allTabs.filter({ $0.isPrivate }) {
                  SessionTab.deleteAll(tabIds: tabs.map({ $0.id }))
                }
                
                if tabManager?.privateBrowsingManager.isPrivateBrowsing == true {
                  tabManager?.willSwitchTabMode(leavingPBM: true)
                }
              }
            }
          }
        }
          OptionToggleView(title: Strings.TabsSettings.privateBrowsingLockTitle,
                         option: Preferences.Privacy.privateBrowsingLock)
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .navigationBarTitle(Strings.TabsSettings.privateTabsSettingsTitle)
    .navigationBarTitleDisplayMode(.inline)
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
  }
}

#if DEBUG
struct PrivateTabsView_Previews: PreviewProvider {
  static var previews: some View {
    PrivateTabsView()
  }
}
#endif
