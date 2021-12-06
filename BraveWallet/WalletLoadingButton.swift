// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI

struct WalletLoadingButton<Title: View>: View {
  @Binding var isLoading: Bool
  var action: () -> Void
  var title: Title
  
  @ScaledMetric private var length: CGFloat = 20.0
  
  init(
    isLoading: Binding<Bool>,
    action: @escaping () -> Void,
    @ViewBuilder title: () -> Title
  ) {
    self._isLoading = isLoading
    self.action = action
    self.title = title()
  }
  
  var body: some View {
    Button {
      if !isLoading {
        action()
      }
    } label: {
      ZStack {
        title
        Circle()
          .trim(from: 0, to: 0.7)
          .stroke(.white, lineWidth: 2)
          .frame(width: length, height: length)
          .rotationEffect(.degrees(isLoading ? 360 : 0))
          .animation(.linear(duration: 0.5).repeatForever(autoreverses: false), value: isLoading)
          .opacity(isLoading ? 1 : 0)
      }
    }
  }
}

#if DEBUG
struct WalletLoadingButton_Previews: PreviewProvider {
  static var previews: some View {
    WalletLoadingButton(
      isLoading: .constant(true),
      action: {
      // preview
      },
      title: {
        Text("Preview")
      }
    )
      .buttonStyle(BraveFilledButtonStyle(size: .normal))
      .disabled(true)
      .frame(maxWidth: .infinity)
  }
}
#endif
