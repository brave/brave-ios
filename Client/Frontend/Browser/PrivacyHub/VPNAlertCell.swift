/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import Data

struct VPNAlertCell: View {
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
  var date: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    let date = Date(timeIntervalSince1970: TimeInterval(vpnAlert.timestamp))
    return formatter.string(from: date)
  }
  
  private func assetName(for type: BraveVPNAlert.TrackerType) -> String {
    switch type {
    case .app: return "vpn_data_tracker"
    case .location: return "vpn_location_tracker"
    case .mail: return "vpn_mail_tracker"
    }
  }
  
  private func headerText(for type: BraveVPNAlert.TrackerType) -> String {
    switch type {
    case .app: return "Tracker & Ad"
    case .location: return "Location Pings"
    case .mail: return "Email tracker"
    }
  }
  
  private let vpnAlert: BraveVPNAlert
  
  init(vpnAlert: BraveVPNAlert) {
    self.vpnAlert = vpnAlert
  }
  
  private var headerText: some View {
    Group {
      if let category = vpnAlert.categoryEnum {
        Text(headerText(for: category))
          .foregroundColor(Color(.secondaryBraveLabel))
          .font(.caption.weight(.semibold))
      } else {
        EmptyView()
      }
    }
  }
  
  var body: some View {
    HStack(alignment: .top) {
      if let category = vpnAlert.categoryEnum {
        Image(assetName(for: category))
      }
      
      VStack(alignment: .leading) {
        
        Group {
          if sizeCategory.isAccessibilityCategory && horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 4) {
              headerText
              PrivacyReportsView.BlockedLabel()
            }
          } else {
            HStack(spacing: 4) {
              headerText
              PrivacyReportsView.BlockedLabel()
            }
          }
        }
        .font(.caption.weight(.semibold))
        
        VStack(alignment: .leading, spacing: 4) {
          Text(vpnAlert.message)
            .font(.callout)
          
          Text(date)
            .font(.caption)
            .foregroundColor(Color(.secondaryBraveLabel))
        }
      }
      Spacer()
    }
    .background(Color(.braveBackground))
    .frame(maxWidth: .infinity)
    .fixedSize(horizontal: false, vertical: true)
    .padding(.horizontal)
    .padding(.vertical, 8)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
