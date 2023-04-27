// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import BraveNews
import BraveCore
import Strings
import Preferences

struct AdvancedShieldsSettingsView: View {
  @ObservedObject private var settings: AdvancedShieldsSettings
  
  private let tabManager: TabManager
  
  @State private var showManageWebsiteData = false
  @State private var showPrivateBrowsingConfirmation = false
  
  init(profile: Profile, tabManager: TabManager, feedDataSource: FeedDataSource, historyAPI: BraveHistoryAPI, p3aUtilities: BraveP3AUtils) {
    self.settings = AdvancedShieldsSettings(
      profile: profile,
      tabManager: tabManager,
      feedDataSource: feedDataSource,
      historyAPI: historyAPI,
      p3aUtilities: p3aUtilities
    )
    self.tabManager = tabManager
  }

  var body: some View {
    List {
      DefaultShieldsViewView(settings: settings)
      ClearDataSectionView(settings: settings)
      
      Section {
        Button {
          showManageWebsiteData = true
        } label: {
          // Hack to show the disclosure
          NavigationLink(destination: { EmptyView() }, label: {
            ShieldLabelView(
              title: Strings.manageWebsiteDataTitle,
              subtitle: nil
            )
          })
        }
          .buttonStyle(.plain)
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
          .sheet(isPresented: $showManageWebsiteData) {
            ManageWebsiteDataView()
          }
        
        NavigationLink {
          PrivacyReportSettingsView()
        } label: {
          ShieldLabelView(
            title: Strings.PrivacyHub.privacyReportsTitle,
            subtitle: nil
          )
        }.listRowBackground(Color(.secondaryBraveGroupedBackground))
      }
      
      Section {
        OptionToggleView(
          title: Strings.privateBrowsingOnly,
          subtitle: nil,
          option: Preferences.Privacy.privateBrowsingOnly,
          onChange: { newValue in
            if newValue {
              showPrivateBrowsingConfirmation = true
            }
          }
        )
        .alert(isPresented: $showPrivateBrowsingConfirmation, content: {
          Alert(
            title: Text(Strings.privateBrowsingOnly),
            message: Text(Strings.privateBrowsingOnlyWarning),
            primaryButton: .default(Text(Strings.OKString), action: {
              Task { @MainActor in
                try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 100)
                await settings.clearPrivateData([CookiesAndCacheClearable()])
                
                // First remove all tabs so that only a blank tab exists.
                self.tabManager.removeAll()
                
                // Reset tab configurations and delete all webviews..
                self.tabManager.reset()
                
                // Restore all existing tabs by removing the blank tabs and recreating new ones..
                self.tabManager.removeAll()
              }
            }),
            secondaryButton: .cancel(Text(Strings.cancelButtonTitle), action: {
              Preferences.Privacy.privateBrowsingOnly.value = false
            })
          )
        })
        
        ShieldToggleView(
          title: Strings.blockMobileAnnoyances,
          subtitle: nil,
          toggle: $settings.blockMobileAnnoyances
        )
        OptionToggleView(
          title: Strings.followUniversalLinks,
          subtitle: nil,
          option: Preferences.General.followUniversalLinks
        )
        OptionToggleView(
          title: Strings.googleSafeBrowsing,
          subtitle: Strings.googleSafeBrowsingUsingWebKitDescription,
          option: Preferences.Shields.googleSafeBrowsing
        )
        ShieldToggleView(
          title: Strings.P3A.settingTitle,
          subtitle: Strings.P3A.settingSubtitle,
          toggle: $settings.isP3AEnabled
        )
      } header: {
        Text(Strings.otherPrivacySettingsSection)
      }
    }
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .listStyle(.insetGrouped)
    .navigationTitle(Strings.braveShieldsAndPrivacy)
  }
}
