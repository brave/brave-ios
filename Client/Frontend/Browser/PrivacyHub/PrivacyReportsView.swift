/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveUI
import Shared
import BraveShared
import Data

struct PrivacyReportsView: View {
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  let lastWeekMostFrequentTracker: (String, Int)?
  let lastWeekRiskiestWebsite: (String, Int)?
  let allTimeMostFrequentTracker: (String, Int)?
  let allTimeRiskiestWebsite: (String, Int)?
  let allTimeListTrackers: [PrivacyReportsItem]
  let allTimeListWebsites: [PrivacyReportsItem]
  let lastVPNAlerts: [BraveVPNAlert]?
  
  var onDismiss: (() -> Void)?
  
  private var noData: Bool {
    return lastWeekMostFrequentTracker == nil
    && lastWeekRiskiestWebsite == nil
    && allTimeMostFrequentTracker == nil
    && allTimeRiskiestWebsite == nil
  }
  
  @State var showNotificationCallout = false
  
  @ObservedObject private var showNotificationPermissionCallout = Preferences.PrivacyHub.shouldShowNotificationPermissionCallout
  
  private var vpnAlertsEnabled: Bool {
    return true
  }
  
  @State private var correctAuthStatus: Bool = false
  
  @State private var showClearDataPrompt: Bool = false
  
  /// This is to cover a case where user has set up their notifications already, and pressing on 'Enable notifications' would do nothing.
  private func determineNotificationPermissionStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        correctAuthStatus =
        settings.authorizationStatus == .notDetermined || settings.authorizationStatus == .provisional
      }
    }
  }
  
  private func dismissView() {
    // Dismiss on presentation mode does not work on iOS 14
    // when using the UIHostingController is parent view.
    // As a workaround a simple completion handler is used instead.
    if #available(iOS 15, *) {
      presentationMode.dismiss()
    } else {
      onDismiss?()
    }
  }
  
  var body: some View {
    NavigationView {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 16) {
          
          if showNotificationPermissionCallout.value && correctAuthStatus {
            NotificationCalloutView()
          }
          
          if noData {
            NoDataCallout()
          }
          
          PrivacyHubLastWeekSection(
            lastWeekMostFrequentTracker: lastWeekMostFrequentTracker,
            lastWeekRiskiestWebsite: lastWeekRiskiestWebsite)
          
          Divider()
          
          if Preferences.PrivacyHub.captureVPNAlerts.value, let lastVPNAlerts = lastVPNAlerts, !lastVPNAlerts.isEmpty {
            PrivacyHubVPNAlertsSection(
              lastVPNAlerts: lastVPNAlerts,
              onDismiss: {
                dismissView()
              })
            
            Divider()
          }
          
          PrivacyHubAllTimeSection(
            allTimeMostFrequentTracker: allTimeMostFrequentTracker,
            allTimeRiskiestWebsite: allTimeRiskiestWebsite,
            allTimeListTrackers: allTimeListTrackers,
            allTimeListWebsites: allTimeListWebsites,
            onDismiss: {
              dismissView()
            })
          
          // FIXME: EXPERIMENTAL UI
          Text("These stats are only stored on your device, and are not sent anywhere. Ever.")
            .font(.caption)
            .multilineTextAlignment(.center)
          Text("Learn more about Privacy Reports")
            .underline()
            .font(.caption.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .center)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle(Strings.PrivacyHub.privacyReportsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(Strings.done) {
              dismissView()
            }
            .foregroundColor(Color(.braveOrange))
          }
          
          ToolbarItem(placement: .cancellationAction) {
            Button(action: {
              showClearDataPrompt = true
            }, label: {
              Image(systemName: "trash")
            })
              .foregroundColor(Color(.braveOrange))
              .actionSheet(isPresented: $showClearDataPrompt) {
                // FIXME: Currently .actionSheet does not allow you leave empty title for the sheet.
                // This could get converted to .confirmationPrompt or Menu with destructive buttons
                // once iOS 15 is minimum supported version
                .init(title: Text(Strings.PrivacyHub.clearAllDataPrompt),
                      buttons: [
                        .destructive(Text(Strings.yes), action: {
                          PrivacyReportsManager.clearAllData()
                          // Dismiss to avoid having to observe for db changes to update the view.
                          dismissView()
                        }),
                        .cancel()
                      ])
              }
          }
        }
      }
      .background(Color(.secondaryBraveBackground).ignoresSafeArea())
    }
    .navigationViewStyle(.stack)
    .environment(\.managedObjectContext, DataController.swiftUIContext)
    .onAppear(perform: determineNotificationPermissionStatus)
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
