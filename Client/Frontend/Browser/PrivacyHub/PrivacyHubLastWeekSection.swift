// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

extension PrivacyReportsView {
  struct PrivacyHubLastWeekSection: View {
    let lastWeekMostFrequentTracker: (String, Int)?
    let lastWeekRiskiestWebsite: (String, Int)?
    
    var body: some View {
      Group {
        VStack(alignment: .leading, spacing: 8) {
          Text("LAST WEEK")
            .font(.footnote.weight(.medium))
          
          HStack {
            Image("frequent_tracker")
            VStack(alignment: .leading) {
              Text("MOST FREQUENT TRACKED & AD")
                .font(.caption)
                .foregroundColor(.init(.secondaryBraveLabel))
              if let lastWeekMostFrequentTracker = lastWeekMostFrequentTracker {
                Group {
                  Text(lastWeekMostFrequentTracker.0)
                    .fontWeight(.medium) +
                  Text(" was blocked by Brave Shields on ") +
                  Text("\(lastWeekMostFrequentTracker.1)")
                    .fontWeight(.medium) +
                  Text(" times")
                }
                .font(.callout)
                
              } else {
                Text("No data to show yet.")
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
              
              if let lastWeekRiskiestWebsite = lastWeekRiskiestWebsite {
                Group {
                  Text(lastWeekRiskiestWebsite.0)
                    .fontWeight(.medium) +
                  Text(" had an average of ") +
                  Text("\(lastWeekRiskiestWebsite.1)")
                    .fontWeight(.medium) +
                  Text(" trackers & ads blocked per visit")
                }
                .font(.callout)
              } else {
                Text("RISKIEST WEBSITE YOU VISITED")
                  .font(.caption)
                  .foregroundColor(Color(.secondaryBraveLabel))
                Text("No data to show yet.")
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
