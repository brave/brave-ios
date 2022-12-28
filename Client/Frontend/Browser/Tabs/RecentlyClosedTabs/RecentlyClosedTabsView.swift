// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveShared
import Data
import CoreData
import BraveUI

struct RecentlyClosedTabsView: View {
  @Environment(\.presentationMode) @Binding private var presentationMode

  @State private var recentlyClosedTabs: [Tab] = []
  @State private var recentlyClosedLoading = true
  
  @State private var showClearDataPrompt: Bool = false
  private(set) var onDismiss: (() -> Void)?

  private let tabManager: TabManager

  private var clearAllDataButton: some View {
    Button("Clear", action: {
      showClearDataPrompt = true
    })
    .accessibility(label: Text("Clear All Recently Closed Tabs"))
    .foregroundColor(Color(.braveBlurpleTint))
    .actionSheet(isPresented: $showClearDataPrompt) {
      .init(title: Text("Clear All Recently Closed Tabs?"),
            buttons: [
              .destructive(Text("Clear Recently Closed Tabs"), action: {
                // TODO: ADD CLEAR CODE
                dismissView()
              }),
              .cancel()
            ])
    }
  }
  
  private var doneButton: some View {
    Button(Strings.done, action: dismissView)
      .foregroundColor(Color(.braveBlurpleTint))
  }
  
  private var websitesList: some View {
    List {
      Section {
        ForEach(recentlyClosedTabs, id: \.id) { tab in
          HStack {
            FaviconImage(url: tab.displayFavicon?.url)
            VStack(alignment: .leading) {
              Text(tab.displayTitle)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(Color(.bravePrimary))
              Text(fetchURL(for: tab) ?? "")
                .font(.caption)
                .foregroundColor(Color(.braveLabel))
            }
            Spacer()
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
          .accessibilityElement()
          .accessibilityLabel("\(tab.displayTitle)")
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .environment(\.defaultMinListHeaderHeight, 0)
    .listStyle(.insetGrouped)
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
  }
  
  init(tabManager: TabManager) {
      self.tabManager = tabManager
  }
  
  var body: some View {
    NavigationView {
        VStack(spacing: 0) {
          if recentlyClosedLoading {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          } else {
            websitesList
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.braveGroupedBackground).ignoresSafeArea())
        .navigationTitle("Recently Closed Tabs")
        .navigationBarTitleDisplayMode(.inline)
        .osAvailabilityModifiers { content in
          if #available(iOS 15.0, *) {
            content
              .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                  doneButton
                }
                ToolbarItem(placement: .cancellationAction) {
                  clearAllDataButton
                }
              }
          } else {
            content
              .navigationBarItems(leading: clearAllDataButton, trailing: doneButton)
          }
        }
    }
    .navigationViewStyle(.stack)
    .environment(\.managedObjectContext, DataController.swiftUIContext)
    .onAppear {
    
      recentlyClosedTabs = tabManager.recentlyClosedTabs()

      recentlyClosedLoading = false
    }
  }
  
  private func dismissView() {
    // Dismiss on presentation mode does not work on iOS 14
    // when using the UIHostingController is parent view.
    // As a workaround a completion handler is used instead.
    if #available(iOS 15, *) {
      presentationMode.dismiss()
    } else {
      onDismiss?()
    }
  }
  
  private func fetchURL(for tab: Tab) -> String? {
    if let tabID = tab.id {
      let fetchedTab = TabMO.get(fromId: tabID)

      if let urlString = fetchedTab?.url, let url = URL(string: urlString), url.isWebPage(), !(InternalURL(url)?.isAboutHomeURL ?? false) {
          return urlString
      }
    }
    
    return nil
  }
}
