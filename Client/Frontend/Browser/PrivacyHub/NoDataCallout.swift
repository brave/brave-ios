// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

extension PrivacyReportsView {
  struct NoDataCallout: View {
    var body: some View {
      HStack {
        Image(systemName: "info.circle.fill")
        Text("Visit some websites to see data here.")
      }
      .foregroundColor(Color.white)
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color(.braveInfoLabel))
      .cornerRadius(15)
    }
  }
}

#if DEBUG
struct NoDataCallout_Previews: PreviewProvider {
  static var previews: some View {
    PrivacyReportsView.NoDataCallout()
  }
}
#endif
