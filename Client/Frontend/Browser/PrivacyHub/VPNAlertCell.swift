/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct VPNAlertCell: View {
  enum AlertType {
    case data, location, mail
    
    var assetName: String {
      switch self {
      case .data: return "vpn_data_tracker"
      case .location: return "vpn_location_tracker"
      case .mail: return "vpn_mail_tracker"
      }
    }
    
    var headerText: String {
      switch self {
      case .data: return "Tracker & Ad"
      case .location: return "Location Pings"
      case .mail: return "Email tracker"
      }
    }
  }
  
  var date: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: vpnAlert.date)
  }
  
  struct VPNAlert: Hashable {
    let date: Date
    let text: String
    let type: AlertType
  }
  
  private let vpnAlert: VPNAlert
  
  init(vpnAlert: VPNAlert) {
    self.vpnAlert = vpnAlert
  }
  
  @State private var vpnAlertsEnabled = true
  
  var body: some View {
    HStack(alignment: .top) {
      Image(vpnAlert.type.assetName)
      VStack(alignment: .leading) {
        HStack(spacing: 4) {
          Text(vpnAlert.type.headerText)
            .foregroundColor(Color(.secondaryBraveLabel))
          PrivacyReportsView.BlockedLabel()
        }
        .font(.caption.weight(.semibold))
        
        Text(vpnAlert.text)
          .font(.callout)
          .fixedSize(horizontal: false, vertical: true)
        
        Text(date)
          .font(.caption)
          .foregroundColor(Color(.secondaryBraveLabel))
      }
      Spacer()
    }
    .background(Color(.braveBackground))
    .frame(maxWidth: .infinity)
    .padding(.horizontal)
    .padding(.vertical, 8)
    .cornerRadius(15)
  }
}

#if DEBUG
struct VPNAlertCell_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      VPNAlertCell(vpnAlert: .init(date: Date(), text: "'App Measurement' collects app usage, device info, and app activity.", type: .data))
        .previewLayout(PreviewLayout.sizeThatFits)
      VPNAlertCell(vpnAlert: .init(date: Date(), text: "‘Branch’ collects location and other geo data.", type: .location))
        .previewLayout(PreviewLayout.sizeThatFits)
      VPNAlertCell(vpnAlert: .init(date: Date(), text: "App Measurement collects app usage, device info, and app activity.", type: .mail))
        .previewLayout(PreviewLayout.sizeThatFits)
    }
    
  }
}
#endif
