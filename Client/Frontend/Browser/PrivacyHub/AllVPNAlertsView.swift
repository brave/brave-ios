/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import Shared
import BraveShared
import Data

struct AllVPNAlertsView: View {
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @Environment(\.managedObjectContext) var context

  @FetchRequest(
    entity: BraveVPNAlert.entity(),
    sortDescriptors: [
      NSSortDescriptor(keyPath: \BraveVPNAlert.timestamp, ascending: false)
    ],
    // For performance reasons we grab last month's alerts only.
    predicate: NSPredicate(format: "timestamp > %lld", Int64(Date().timeIntervalSince1970 - 30.days))
  ) var vpnAlerts: FetchedResults<BraveVPNAlert>

  let trackerCounts: (trackerCount: Int, locationPingCount: Int, emailTrackerCount: Int)
  private(set) var onDismiss: () -> Void

  private var headerView: some View {
    VStack {
      HStack {
        Text(Strings.PrivacyHub.vpvnAlertsTotalCount.uppercased())
          .font(.subheadline.weight(.medium))
        Spacer()
        Text("\(trackerCounts.trackerCount + trackerCounts.locationPingCount + trackerCounts.emailTrackerCount)")
          .font(.headline.weight(.semibold))
      }
      .padding()
      .background(Color("total_alerts_background"))
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

      if sizeCategory.isAccessibilityCategory && horizontalSizeClass == .compact {
        VPNAlertStat(
          assetName: "vpn_data_tracker",
          title: Strings.PrivacyHub.vpnAlertRegularTrackerTypePlural,
          count: trackerCounts.trackerCount,
          compact: true)
        VPNAlertStat(
          assetName: "vpn_location_tracker",
          title: Strings.PrivacyHub.vpnAlertLocationTrackerTypePlural,
          count: trackerCounts.locationPingCount,
          compact: true)
        VPNAlertStat(
          assetName: "vpn_mail_tracker",
          title: Strings.PrivacyHub.vpnAlertEmailTrackerTypePlural,
          count: trackerCounts.emailTrackerCount,
          compact: true)
      } else {
        VPNAlertStat(
          assetName: "vpn_data_tracker",
          title: Strings.PrivacyHub.vpnAlertRegularTrackerTypePlural,
          count: trackerCounts.trackerCount,
          compact: false)
        HStack {
          VPNAlertStat(
            assetName: "vpn_location_tracker",
            title: Strings.PrivacyHub.vpnAlertLocationTrackerTypePlural,
            count: trackerCounts.locationPingCount,
            compact: true)
          VPNAlertStat(
            assetName: "vpn_mail_tracker",
            title: Strings.PrivacyHub.vpnAlertEmailTrackerTypePlural,
            count: trackerCounts.emailTrackerCount,
            compact: true)
        }
      }

    }
    .padding(.vertical)
  }

  private func cell(_ alert: BraveVPNAlert) -> some View {
    VPNAlertCell(vpnAlert: alert)
      .listRowInsets(.init())
      .background(Color(.braveBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .padding(.vertical, 4)
  }

  var body: some View {

    Group {
      VStack(alignment: .leading) {

        if #available(iOS 15, *) {
          List {
            Section {
              ForEach(vpnAlerts) { alert in
                cell(alert)
                  .listRowBackground(Color.clear)
                  .listRowSeparator(.hidden)
              }
            } header: {
              headerView
                .listRowInsets(.init())
            }
          }
          .listStyle(.insetGrouped)

          Spacer()
        } else {
          // Workaround: iOS 14 does not easily support hidden separators for List,
          // have to use ScrollView > LazyVSack instead.
          ScrollView {
            headerView

            LazyVStack(spacing: 0) {
              ForEach(vpnAlerts) { alert in
                cell(alert)
              }
            }
          }
          .padding(.horizontal)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.secondaryBraveBackground).ignoresSafeArea())
    .ignoresSafeArea(.container, edges: .bottom)
    .navigationTitle(Strings.PrivacyHub.allVPNAlertsButtonText)
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
struct AllVPNAlertsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      AllVPNAlertsView()
      AllVPNAlertsView()
        .preferredColorScheme(.dark)
    }
  }
}
#endif
