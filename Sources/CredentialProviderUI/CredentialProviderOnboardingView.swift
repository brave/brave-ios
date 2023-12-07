// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import DesignSystem

public struct CredentialProviderOnboardingView: View {
  public var action: () -> Void
  public init(action: @escaping () -> Void) {
    self.action = action
  }
  public var body: some View {
    VStack(spacing: 0) {
      // FIXME: Replace with real logo?
      Image(braveSystemName: "leo.brave.icon-monochrome")
        .font(.system(size: 100))
        .foregroundStyle(LinearGradient(braveSystemName: .braveRelease))
        .aspectRatio(1, contentMode: .fit)
        .background {
          Color.white
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 1)
            .shadow(color: .black.opacity(0.08), radius: 40, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top)
      VStack {
        VStack(spacing: 12) {
          Text("AutoFill Brave Passwords")
            .font(.title.bold())
            .multilineTextAlignment(.center)
            .foregroundColor(Color(braveSystemName: .textPrimary))
          Text("Some secondary text")
            .font(.subheadline)
            .foregroundColor(Color(braveSystemName: .textSecondary))
        }
        .padding(.horizontal)
        Spacer()
        Button {
          action()
        } label: {
          Text("Continue")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BraveFilledButtonStyle(size: .large))
      }
      .padding()
      .padding()
    }
    .background {
      LinearGradient(braveSystemName: .hero)
        .overlay {
          Rectangle().fill(Material.bar)
        }
        .ignoresSafeArea()
    }
  }
}

#if DEBUG
#Preview {
  CredentialProviderOnboardingView(action: {})
}
#endif
