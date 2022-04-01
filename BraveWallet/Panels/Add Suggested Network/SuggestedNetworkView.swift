// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import struct Shared.Strings
import BraveShared
import BraveCore

struct SuggestedNetworkView: View {
  enum Mode: Equatable {
    case switchNetworks(chainId: String, origin: URL)
    case addNetwork(BraveWallet.NetworkInfo)
  }
  
  var mode: Mode
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  
  @State private var isPresentingNetworkDetails: CustomNetworkModel?
  @State private var customNetworkError: CustomNetworkError?
  
  @ScaledMetric private var blockieSize = 24
  @ScaledMetric private var faviconSize = 48

  @Environment(\.sizeCategory) private var sizeCategory
  @Environment(\.openWalletURLAction) private var openWalletURL
  
  var onDismiss: (_ approved: Bool) -> Void
  
  init(
    mode: Mode,
    keyringStore: KeyringStore,
    networkStore: NetworkStore,
    onDismiss: @escaping (_ approved: Bool) -> Void
  ) {
    self.mode = mode
    self.keyringStore = keyringStore
    self.networkStore = networkStore
    self.onDismiss = onDismiss
  }
  
  private var chain: BraveWallet.NetworkInfo? {
    switch mode {
    case let .addNetwork(chain):
      return chain
    case let .switchNetworks(chainId, _):
      return networkStore.ethereumChains.first(where: { $0.chainId == chainId })
    }
  }
  
  private var navigationTitle: String {
    switch mode {
    case .switchNetworks: return Strings.Wallet.switchNetworkTitle
    case .addNetwork: return Strings.Wallet.addNetworkTitle
    }
  }
  
  private var headerTitle: String {
    switch mode {
    case .switchNetworks: return Strings.Wallet.switchNetworkSubtitle
    case .addNetwork: return Strings.Wallet.addNetworkSubtitle
    }
  }
  
  private var headerDescription: String {
    switch mode {
    case .switchNetworks: return Strings.Wallet.switchNetworkDescription
    case .addNetwork: return Strings.Wallet.addNetworkDescription
    }
  }
  
  private var headerView: some View {
    VStack {
      HStack(spacing: 8) {
        Spacer()
        Text(keyringStore.selectedAccount.address.truncatedAddress)
          .fontWeight(.semibold)
        Blockie(address: keyringStore.selectedAccount.address)
          .frame(width: blockieSize, height: blockieSize)
      }
      VStack(spacing: 8) {
        Image(systemName: "globe")
          .frame(width: faviconSize, height: faviconSize)
          .background(Color(.braveDisabled))
          .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        if case let .switchNetworks(_, origin) = mode {
          Text(verbatim: origin.absoluteDisplayString)
            .font(.subheadline)
            .foregroundColor(Color(.braveLabel))
            .multilineTextAlignment(.center)
        }
        Text(headerTitle)
          .font(.headline)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.center)
        Text(headerDescription)
          .font(.subheadline)
          .foregroundColor(Color(.braveLabel))
          .multilineTextAlignment(.center)
        if case .addNetwork = mode {
          Button {
            openWalletURL?(BraveUX.braveWalletNetworkLearnMoreURL)
          } label: {
            Text(Strings.Wallet.learnMoreButton)
              .foregroundColor(Color(.braveBlurpleTint))
          }
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical)
    }
    .resetListHeaderStyle()
    .padding(.vertical)
  }
  
  var body: some View {
    List {
      Section {
        if let chain = chain {
          VStack(alignment: .leading) {
            Text(Strings.Wallet.networkNameTitle)
              .fontWeight(.semibold)
            Text(chain.chainName)
          }
          .padding(.vertical, 6)
          if let networkURL = chain.rpcUrls.first {
            VStack(alignment: .leading) {
              Text(Strings.Wallet.networkURLTitle)
                .fontWeight(.semibold)
              Text(URL(string: networkURL)?.absoluteDisplayString ?? networkURL)
            }
            .padding(.vertical, 6)
          }
          Button {
            let networkDetails = CustomNetworkModel()
            networkDetails.populateDetails(from: chain, mode: .view)
            self.isPresentingNetworkDetails = networkDetails
          } label: {
            Text(Strings.Wallet.viewDetails)
              .foregroundColor(Color(.braveBlurpleTint))
          }
        }
      } header: {
        headerView
      }
      .listRowBackground(Color(.secondaryBraveGroupedBackground))
      .font(.footnote)
      
      Section {
        actionButtonContainer
          .frame(maxWidth: .infinity)
      }
      .listRowBackground(Color(.braveGroupedBackground))
      .listRowInsets(.zero)
      .opacity(sizeCategory.isAccessibilityCategory ? 0 : 1)
      .accessibility(hidden: sizeCategory.isAccessibilityCategory)
    }
    .navigationTitle(navigationTitle)
    .navigationBarTitleDisplayMode(.inline)
    .overlay(
      Group {
        if sizeCategory.isAccessibilityCategory {
          actionButtonContainer
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
    .background(
      Color.clear
        .sheet(item: $isPresentingNetworkDetails) { detailsModel in
          NavigationView {
            CustomNetworkDetailsView(
              networkStore: networkStore,
              model: detailsModel
            )
          }
          .navigationViewStyle(StackNavigationViewStyle())
        }
    )
    .background(
      Color.clear
        .alert(
          item: $customNetworkError,
          content: { error in
            Alert(
              title: Text(error.errorTitle),
              message: Text(error.errorDescription),
              dismissButton: .default(Text(Strings.OKString))
            )
          })
    )
  }
  
  private var actionButtonTitle: String {
    switch mode {
    case .switchNetworks: return Strings.Wallet.switchNetworkButtonTitle
    case .addNetwork: return Strings.Wallet.approveNetworkButtonTitle
    }
  }
  
  private var verticalActionButtons: Bool {
    if case .switchNetworks = mode {
      return true
    } else {
      return sizeCategory.isAccessibilityCategory
    }
  }
  
  @ViewBuilder private var actionButtonContainer: some View {
    if verticalActionButtons {
      VStack {
        actionButtons
      }
    } else {
      HStack {
        actionButtons
      }
    }
  }

  @ViewBuilder private var actionButtons: some View {
    Button(action: { onDismiss(false) }) {
      HStack {
        Image(systemName: "xmark")
        Text(Strings.cancelButtonTitle)
      }
    }
    .buttonStyle(BraveOutlineButtonStyle(size: .large))
    Button(action: { onDismiss(true) }) {
      HStack {
        Image("brave.checkmark.circle.fill")
        Text(actionButtonTitle)
          .multilineTextAlignment(.center)
      }
    }
    .buttonStyle(BraveFilledButtonStyle(size: .large))
  }
}

#if DEBUG
struct SuggestedNetworkView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      SuggestedNetworkView(
        mode: .addNetwork(.mockRopsten),
        keyringStore: .previewStoreWithWalletCreated,
        networkStore: .previewStore,
        onDismiss: { _ in }
      )
      SuggestedNetworkView(
        mode: .switchNetworks(
          chainId: BraveWallet.RopstenChainId,
          origin: URL(string: "https://app.uniswap.org")!),
        keyringStore: .previewStoreWithWalletCreated,
        networkStore: .previewStore,
        onDismiss: { _ in }
      )
    }
  }
}
#endif
