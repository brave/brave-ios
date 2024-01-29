// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatPageContextView: View {
  @Binding var isToggleOn: Bool
  
  @State var isToggleEnabled: Bool
  
  var body: some View {
    Toggle(isOn: $isToggleOn) {
      Text("Use page context for response \(Image(braveSystemName: "leo.info.outline"))")
        .font(.footnote)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
    }
    .disabled(!isToggleEnabled)
    .tint(Color(braveSystemName: .primary60))
    .padding(8.0)
    .background(
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .foregroundStyle(Color(braveSystemName: .pageBackground))
    )
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatPageContextView(isToggleOn: .constant(true), isToggleEnabled: true)
    .previewLayout(.sizeThatFits)
}
