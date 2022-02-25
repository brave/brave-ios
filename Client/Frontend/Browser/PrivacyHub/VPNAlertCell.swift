// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct VPNAlertCell: View {
  enum AlertType {
    case data, location, mail
  }
  
  private var assetName: String {
    switch vpnAlert.type {
    case .data: return "vpn_data_tracker"
    case .location: return "vpn_location_tracker"
    case .mail: return "vpn_mail_tracker"
    }
  }
  
  private var headerText: String {
    switch vpnAlert.type {
    case .data: return "Tracker & Ad"
    case .location: return "Location Ping"
    case .mail: return "Email tracker"
    }
  }
  
  var date: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: vpnAlert.date)
  }
  
  struct VPNAlert {
    let date: Date
    let text: String
    let type: AlertType
  }
  
  private let vpnAlert: VPNAlert
  
  init(vpnAlert: VPNAlert) {
    self.vpnAlert = vpnAlert
  }
  
  var body: some View {
    
    HStack(alignment: .top) {
      Image(assetName)
      VStack(alignment: .leading) {
        HStack(spacing: 4) {
          Text(headerText)
            .foregroundColor(Color(.secondaryBraveLabel))
          Text("Blocked")
            .foregroundColor(Color(.braveErrorBorder))
            .padding(.horizontal, 4)
            .background(Color(.braveErrorBackground))
            .cornerRadius(4)
        }
        .font(.caption.weight(.semibold))
        
        Text(vpnAlert.text)
          .font(.callout)
        
        Text(date)
          .font(.caption)
          .foregroundColor(Color(.secondaryBraveLabel))
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
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
