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
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.sizeCategory) private var sizeCategory
  
  @State private var websites: [RecentSearch] = []
//  @State private var websites: [PrivacyReportsWebsite] = []
  @State private var websitesLoading = true
  
  @State private var showClearDataPrompt: Bool = false
  
  private let recentSearchesFRC = RecentSearch.frc()

  private var clearAllDataButton: some View {
    Button("Clear", action: {
      showClearDataPrompt = true
    })
    .accessibility(label: Text(Strings.PrivacyHub.clearAllDataAccessibility))
    .foregroundColor(Color(.braveBlurpleTint))
    .actionSheet(isPresented: $showClearDataPrompt) {
      .init(title: Text(Strings.PrivacyHub.clearAllDataPrompt),
            buttons: [
              .destructive(Text(Strings.yes), action: {
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
//      Section {
//        ForEach(websites) { item in
//          HStack {
//            FaviconImage(url: item.faviconUrl)
//            Text(item.domain)
//            Spacer()
//          }
//        }
//      }
      Section {
        ForEach(websites) { item in
          HStack {
            FaviconImage(url: item.websiteUrl)
            Text(item.text ?? "")
            Spacer()
          }
        }
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
    .environment(\.defaultMinListHeaderHeight, 0)
    .listStyle(.insetGrouped)
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
  }
  
  var body: some View {
    NavigationView {
        VStack(spacing: 0) {
          if websitesLoading {
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
      
      do {
        try recentSearchesFRC.performFetch()
      } catch {
        print("Recent Searches fetch error: \(error.localizedDescription))")
      }

      websites = recentSearchesFRC.fetchedObjects ?? []

      
//      BlockedResource.allTimeMostRiskyWebsites { riskyWebsites in
//        websites = riskyWebsites.map {
//          PrivacyReportsWebsite(domain: $0.domain, faviconUrl: $0.faviconUrl, count: $0.count)
//        }
//
//        websitesLoading = false
//      }
    }
  }
  
  private func dismissView() {
    // TODO: Custom Dismissal
  }
}

#if DEBUG
struct RecentlyClosedTabsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      RecentlyClosedTabsView()
      RecentlyClosedTabsView()
        .preferredColorScheme(.dark)
    }
  }
}
#endif
