/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct AllVPNAlertsView: View {
  let vpnAlerts: [VPNAlertCell.VPNAlert] =
  [.init(date: Date(), text: "'App Measurement' collects app usage, device info, and app activity.", type: .data),
   .init(date: Date(), text: "‘Branch’ collects location and other geo data.", type: .location),
   .init(date: Date(), text: "App Measurement collects app usage, device info, and app activity.", type: .mail),
   .init(date: Date(), text: "'App Measurement' collects app usage, device info, and app activity.", type: .data),
   .init(date: Date(), text: "‘Branch’ collects location and other geo data.", type: .location),
   .init(date: Date(), text: "App Measurement collects app usage, device info, and app activity.", type: .mail)
  ]
  
  var body: some View {
    
    VStack(alignment: .leading) {
      List {
        Section {
          ForEach(vpnAlerts, id: \.self) { alert in
            VPNAlertCell(vpnAlert: alert)
              .listRowInsets(.init())
              .background(Color(.braveBackground))
              .cornerRadius(15)
          }
        } header: {
          VStack {
            HStack {
              Text("Total alerts".uppercased())
                .font(.subheadline.weight(.medium))
              Spacer()
              Text("123")
                .font(.headline.weight(.semibold))
            }
            .padding()
            .background(Color(.tertiaryBraveBackground))
            .cornerRadius(15)
            
            HStack {
              VPNAlertStat(type: .data, compact: false)
            }
            
            HStack {
              VPNAlertStat(type: .location, compact: true)
              VPNAlertStat(type: .mail, compact: true)
            }
          }
          .padding(.bottom)
          .listRowInsets(.init())
        }
        
      }
      
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.secondaryBraveBackground))
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
