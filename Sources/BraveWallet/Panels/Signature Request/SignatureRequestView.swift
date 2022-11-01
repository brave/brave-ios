// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import BraveCore
import BraveShared
import DesignSystem

struct SignatureRequestView: View {
  var requests: [BraveWallet.SignMessageRequest]
  @ObservedObject var keyringStore: KeyringStore
  var cryptoStore: CryptoStore
  
  var onDismiss: () -> Void

  @State private var requestIndex: Int = 0
  @State private var renderUnknownUnicodes: Bool = false
  @State private var needPilcrowFormatted: Bool = false
  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.presentationMode) @Binding private var presentationMode
  @ScaledMetric private var blockieSize = 54
  private let maxBlockieSize: CGFloat = 108
  private let staticTextViewHeight: CGFloat = 200
  
  private var currentRequest: BraveWallet.SignMessageRequest {
    requests[requestIndex]
  }
  
  private var account: BraveWallet.AccountInfo {
    keyringStore.allAccounts.first(where: { $0.address == currentRequest.address }) ?? keyringStore.selectedAccount
  }
  
  private var requestMessage: String {
    var result = currentRequest.message
    
    if needPilcrowFormatted {
      var copy = currentRequest.message
      while copy.range(of: "\\n{2,}", options: .regularExpression) != nil {
        if let range = copy.range(of: "\\n{2,}", options: .regularExpression) {
          let newlines = String(copy[range])
          result.replaceSubrange(range, with: "\n\u{00B6} <\(newlines.count)>\n")
          copy.replaceSubrange(range, with: "\n\u{00B6} <\(newlines.count)>\n")
        }
      }
    }
    
    if renderUnknownUnicodes {
      result = result.printableWithUnknownUnicode
    }
    
    return result
  }
  
  private struct WarningView<Button: View>: View {
    var warningMsg: String
    var button: () -> Button
    
    @Environment(\.pixelLength) private var pixelLength
    
    init(
      warningMsg: String,
      @ViewBuilder button: @escaping () -> Button
    ) {
      self.warningMsg = warningMsg
      self.button = button
    }
    
    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text("\(Image(systemName: "exclamationmark.triangle.fill"))  \(warningMsg)")
          .font(.subheadline.weight(.medium))
          .foregroundColor(Color(.braveLabel))
        button()
      }
      .padding(12)
      .background(
        Color(.braveWarningBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .strokeBorder(Color(.braveWarningBorder), style: StrokeStyle(lineWidth: pixelLength))
          )
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      )
    }
  }
  
  init(
    requests: [BraveWallet.SignMessageRequest],
    keyringStore: KeyringStore,
    cryptoStore: CryptoStore,
    onDismiss: @escaping () -> Void
  ) {
    assert(!requests.isEmpty)
    self.requests = requests
    self.keyringStore = keyringStore
    self.cryptoStore = cryptoStore
    self.onDismiss = onDismiss
  }
  
  var body: some View {
    ScrollView(.vertical) {
      VStack {
        if requests.count > 1 {
          HStack {
            Spacer()
            Text(String.localizedStringWithFormat(Strings.Wallet.transactionCount, requestIndex + 1, requests.count))
              .fontWeight(.semibold)
            Button(action: next) {
              Text(Strings.Wallet.next)
                .fontWeight(.semibold)
                .foregroundColor(Color(.braveBlurpleTint))
            }
          }
        }
        VStack(spacing: 12) {
          VStack(spacing: 8) {
            Blockie(address: account.address)
              .frame(width: min(blockieSize, maxBlockieSize), height: min(blockieSize, maxBlockieSize))
            AddressView(address: account.address) {
              VStack(spacing: 4) {
                Text(account.name)
                  .font(.subheadline.weight(.semibold))
                  .foregroundColor(Color(.braveLabel))
                Text(account.address.truncatedAddress)
                  .font(.subheadline.weight(.semibold))
                  .foregroundColor(Color(.secondaryBraveLabel))
              }
            }
            Text(urlOrigin: currentRequest.originInfo.origin)
              .font(.caption)
              .foregroundColor(Color(.braveLabel))
              .multilineTextAlignment(.center)
          }
          .accessibilityElement(children: .combine)
          Text(Strings.Wallet.signatureRequestSubtitle)
            .font(.headline)
            .foregroundColor(Color(.bravePrimary))
          VStack(alignment: .leading, spacing: 8) {
            if needPilcrowFormatted {
              WarningView(warningMsg: Strings.Wallet.signMessageConsecutiveNewlineWarning) {}
            }
            if currentRequest.message.hasUnknownUnicode {
              WarningView(warningMsg: Strings.Wallet.signMessageRequestUnknownUnicodeWarning) {
                Button {
                  renderUnknownUnicodes.toggle()
                } label: {
                  Text(renderUnknownUnicodes ? Strings.Wallet.signMessageShowOriginalMessage : Strings.Wallet.signMessageShowUnknownUnicode)
                    .font(.subheadline)
                    .foregroundColor(Color(.braveBlurple))
                }
              }
            }
          }
        }
        .padding(.vertical, 32)
        StaticTextView(text: requestMessage, isMonospaced: false)
          .frame(maxWidth: .infinity)
          .frame(height: staticTextViewHeight)
          .background(Color(.tertiaryBraveGroupedBackground))
          .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
          .padding()
        .background(
          Color(.secondaryBraveGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        buttonsContainer
          .padding(.top)
          .opacity(sizeCategory.isAccessibilityCategory ? 0 : 1)
          .accessibility(hidden: sizeCategory.isAccessibilityCategory)
      }
      .padding()
    }
    .overlay(
      Group {
        if sizeCategory.isAccessibilityCategory {
          buttonsContainer
            .frame(maxWidth: .infinity)
            .padding(.top)
            .background(
              LinearGradient(
                stops: [
                  .init(color: Color(.braveGroupedBackground).opacity(0), location: 0),
                  .init(color: Color(.braveGroupedBackground).opacity(1), location: 0.05),
                  .init(color: Color(.braveGroupedBackground).opacity(1), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
              .ignoresSafeArea()
              .allowsHitTesting(false)
            )
        }
      },
      alignment: .bottom
    )
    .frame(maxWidth: .infinity)
    .navigationTitle(Strings.Wallet.signatureRequestTitle)
    .navigationBarTitleDisplayMode(.inline)
    .foregroundColor(Color(.braveLabel))
    .background(Color(.braveGroupedBackground).edgesIgnoringSafeArea(.all))
    .introspectTextView { textView in
      // A flash to show users message is overflowing the text view (related to issue https://github.com/brave/brave-ios/issues/6277)
      textView.flashScrollIndicators()
      if textView.contentSize.height > staticTextViewHeight && requestMessage.hasConsecutiveNewLines {
        needPilcrowFormatted = true
      }
    }
  }
  
  private var isButtonsDisabled: Bool {
    requestIndex != 0
  }
  
  @ViewBuilder private var buttonsContainer: some View {
    if sizeCategory.isAccessibilityCategory {
      VStack {
        buttons
      }
    } else {
      HStack {
        buttons
      }
    }
  }
  
  @ViewBuilder private var buttons: some View {
    Button(action: { // cancel
      cryptoStore.handleWebpageRequestResponse(.signMessage(approved: false, id: currentRequest.id))
      if requests.count == 1 {
        onDismiss()
      }
    }) {
      Label(Strings.cancelButtonTitle, systemImage: "xmark")
        .imageScale(.large)
    }
    .buttonStyle(BraveOutlineButtonStyle(size: .large))
    .disabled(isButtonsDisabled)
    Button(action: { // approve
      cryptoStore.handleWebpageRequestResponse(.signMessage(approved: true, id: currentRequest.id))
      if requests.count == 1 {
        onDismiss()
      }
    }) {
      Label(Strings.Wallet.sign, braveSystemImage: "brave.key")
        .imageScale(.large)
    }
    .buttonStyle(BraveFilledButtonStyle(size: .large))
    .disabled(isButtonsDisabled)
  }
  
  private func next() {
    if requestIndex + 1 < requests.count {
      requestIndex += 1
    } else {
      requestIndex = 0
    }
  }
}

extension String {
  var hasUnknownUnicode: Bool {
    // same requirement as desktop. Valid: [0, 127]
    for c in unicodeScalars {
      let ci = Int(c.value)
      if ci > 127 {
        return true
      }
    }
    return false
  }
  
  var hasConsecutiveNewLines: Bool {
    // return true if string has two or more consecutive newline chars
    return range(of: "\\n{2,}", options: .regularExpression) != nil
  }
  
  var printableWithUnknownUnicode: String {
    var result = ""
    for c in unicodeScalars {
      let ci = Int(c.value)
      if let unicodeScalar = Unicode.Scalar(ci) {
        if ci == 10 { // will keep newline char as it is
          result += "\n"
        } else if ci == 182 {
          result += unicodeScalar.escaped(asASCII: false) // will display pilcrow sign
        } else {
          // ascii char will be displayed as it is
          // unknown (> 127) will be displayed as hex-encoded
          result += unicodeScalar.escaped(asASCII: true)
        }
      }
    }
    return result
  }
}

#if DEBUG
struct SignatureRequestView_Previews: PreviewProvider {
  static var previews: some View {
    SignatureRequestView(
      requests: [.previewRequest],
      keyringStore: .previewStoreWithWalletCreated,
      cryptoStore: .previewStore,
      onDismiss: { }
    )
  }
}
#endif
