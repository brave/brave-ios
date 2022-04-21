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
    @Environment(\.pixelLength) private var pixelLength
    
    @State private var mostFrequentTracker: CountableEntity?
    @State private var riskiestWebsite: CountableEntity?
    
    private(set) var onDismiss: () -> Void
    
    private func allTimeItemView(trackerOrWebsite: CountableEntity?, countableLabel: String) -> some View {
      VStack {
        Text(Strings.PrivacyHub.allTimeTrackerTitle.uppercased())
          .font(.caption)
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundColor(Color(.secondaryBraveLabel))
        
        if let entity = trackerOrWebsite {
          VStack(alignment: .leading) {
            Text(entity.name)
              .font(.subheadline)
            Text(String.localizedStringWithFormat(countableLabel, entity.count))
              .font(.footnote)
              .foregroundColor(Color(.secondaryBraveLabel))
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        } else {
          Text(Strings.PrivacyHub.noDataToShow)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .font(.subheadline)
            .foregroundColor(Color(.secondaryBraveLabel))
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal)
      .padding(.vertical, 8)
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
            allTimeItemView(trackerOrWebsite: mostFrequentTracker, countableLabel: Strings.PrivacyHub.allTimeSitesCount)
            allTimeItemView(trackerOrWebsite: riskiestWebsite, countableLabel: Strings.PrivacyHub.allTimeTrackersCount)
          }
        } else {
          HStack(spacing: 12) {
            allTimeItemView(trackerOrWebsite: mostFrequentTracker, countableLabel: Strings.PrivacyHub.allTimeSitesCount)
            allTimeItemView(trackerOrWebsite: riskiestWebsite, countableLabel: Strings.PrivacyHub.allTimeTrackersCount)
          }
        }
        
        NavigationLink(
          destination: PrivacyReportAllTimeListsView(onDismiss: onDismiss)
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
            .stroke(Color(.braveLabel), lineWidth: pixelLength)
        )
      }
      .fixedSize(horizontal: false, vertical: true)
      .onAppear {
        BlockedResource.mostBlockedTracker(inLastDays: nil) { result in
          mostFrequentTracker = result
        }
        
        BlockedResource.riskiestWebsite(inLastDays: nil) { result in
          riskiestWebsite = result
        }
      }
    }
  }
}

#if DEBUG
struct PrivacyHubAllTimeSection_Previews: PreviewProvider {
  static var previews: some View {
    PrivacyReportsView.PrivacyHubAllTimeSection(onDismiss: {})
  }
}
#endif
