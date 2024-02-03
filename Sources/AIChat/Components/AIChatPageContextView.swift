// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatPageContextView: View {
  @Binding var isToggleOn: Bool
  
  @State var isToggleEnabled: Bool
  
  var body: some View {
    Toggle(isOn: $isToggleOn) {
      Text("Shape answers based on the page's contents \(Image(braveSystemName: "leo.info.outline"))")
        .font(.footnote)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
    }
    .disabled(!isToggleEnabled)
    .tint(isToggleOn ? Color(braveSystemName: .primary60) : Color(braveSystemName: .gray30))
    .padding([.vertical, .trailing], 8.0)
    .padding(.leading, 12.0)
    .background(
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .foregroundStyle(Color(braveSystemName: .pageBackground))
    )
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
    .shadow(color: .black.opacity(0.15), radius: 4.0, x: 0.0, y: 1.0)
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatPageContextView(isToggleOn: .constant(true), isToggleEnabled: true)
    .previewLayout(.sizeThatFits)
}
