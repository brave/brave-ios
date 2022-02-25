// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

extension PrivacyReportsView {
  struct PrivacyHubAllTimeSection: View {
    let allTimeMostFrequentTracker: (String, Int)?
    let allTimeRiskiestWebsite: (String, Int)?
    
    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text("ALL TIME")
          .font(.footnote.weight(.medium))
        
        HStack(spacing: 12) {
          VStack {
            Text("TRACKER & AD")
              .font(.caption)
              .frame(maxWidth: .infinity, alignment: .leading)
              .foregroundColor(Color(.secondaryBraveLabel))
            
            if let allTimeMostFrequentTracker = allTimeMostFrequentTracker {
              VStack(alignment: .leading) {
                Text(allTimeMostFrequentTracker.0)
                Text("\(allTimeMostFrequentTracker.1) sites")
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .font(.subheadline)
              
            } else {
              Text("No data to show yet.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryBraveLabel))
            }
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color(.braveBackground))
          .cornerRadius(15)
          
          VStack {
            Text("WEBSITE")
              .font(.caption)
              .frame(maxWidth: .infinity, alignment: .leading)
              .foregroundColor(Color(.secondaryBraveLabel))
            
            if let allTimeRiskiestWebsite = allTimeRiskiestWebsite {
              VStack(alignment: .leading) {
                Text(allTimeRiskiestWebsite.0)
                Text("\(allTimeRiskiestWebsite.1) sites")
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .font(.subheadline)
              
            } else {
              Text("No data to show yet.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
                .foregroundColor(Color(.secondaryBraveLabel))
            }
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color(.braveBackground))
          .cornerRadius(15)
        }
        
        Button(action: {
          
        }) {
          NavigationLink(destination: PrivacyReportAllTimeListsView()) {
            HStack {
              Text("All time lists")
              Image(systemName: "arrow.right")
            }
          }
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity)
          .foregroundColor(Color(.braveLabel))
        }
        .overlay(
          RoundedRectangle(cornerRadius: 25)
            .stroke(Color(.braveLabel), lineWidth: 1))
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
