/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct PrivacyReportAllTimeListsView: View {
  
  enum Page: String, CaseIterable, Identifiable {
    case trackersAndAds = "Trackers & Ads"
    case websites = "Websites"
    
    var id: String {
      rawValue
    }
  }
  @State private var currentPage: Page = .trackersAndAds
  
  var body: some View {
    VStack(spacing: 0) {
      Picker("", selection: $currentPage) {
        ForEach(Page.allCases) {
          Text($0.rawValue)
            .tag($0)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background(Color(.braveGroupedBackground))
      TabView(selection: $currentPage) {
        List {
          Section {
            ForEach(0..<20) { i in
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("\(i)-analytics.com")
                    .font(.callout)
                  HStack(spacing: 4) {
                    Text("Blocked by")
                      .foregroundColor(Color(.secondaryBraveLabel))
                    PrivacyReportsView.BlockedByShieldsLabel()
                    if i % 2 == 0 {
                      PrivacyReportsView.BlockedByVPNLabel()
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
            Text("Most frequent trackers & ads on sites you Visit")
              .listRowInsets(.init())
              .padding(.vertical, 8)
              .padding(.horizontal)
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        .tag(Page.trackersAndAds)
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
            Text("Websites with the most trackers & ads")
              .font(.callout)
              .listRowInsets(.init())
              .padding(.vertical, 8)
              .padding(.horizontal)
          }
          .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
        .tag(Page.websites)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .background(Color(.braveGroupedBackground))
      .ignoresSafeArea(.container, edges: .bottom)
      .animation(.default, value: currentPage)
      .environment(\.defaultMinListHeaderHeight, 0)
      .navigationTitle("Privacy report")
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
