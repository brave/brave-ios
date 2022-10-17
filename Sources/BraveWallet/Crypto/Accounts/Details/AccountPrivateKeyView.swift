// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import DesignSystem
import Strings

struct AccountPrivateKeyView: View {
  @ObservedObject var keyringStore: KeyringStore
  var account: BraveWallet.AccountInfo

  @State private var key: String = ""
  @State private var isKeyVisible: Bool = false

  @Environment(\.pixelLength) private var pixelLength

  var body: some View {
    ScrollView(.vertical) {
      VStack {
        Text("\(Image(systemName: "exclamationmark.triangle.fill"))  \(Strings.Wallet.accountPrivateKeyDisplayWarning)")
          .font(.subheadline.weight(.medium))
          .foregroundColor(Color(.braveLabel))
          .padding(12)
          .background(
            Color(.braveWarningBackground)
              .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                  .strokeBorder(Color(.braveWarningBorder), style: StrokeStyle(lineWidth: pixelLength))
              )
              .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          )
        SensitiveTextView(text: key, isShowingText: $isKeyVisible)
          .multilineTextAlignment(.center)
          .font(.system(.body, design: .monospaced))
          .padding(40)

        Button(action: {
          withAnimation {
            isKeyVisible.toggle()
          }
        }) {
          Text(isKeyVisible ? Strings.Wallet.hidePrivateKeyButtonTitle : Strings.Wallet.showPrivateKeyButtonTitle)
        }
        .buttonStyle(BraveFilledButtonStyle(size: .normal))
        .animation(nil, value: isKeyVisible)
      }
      .padding()
      .onAppear {
        // TODO: Issue #5881 - Add password protection to view
        keyringStore.privateKey(for: account, password: "") { key in
          self.key = key ?? ""
        }
      }
    }
    .background(Color(.braveBackground))
    .navigationTitle(Strings.Wallet.accountPrivateKey)
    .navigationBarTitleDisplayMode(.inline)
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
      isKeyVisible = false
    }
    .alertOnScreenshot {
      Alert(
        title: Text(Strings.Wallet.screenshotDetectedTitle),
        message: Text(Strings.Wallet.privateKeyScreenshotDetectedMessage),
        dismissButton: .cancel(Text(Strings.OKString))
      )
    }
  }
}

#if DEBUG
struct AccountPrivateKeyView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AccountPrivateKeyView(keyringStore: .previewStoreWithWalletCreated, account: .previewAccount)
    }
    .previewSizeCategories()
  }
}
#endif
