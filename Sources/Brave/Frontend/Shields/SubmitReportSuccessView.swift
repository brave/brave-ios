// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import BraveUI
import DesignSystem
import SnapKit

struct SubmitReportSuccessView: View {
  var body: some View {
    VStack(alignment: .center, spacing: 16) {
      Image(braveSystemName: "leo.check.circle-outline")
        .resizable()
        .frame(width: 48, height: 48)
        .foregroundStyle(Color(braveSystemName: .systemfeedbackSuccessIcon))
      
      Text(Strings.Shields.siteReportedTitle)
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .font(.title)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
      
      Text(Strings.Shields.siteReportedBody)
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
    }
    .padding(32)
  }
}

#if swift(>=5.9)
#Preview {
  SubmitReportSuccessView()
}
#endif
