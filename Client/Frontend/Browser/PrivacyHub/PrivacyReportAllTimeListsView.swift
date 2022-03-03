/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import Shared
import BraveShared

struct PrivacyReportAllTimeListsView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.sizeCategory) private var sizeCategory
  
  private(set) var onDismiss: () -> Void
  
  enum Page: CaseIterable, Identifiable {
    case trackersAndAds, websites
    
    var id: String {
      displayString
    }
    
    var displayString: String {
      switch self {
      case .trackersAndAds: return Strings.PrivacyHub.allTimeListsTrackersView
      case .websites: return Strings.PrivacyHub.allTimeListsWebsitesView
      }
    }
  }
  
  @State private var currentPage: Page = .trackersAndAds
  
  func blockedByLabels(i: Int) -> some View {
    Group {
      if horizontalSizeClass == .compact {
        VStack(alignment: .leading) {
          PrivacyReportsView.BlockedByShieldsLabel()
          if i % 2 == 0 {
            PrivacyReportsView.BlockedByVPNLabel()
          }
        }
      } else {
        HStack {
          PrivacyReportsView.BlockedByShieldsLabel()
          if i % 2 == 0 {
            PrivacyReportsView.BlockedByVPNLabel()
          }
        }
      }
    }
  }
  
  private var selectionPicker: some View {
    Picker("", selection: $currentPage) {
      ForEach(Page.allCases) {
        Text($0.displayString)
          .tag($0)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }
  
  var body: some View {
    VStack(spacing: 0) {
      if #available(iOS 15.0, *) {
        selectionPicker
          .accessibilityShowsLargeContentViewer()
      } else {
        selectionPicker
      }
      
      switch currentPage {
      case .trackersAndAds:
        List {
          Section {
            ForEach(0..<20) { i in
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("\(i)-analytics.com")
                    .font(.callout)
                  
                  Group {
                    if sizeCategory.isAccessibilityCategory {
                      VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.PrivacyHub.blockedBy)
                          .foregroundColor(Color(.secondaryBraveLabel))
                        
                        blockedByLabels(i: i)
                      }
                    } else {
                      HStack(spacing: 4) {
                        Text(Strings.PrivacyHub.blockedBy)
                          .foregroundColor(Color(.secondaryBraveLabel))
                        PrivacyReportsView.BlockedByShieldsLabel()
                        if i % 2 == 0 {
                          PrivacyReportsView.BlockedByVPNLabel()
                        }
                      }
                    }
                  }
                  .font(.caption)
                }
                
                Spacer()
                Text("\(i * 17)")
                  .font(.headline.weight(.semibold))
              }
            }
          } header: {
            Text(Strings.PrivacyHub.allTimeListTrackersHeaderTitle)
              .listRowInsets(.init())
              .padding(.vertical, 8)
              .font(.footnote)
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        .listStyle(.insetGrouped)
        
      case .websites:
        List {
          Section {
            ForEach(0..<20) { i in
              HStack {
                Label("\(i).com", systemImage: "globe")
                Spacer()
                Text("\(i * 17)")
                  .font(.headline.weight(.semibold))
              }
            }
          } header: {
            Text(Strings.PrivacyHub.allTimeListWebsitesHeaderTitle)
              .font(.footnote)
              .listRowInsets(.init())
              .padding(.vertical, 8)
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        .listStyle(.insetGrouped)
      }
    }
    .background(Color(.braveGroupedBackground).ignoresSafeArea())
    .ignoresSafeArea(.container, edges: .bottom)
    .navigationTitle(Strings.PrivacyHub.allTimeListsButtonText)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
          Button(Strings.done) {
            onDismiss()
          }
          .foregroundColor(Color(.braveOrange))
      }
    }
  }
}

#if DEBUG
struct PrivacyReportAllTimeListsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      PrivacyReportAllTimeListsView()
      PrivacyReportAllTimeListsView()
        .preferredColorScheme(.dark)
    }
  }
}
#endif
