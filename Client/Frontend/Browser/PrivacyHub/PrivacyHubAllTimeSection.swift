// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveShared
import Data

extension PrivacyReportsView {
  struct PrivacyHubAllTimeSection: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let allTimeMostFrequentTracker: CountableEntity?
    let allTimeRiskiestWebsite: CountableEntity?
    
    let allTimeListTrackers: [PrivacyReportsItem]
    let allTimeListWebsites: [PrivacyReportsItem]
    
    private(set) var onDismiss: () -> Void
    
    private var allTimeTrackerView: some View {
      VStack {
        Text(Strings.PrivacyHub.allTimeTrackerTitle.uppercased())
          .font(.caption)
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundColor(Color(.secondaryBraveLabel))
        
        if let allTimeMostFrequentTracker = allTimeMostFrequentTracker {
          VStack(alignment: .leading) {
            Text(allTimeMostFrequentTracker.name)
            
            Text(String.localizedStringWithFormat(Strings.PrivacyHub.allTimeSitesCount,
                                                  allTimeMostFrequentTracker.count))
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .font(.subheadline)
          
        } else {
          Text(Strings.PrivacyHub.noDataToShow)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.subheadline)
            .foregroundColor(Color(.secondaryBraveLabel))
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color(.braveBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var allTimeWebsiteView: some View {
      VStack {
        Text(Strings.PrivacyHub.allTimeWebsiteTitle.uppercased())
          .font(.caption)
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundColor(Color(.secondaryBraveLabel))
        
        if let allTimeRiskiestWebsite = allTimeRiskiestWebsite {
          VStack(alignment: .leading) {
            Text(allTimeRiskiestWebsite.name)
            Text(String.localizedStringWithFormat(Strings.PrivacyHub.allTimeTrackersCount,
                                                  allTimeRiskiestWebsite.count))
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .font(.subheadline)
          
        } else {
          Text(Strings.PrivacyHub.noDataToShow)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.subheadline)
            .foregroundColor(Color(.secondaryBraveLabel))
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color(.braveBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text(Strings.PrivacyHub.allTimeListsHeader.uppercased())
          .font(.footnote.weight(.medium))
          .fixedSize(horizontal: false, vertical: true)
        
        if sizeCategory.isAccessibilityCategory && horizontalSizeClass == .compact {
          VStack {
            allTimeTrackerView
            allTimeWebsiteView
          }
        } else {
          HStack(spacing: 12) {
            allTimeTrackerView
            allTimeWebsiteView
          }
        }
        
        NavigationLink(
          destination: PrivacyReportAllTimeListsView(
            allTimeListTrackers: allTimeListTrackers,
            allTimeListWebsites: allTimeListWebsites,
            onDismiss: onDismiss)
        ) {
          HStack {
            Text(Strings.PrivacyHub.allTimeListsButtonText)
            Image(systemName: "arrow.right")
          }
          .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .foregroundColor(Color(.braveLabel))
        .overlay(
          RoundedRectangle(cornerRadius: 25)
            .stroke(Color(.braveLabel), lineWidth: 1)
        )
      }
      .fixedSize(horizontal: false, vertical: true)
    }
  }
}

#if DEBUG
struct PrivacyHubAllTimeSection_Previews: PreviewProvider {
  static var previews: some View {
    PrivacyHubAllTimeSection()
  }
}
#endif
