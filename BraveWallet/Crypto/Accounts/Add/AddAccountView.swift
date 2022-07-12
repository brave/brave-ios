/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveUI
import DesignSystem
import Strings
import BraveCore

struct AddAccountView: View {
  @ObservedObject var keyringStore: KeyringStore

  @State private var name: String = ""
  @State private var privateKey: String = ""
  @State private var isPresentingImport: Bool = false
  @State private var isLoadingFile: Bool = false
  @State private var originPassword: String = ""
  @State private var failedToImport: Bool = false
  @State private var isPresentingAddAccount: Bool = false
  @ScaledMetric(relativeTo: .body) private var privateKeyFieldHeight: CGFloat = 140.0
  @Environment(\.presentationMode) @Binding var presentationMode
  
  @ScaledMetric private var iconSize = 40.0
  private let maxIconSize: CGFloat = 80.0
  
  var coin: BraveWallet.CoinType?

  private func addAccount() {
    if privateKey.isEmpty {
      // Add normal account
      let accountName = name.isEmpty ? String.localizedStringWithFormat(Strings.Wallet.defaultAccountName, keyringStore.keyring.accountInfos.filter(\.isPrimary).count + 1) : name
      keyringStore.addPrimaryAccount(accountName) { success in
        if success {
          presentationMode.dismiss()
        }
      }
    } else {
      let handler: (Bool, String) -> Void = { success, _ in
        if success {
          presentationMode.dismiss()
        } else {
          failedToImport = true
        }
      }
      let accountName = name.isEmpty ? String.localizedStringWithFormat(Strings.Wallet.defaultSecondaryAccountName, keyringStore.keyring.accountInfos.filter(\.isImported).count + 1) : name
      if isJSONImported {
        keyringStore.addSecondaryAccount(accountName, json: privateKey, password: originPassword, completion: handler)
      } else {
        keyringStore.addSecondaryAccount(accountName, privateKey: privateKey, completion: handler)
      }
    }
  }

  private var isJSONImported: Bool {
    guard let data = privateKey.data(using: .utf8) else {
      return false
    }
    do {
      _ = try JSONSerialization.jsonObject(with: data, options: [])
      return true
    } catch {
      return false
    }
  }
  
  @ViewBuilder private var addAccountView: some View {
    List {
      accountNameSection
      if isJSONImported {
        originPasswordSection
      }
      privateKeySection
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(Strings.Wallet.addAccountTitle)
    .navigationBarItems(
      // Have to use this instead of toolbar placement to have a custom button style
      trailing: Button(action: addAccount) {
        Text(Strings.Wallet.add)
      }
        .buttonStyle(BraveFilledButtonStyle(size: .small))
    )
    .alert(isPresented: $failedToImport) {
      Alert(
        title: Text(Strings.Wallet.failedToImportAccountErrorTitle),
        message: Text(Strings.Wallet.failedToImportAccountErrorMessage),
        dismissButton: .cancel(Text(Strings.OKString))
      )
    }
  }

  var body: some View {
    Group {
      if coin == nil {
        List {
          Section(
            header: WalletListHeaderView(
              title: Text(Strings.Wallet.coinTypeSelectionHeader)
            )
          ) {
            ForEach(WalletConstants.supportedCoinTypes) { coin in
              NavigationLink(isActive: $isPresentingAddAccount) {
                addAccountView
              } label: {
                Button(action: {
                  isPresentingAddAccount = true
                }) {
                  HStack(spacing: 10) {
                    Image(coin.iconName, bundle: .current)
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .clipShape(Circle())
                      .frame(width: min(iconSize, maxIconSize), height: min(iconSize, maxIconSize))
                    VStack(alignment: .leading, spacing: 3) {
                      Text(coin.localizedTitle)
                        .foregroundColor(Color(.bravePrimary))
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                      Text(coin.localizedDescription)
                        .foregroundColor(Color(.braveLabel))
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                    }
                  }
                  .padding(.vertical, 10)
                }
              }
            }
          }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Strings.Wallet.addAccountTitle)
      } else {
        addAccountView
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .cancellationAction) {
        Button(action: {
          presentationMode.dismiss()
        }) {
          Text(Strings.cancelButtonTitle)
            .foregroundColor(Color(.braveOrange))
        }
      }
    }
  }

  private var accountNameSection: some View {
    Section(
      header: WalletListHeaderView(
        title: Text(Strings.Wallet.accountDetailsNameTitle)
          .font(.subheadline.weight(.semibold))
          .foregroundColor(Color(.bravePrimary))
      )
      .osAvailabilityModifiers { content in
        if #available(iOS 15.0, *) {
          content  // Padding already applied
        } else {
          content
            .padding(.top)
        }
      }
    ) {
      TextField(Strings.Wallet.accountDetailsNamePlaceholder, text: $name)
        .listRowBackground(Color(.secondaryBraveGroupedBackground))
    }
  }

  private var originPasswordSection: some View {
    Section(
      header: WalletListHeaderView(
        title: Text(Strings.Wallet.importAccountOriginPasswordTitle)
          .font(.subheadline.weight(.semibold))
          .foregroundColor(Color(.bravePrimary))
      )
    ) {
      SecureField(Strings.Wallet.passwordPlaceholder, text: $originPassword)
    }
    .listRowBackground(Color(.secondaryBraveGroupedBackground))
  }

  private var privateKeySection: some View {
    Section(
      header: WalletListHeaderView(
        title: Text(Strings.Wallet.importAccountSectionTitle)
          .font(.subheadline.weight(.semibold))
          .foregroundColor(Color(.bravePrimary))
      )
    ) {
      TextEditor(text: $privateKey)
        .autocapitalization(.none)
        .font(.system(.body, design: .monospaced))
        .frame(height: privateKeyFieldHeight)
        .background(
          Text(Strings.Wallet.importAccountPlaceholder)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)  // To match the TextEditor's editing insets
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color(.placeholderText))
            .opacity(privateKey.isEmpty ? 1 : 0)
            .accessibilityHidden(true),
          alignment: .top
        )
        .introspectTextView { textView in
          textView.smartQuotesType = .no
        }
        .accessibilityValue(privateKey.isEmpty ? Strings.Wallet.importAccountPlaceholder : privateKey)
      Button(action: { isPresentingImport = true }) {
        HStack {
          Text(Strings.Wallet.importButtonTitle)
            .foregroundColor(.accentColor)
            .font(.callout)
          if isLoadingFile {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
          }
        }
        .frame(maxWidth: .infinity)
      }
      .disabled(isLoadingFile)
    }
    .listRowBackground(Color(.secondaryBraveGroupedBackground))
  }
}

#if DEBUG
struct AddAccountView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AddAccountView(keyringStore: .previewStore)
    }
  }
}
#endif
