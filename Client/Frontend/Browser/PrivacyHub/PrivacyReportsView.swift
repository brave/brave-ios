/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveUI

struct PrivacyReportsView: View {
  
  let lastWeekMostFrequentTracker: (String, Int)?
  let lastWeekRiskiestWebsite: (String, Int)?
  let allTimeMostFrequentTracker: (String, Int)?
  let allTimeRiskiestWebsite: (String, Int)?
  
  private var noData: Bool {
    return lastWeekMostFrequentTracker == nil
    && lastWeekRiskiestWebsite == nil
    && allTimeMostFrequentTracker == nil
    && allTimeRiskiestWebsite == nil
  }
  
  private var showNotificationCallout: Bool {
    // FIXME: Notifications disabled AND user did not dismiss it yet - pref.
    return true
  }
  
  private var vpnAlertsEnabled: Bool {
    return true
  }
  
  var body: some View {
    NavigationView {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 16) {
          
          if showNotificationCallout {
            NotificationCalloutView()
          }
          
          if noData {
            NoDataCallout()
          }
          
          PrivacyHubLastWeekSection(
            lastWeekMostFrequentTracker: lastWeekMostFrequentTracker,
            lastWeekRiskiestWebsite: lastWeekRiskiestWebsite)
          
          Divider()
          
          if vpnAlertsEnabled {
            PrivacyHubVPNAlertsSection()
          }
          
          Divider()
          
          PrivacyHubAllTimeSection(
            allTimeMostFrequentTracker: allTimeMostFrequentTracker,
            allTimeRiskiestWebsite: allTimeRiskiestWebsite)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Privacy report")
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(.stack)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing, content: {
            Image(systemName: "xmark.circle.fill")
          })
        }
      }
      .background(Color(.secondaryBraveBackground))
    }
  }
}

#if DEBUG
struct PrivacyReports_Previews: PreviewProvider {
  static var previews: some View {
    let lastWeekMostFrequentTracker = ("google-analytics", 133)
    let lastWeekRiskiestWebsite = ("example.com", 13)
    let allTimeMostFrequentTracker = ("scary-analytics", 678)
    let allTimeRiskiestWebsite = ("scary.example.com", 554)
    
    Group {
      ContentView(lastWeekMostFrequentTracker: lastWeekMostFrequentTracker, lastWeekRiskiestWebsite: lastWeekRiskiestWebsite, allTimeMostFrequentTracker: allTimeMostFrequentTracker, allTimeRiskiestWebsite: allTimeRiskiestWebsite)
      ContentView(lastWeekMostFrequentTracker: lastWeekMostFrequentTracker, lastWeekRiskiestWebsite: lastWeekRiskiestWebsite, allTimeMostFrequentTracker: allTimeMostFrequentTracker, allTimeRiskiestWebsite: allTimeRiskiestWebsite)
        .preferredColorScheme(.dark)
    }
  }
}
#endif
