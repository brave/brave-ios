/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

extension AllVPNAlertsView {
  struct VPNAlertStat: View {
    
    private let type: VPNAlertCell.AlertType
    private let compact: Bool
    
    init(type: VPNAlertCell.AlertType, compact: Bool) {
      self.type = type
      self.compact = compact
    }
    
    var body: some View {
      HStack {
        Image(type.assetName)
          .padding(.leading)
        
        if compact {
          VStack(alignment: .leading) {
            Text(type.headerText)
              .foregroundColor(Color(.secondaryBraveLabel))
              .font(.caption.weight(.semibold))
            Text("\(123)")
              .font(.headline.weight(.semibold))
              // Smaller custom padding here to try to display the cell's text in one line
              // on regular font size English language.
              .padding(.trailing, 4)
          }
          Spacer()
        } else {
          Text(type.headerText)
            .font(.caption.weight(.semibold))
          Spacer()
          Text("\(123)")
            .font(.headline.weight(.semibold))
            .padding(.trailing)
        }
      }
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity)
      .background(Color(.braveBackground))
      .cornerRadius(15)
      
    }
  }
}

#if DEBUG
struct VPNAlertStat_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      AllVPNAlertsView.VPNAlertStat(type: .data, compact: false)
        .previewLayout(PreviewLayout.sizeThatFits)
      AllVPNAlertsView.VPNAlertStat(type: .mail, compact: true)
        .previewLayout(PreviewLayout.sizeThatFits)
      AllVPNAlertsView.VPNAlertStat(type: .location, compact: true)
        .previewLayout(PreviewLayout.sizeThatFits)
    }
    
  }
}
#endif
