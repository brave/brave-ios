/* Copyright 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import DesignSystem

struct OnBoardingCompletedView: View {
  var onFinish: () -> Void
  
  var body: some View {
    ScrollView {
      VStack {
        Image("wallet-onboarding-complete", bundle: .module)
        Text(Strings.Wallet.onboardingCompletedTitle)
          .font(.title)
          .foregroundColor(.primary)
          .fixedSize(horizontal: false, vertical: true)
        Text(Strings.Wallet.onboardingCompletedSubTitle)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 4)
        Button {
          onFinish()
        } label: {
          Text(Strings.Wallet.onboardingCompletedButtonTitle)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BraveFilledButtonStyle(size: .large))
        .padding(.top, 84)
      }
      .padding(.top, 124)
      .padding(.horizontal, 20)
    }
    .background(
      Image("wallet-background", bundle: .module)
        .resizable()
        .aspectRatio(contentMode: .fill)
    )
    .edgesIgnoringSafeArea(.all)
  }
}

#if DEBUG
struct OnBoardingCompletedView_Previews: PreviewProvider {
  static var previews: some View {
    OnBoardingCompletedView(
      onFinish: {}
    )
  }
}
#endif
