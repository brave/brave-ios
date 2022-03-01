// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveShared

extension PrivacyReportsView {
  struct PrivacyHubLastWeekSection: View {
    let lastWeekMostFrequentTracker: (String, Int)?
    let lastWeekRiskiestWebsite: (String, Int)?
    
    var body: some View {
      Group {
        VStack(alignment: .leading, spacing: 8) {
          Text(Strings.PrivacyHub.lastWeekHeader.uppercased())
            .font(.footnote.weight(.medium))
          
          HStack {
            Image("frequent_tracker")
            VStack(alignment: .leading) {
              Text(Strings.PrivacyHub.mostFrequentTrackerAndAdTitle.uppercased())
                .font(.caption)
                .foregroundColor(.init(.secondaryBraveLabel))
              if let lastWeekMostFrequentTracker = lastWeekMostFrequentTracker {
                // FIXME: Add bold for string args.
                Text(String(format: Strings.PrivacyHub.mostFrequentTrackerAndAdBody,
                            lastWeekMostFrequentTracker.0, lastWeekMostFrequentTracker.1))
                  .font(.callout)
              } else {
                Text(Strings.PrivacyHub.noDataToShow)
                  .foregroundColor(.init(.secondaryBraveLabel))
              }
            }
            Spacer()
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color(.braveBackground))
          .cornerRadius(15)
          
          HStack {
            Image("creepy_website")
            VStack(alignment: .leading) {
              
              Text(Strings.PrivacyHub.riskiestWebsiteTitle.uppercased())
                .font(.caption)
                .foregroundColor(Color(.secondaryBraveLabel))
              
              if let lastWeekRiskiestWebsite = lastWeekRiskiestWebsite {
                // FIXME: Add bold for string args.
                Text(String(format: Strings.PrivacyHub.riskiestWebsiteBody,
                            lastWeekRiskiestWebsite.0, lastWeekRiskiestWebsite.1))
                  .font(.callout)
              } else {
                Text(Strings.PrivacyHub.noDataToShow)
                  .foregroundColor(Color(.secondaryBraveLabel))
              }
            }
            
            Spacer()
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color(.braveBackground))
          .cornerRadius(15)
        }
        .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

#if DEBUG
struct PrivacyHubLastWeekSection_Previews: PreviewProvider {
  static var previews: some View {
    PrivacyHubLastWeekSection(lastWeekMostFrequentTracker: nil, lastWeekRiskiestWebsite: nil)
  }
}
#endif
