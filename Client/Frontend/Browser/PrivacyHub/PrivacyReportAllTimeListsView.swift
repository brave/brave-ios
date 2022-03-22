/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import Shared
import BraveShared

private struct FaviconImage: View {
  let url: URL?

  @StateObject private var faviconLoader = PlaylistFolderImageLoader()

  init(url: String?) {
    if let url = url {
      self.url = URL(string: url)
    } else {
      self.url = nil
    }
  }

  var body: some View {
    Image(uiImage: faviconLoader.image ?? .init(imageLiteralResourceName: "defaultFavicon"))
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 30, height: 30)
      .onAppear {
        if let url = url {
          faviconLoader.load(domainUrl: url)
        }
      }
  }
}

struct PrivacyReportAllTimeListsView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.sizeCategory) private var sizeCategory

  let allTimeListTrackers: [PrivacyReportsItem]
  let allTimeListWebsites: [PrivacyReportsItem]

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

  private var trackersList: some View {
    List {
      Section {
        ForEach(allTimeListTrackers) { item in
          HStack {
            VStack(alignment: .leading, spacing: 4) {

              VStack(alignment: .leading, spacing: 0) {
                Text(item.domainOrTracker)
                  .font(.callout)
                  .foregroundColor(Color(.bravePrimary))

                if let url = URL(string: item.domainOrTracker),
                  let humanFriendlyTrackerName =
                    BlockedTrackerParser.parse(url: url, fallbackToDomainURL: false)
                {
                  Text(humanFriendlyTrackerName)
                    .font(.footnote)
                    .foregroundColor(Color(.braveLabel))
                }
              }

              Group {
                if sizeCategory.isAccessibilityCategory {
                  VStack(alignment: .leading, spacing: 4) {
                    Text(Strings.PrivacyHub.blockedBy)
                      .foregroundColor(Color(.secondaryBraveLabel))

                    blockedByLabels(i: item.count)  // FIXME: count not needed here, was for tests.
                  }
                } else {
                  HStack(spacing: 4) {
                    Text(Strings.PrivacyHub.blockedBy)
                      .foregroundColor(Color(.secondaryBraveLabel))

                    if let source = item.source {
                      Group {
                        switch source {
                        case .shields:
                          PrivacyReportsView.BlockedByShieldsLabel()
                        case .vpn:
                          PrivacyReportsView.BlockedByVPNLabel()
                        case .both:
                          PrivacyReportsView.BlockedByShieldsLabel()
                          PrivacyReportsView.BlockedByVPNLabel()
                        }
                      }
                    }
                  }
                }
              }
              .font(.caption)
            }

            Spacer()
            Text("\(item.count)")
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
  }

  private var websitesList: some View {
    List {
      Section {
        ForEach(allTimeListWebsites) { item in
          HStack {
            FaviconImage(url: item.faviconUrl)
            Text(item.domainOrTracker)
            Spacer()
            Text("\(item.count)")
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
        trackersList
      case .websites:
        websitesList
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
