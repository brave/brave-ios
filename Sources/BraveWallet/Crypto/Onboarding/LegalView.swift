/* Copyright 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import DesignSystem

struct LegalView: View {
  @ObservedObject var keyringStore: KeyringStore
  var setupOption: SetupOption
  
  @State private var isResponsibilityCheckboxChecked: Bool = false
  @State private var isTermsCheckboxChecked: Bool = false
  @State private var isShowingCreateNewWallet: Bool = false
  @State private var isShowingRestoreExistedWallet: Bool = false
  
  enum SetupOption {
    case new
    case restore
  }
  
  private var isContinueDisabled: Bool {
    !isResponsibilityCheckboxChecked || !isTermsCheckboxChecked
  }
  
  var body: some View {
    ScrollView {
      VStack(spacing: 48) {
        VStack(spacing: 14) {
          Text(Strings.Wallet.legalTitle)
            .font(.title)
            .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
          Text(Strings.Wallet.legalDescription)
            .font(.subheadline)
            .foregroundColor(Color(uiColor: WalletV2Design.textSecondary))
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        HStack(alignment: .top, spacing: 16) {
          Toggle("", isOn: $isResponsibilityCheckboxChecked)
            .labelsHidden()
            .tint(Color(.braveBlurpleTint))
          Text(Strings.Wallet.legalUserResponsibility)
            .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        HStack(alignment: .top, spacing: 16) {
          Toggle("", isOn: $isTermsCheckboxChecked)
            .labelsHidden()
            .tint(Color(.braveBlurpleTint))
          Text(LocalizedStringKey(String.localizedStringWithFormat(Strings.Wallet.legalTermOfUse, WalletConstants.braveWalletTermsOfUse.absoluteDisplayString)))
            .foregroundColor(Color(uiColor: WalletV2Design.textPrimary))
            .tint(Color(.braveBlurpleTint))
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        Button {
          if setupOption == .new {
            isShowingCreateNewWallet = true
          } else {
            isShowingRestoreExistedWallet = true
          }
        } label: {
          Text(Strings.Wallet.continueButtonTitle)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(BraveFilledButtonStyle(size: .large))
        .disabled(isContinueDisabled)
        .padding(.top, 40)
      }
    }
    .padding()
    .background(
      NavigationLink(
        destination: CreateWalletContainerView(keyringStore: keyringStore),
        isActive: $isShowingCreateNewWallet,
        label: {
          EmptyView()
        }
      )
    )
    .background(
      NavigationLink(
        destination: RestoreWalletContainerView(keyringStore: keyringStore),
        isActive: $isShowingRestoreExistedWallet,
        label: {
          EmptyView()
        }
      )
    )
    .accessibilityEmbedInScrollView()
    .background(Color(.braveBackground).edgesIgnoringSafeArea(.all))
    .transparentNavigationBar(backButtonTitle: Strings.Wallet.web3DomainInterstitialPageTAndU.capitalizeFirstLetter, backButtonDisplayMode: .generic)
  }
}

#if DEBUG
struct LegalView_Previews: PreviewProvider {
  static var previews: some View {
    LegalView(keyringStore: .previewStore, setupOption: .new)
  }
}
#endif
