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
  @State private var showLoading = false
  
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
      ClearDataSectionView(settings: settings, clearingData: $showLoading)
      
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
                self.showLoading = true
                await settings.clearPrivateData([CookiesAndCacheClearable()])
                
                // First remove all tabs so that only a blank tab exists.
                self.tabManager.removeAll()
                
                // Reset tab configurations and delete all webviews..
                self.tabManager.reset()
                
                // Restore all existing tabs by removing the blank tabs and recreating new ones..
                self.tabManager.removeAll()
                self.showLoading = false
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
    .loadingView(message: Strings.clearingData, isShowing: $showLoading)
    .navigationTitle(Strings.braveShieldsAndPrivacy)
  }
}

struct ProgressIndicatorView: UIViewRepresentable {
  private let size: LoaderView.Size
  @Environment(\.font) var font
  @Binding var isAnimating: Bool
  
  init(size: LoaderView.Size) {
    self.size = size
    _isAnimating = .constant(true)
  }
  
  func makeUIView(context: Context) -> BraveUI.LoaderView {
    let loaderView = LoaderView(size: size)
    loaderView.tintColor = .white
    return loaderView
  }
  
  func updateUIView(_ loaderView: BraveUI.LoaderView, context: Context) {
    if isAnimating {
      loaderView.start()
      
    } else {
      loaderView.stop()
    }
  }
}

struct LoadingView: ViewModifier {
  enum Size {
    case small, normal, large
    var loadingViewSize: LoaderView.Size {
      switch self {
      case .large: return .large
      case .normal: return .normal
      case .small: return .small
      }
    }
  }
  
  @Environment(\.colorScheme) private var colorScheme
  let size: Size
  let message: String
  @Binding var isShowing: Bool
  
  private var overlayColor: Color {
    switch colorScheme {
    case .dark: return .black
    case .light: return .white
    @unknown default: return .white
    }
  }
  
  func body(content: Content) -> some View {
    GeometryReader { geometry in
      content
        .disabled(self.isShowing)
        .blur(radius: self.isShowing ? 1 : 0)
        .animation(.default, value: isShowing)
        .overlay {
          overlayColor.opacity(0.25)
            .overlay(alignment: .center) {
              VStack {
                ProgressIndicatorView(size: size.loadingViewSize)
                  .frame(width: size.loadingViewSize.width, height: size.loadingViewSize.height)
                Text(message)
                  .font(.callout)
                  .foregroundColor(.white)
                  .fontWeight(.bold)
              }
                .frame(
                  width: geometry.size.width / 2,
                  height: geometry.size.height / 5
                )
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
            }
            .opacity(self.isShowing ? 1 : 0)
            .animation(.default, value: isShowing)
            .ignoresSafeArea()
        }
    }
  }
}

extension View {
  func loadingView(size: LoadingView.Size = .large, message: String, isShowing: Binding<Bool>) -> some View {
    self.modifier(LoadingView(size: size, message: message, isShowing: isShowing))
  }
}
