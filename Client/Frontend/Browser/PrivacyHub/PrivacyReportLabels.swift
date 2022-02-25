// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

extension PrivacyReportsView {
  struct BlockedLabel: View {
    var body: some View {
      Text("Blocked".uppercased())
        .foregroundColor(Color("label_red_foreground"))
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color("label_red_background"))
        .cornerRadius(4)
    }
  }
  
  struct BlockedByVPNLabel: View {
    var body: some View {
      Text("Firewall + VPN".uppercased())
        .foregroundColor(Color("label_violet_foreground"))
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color("label_violet_background"))
        .clipShape(Capsule())
    }
  }
  
  struct BlockedByShieldsLabel: View {
    var body: some View {
      Text("Shields".uppercased())
        .foregroundColor(Color("label_orange_foreground"))
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color("label_orange_background"))
        .clipShape(Capsule())
    }
  }
}

#if DEBUG
struct PrivacyReportLabels_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      PrivacyReportsView.BlockedLabel()
      PrivacyReportsView.BlockedByVPNLabel()
      PrivacyReportsView.BlockedByShieldsLabel()
      
      Group {
        PrivacyReportsView.BlockedLabel()
        PrivacyReportsView.BlockedByVPNLabel()
        PrivacyReportsView.BlockedByShieldsLabel()
      }
      .preferredColorScheme(.dark)
      
    }
    .previewLayout(.sizeThatFits)
    .padding()
    
  }
}
#endif
