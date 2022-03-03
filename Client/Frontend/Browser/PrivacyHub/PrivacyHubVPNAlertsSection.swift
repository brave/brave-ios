// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveShared

extension PrivacyReportsView {
  struct PrivacyHubVPNAlertsSection: View {
    private(set) var onDismiss: () -> Void
    
    let vpnAlerts: [VPNAlertCell.VPNAlert] =
    [.init(date: Date(), text: "'App Measurement' collects app usage, device info, and app activity.", type: .data),
     .init(date: Date(), text: "‘Branch’ collects location and other geo data.", type: .location),
     .init(date: Date(), text: "App Measurement collects app usage, device info, and app activity.", type: .mail)
    ]
    
    var body: some View {
      VStack(alignment: .leading) {
        Text(Strings.PrivacyHub.vpnAlertsHeader.uppercased())
          .font(.footnote.weight(.medium))
          .fixedSize(horizontal: false, vertical: true)
        
        ForEach(vpnAlerts, id: \.self) { alert in
          VPNAlertCell(vpnAlert: alert)
            .background(Color(.braveBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        
        NavigationLink(destination: AllVPNAlertsView(onDismiss: {
          onDismiss()
        })) {
          HStack {
            Text(Strings.PrivacyHub.allVPNAlertsButtonText)
            Image(systemName: "arrow.right")
          }
          .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .foregroundColor(Color(.braveLabel))
        .overlay(
          RoundedRectangle(cornerRadius: 25)
            .stroke(Color(.braveLabel), lineWidth: 1))
      }
    }
  }
}

#if DEBUG
struct PrivacyHubVPNAlertsSection_Previews: PreviewProvider {
  static var previews: some View {
    PrivacyHubVPNAlertsSection()
  }
}
#endif
