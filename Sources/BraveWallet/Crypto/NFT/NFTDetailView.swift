/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveCore
import DesignSystem
import BraveUI
import SDWebImageSwiftUI

struct NFTDetailView: View {
  @ObservedObject var nftDetailStore: NFTDetailStore
  @Binding var buySendSwapDestination: BuySendSwapDestination? 
  var onNFTMetadataRefreshed: ((NFTMetadata) -> Void)?
  var onNFTStatusUpdated: (() -> Void)?
  
  @Environment(\.openURL) private var openWalletURL
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  @State private var isPresentingRemoveAlert: Bool = false
  
  @ViewBuilder private var noImageView: some View {
    Text(Strings.Wallet.nftDetailImageNotAvailable)
      .foregroundColor(Color(.secondaryBraveLabel))
      .frame(maxWidth: .infinity, minHeight: 300)
  }
  
  @ViewBuilder private var nftLogo: some View {
    if let image = nftDetailStore.networkInfo.nativeTokenLogoImage, !nftDetailStore.isLoading {
      Image(uiImage: image)
        .resizable()
        .frame(width: 32, height: 32)
        .overlay {
          Circle()
            .stroke(lineWidth: 2)
            .foregroundColor(Color(braveSystemName: .containerBackground))
        }
    }
  }
  
  @ViewBuilder private var nftImage: some View {
    NFTImageView(urlString: nftDetailStore.nftMetadata?.imageURLString ?? "", isLoading: nftDetailStore.isLoading) {
      noImageView
    }
    .cornerRadius(10)
    .frame(maxWidth: .infinity, minHeight: 300)
  }
  
  private var isSVGImage: Bool {
    guard let nftMetadata = nftDetailStore.nftMetadata, let imageUrlString = nftMetadata.imageURLString else { return false }
    return imageUrlString.hasPrefix("data:image/svg") || imageUrlString.hasSuffix(".svg")
  }
  
  var body: some View {
    Form {
      Section {
        VStack(alignment: .leading, spacing: 16) {
          nftImage
            .overlay(alignment: .topLeading) {
              if nftDetailStore.nft.isSpam {
                HStack(spacing: 4) {
                  Text(Strings.Wallet.nftSpam)
                    .padding(.vertical, 4)
                    .padding(.leading, 6)
                    .foregroundColor(Color(.braveErrorLabel))
                  Image(braveSystemName: "leo.warning.triangle-outline")
                    .padding(.vertical, 4)
                    .padding(.trailing, 6)
                    .foregroundColor(Color(.braveErrorBorder))
                }
                .font(.system(size: 13).weight(.semibold))
                .background(
                  Color(uiColor: WalletV2Design.spamNFTLabelBackground)
                    .cornerRadius(4)
                )
                .padding(12)
              }
            }
            .overlay(alignment: .bottomTrailing) {
              ZStack {
                if let owner = nftDetailStore.owner {
                  Blockie(address: owner.address, shape: .rectangle)
                    .overlay(
                      RoundedRectangle(cornerRadius: 4)
                        .stroke(lineWidth: 2)
                        .foregroundColor(Color(braveSystemName: .containerBackground))
                    )
                    .frame(width: 32, height: 32)
                    .zIndex(1)
                    .offset(x: -28)
                }
                nftLogo
              }
              .offset(y: 16)
            }
          VStack(alignment: .leading, spacing: 8) {
            Text(nftDetailStore.nft.nftTokenTitle)
              .font(.title3.weight(.semibold))
              .foregroundColor(Color(.braveLabel))
            Text(nftDetailStore.nft.name)
              .foregroundColor(Color(.secondaryBraveLabel))
          }
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
      }
      Section {
        List {
          if let owner = nftDetailStore.owner {
            NFTDetailRow(title: Strings.Wallet.nftDetailOwnedBy) {
              AddressView(address: owner.address) {
                HStack {
                  Text(owner.name)
                    .foregroundColor(Color(.braveBlurpleTint))
                  Text(owner.address.truncatedAddress)
                    .foregroundColor(Color(.braveLabel))
                }
                .font(.subheadline)
              }
            }
          }
          if nftDetailStore.nft.isErc721, let tokenId = Int(nftDetailStore.nft.tokenId.removingHexPrefix, radix: 16) {
            NFTDetailRow(title: Strings.Wallet.nftDetailTokenID) {
              Text("\(tokenId)")
                .font(.subheadline)
                .foregroundColor(Color(.braveLabel))
            }
          }
          NFTDetailRow(title: nftDetailStore.nft.isErc721 ? Strings.Wallet.contractAddressAccessibilityLabel : Strings.Wallet.tokenMintAddress) {
            Button {
              if nftDetailStore.nft.isErc721 {
                if let explorerURL = nftDetailStore.networkInfo.blockExplorerUrls.first {
                  let baseURL = "\(explorerURL)/token/\(nftDetailStore.nft.contractAddress)"
                  var nftURL = URL(string: baseURL)
                  if let tokenId = Int(nftDetailStore.nft.tokenId.removingHexPrefix, radix: 16) {
                    nftURL = URL(string: "\(baseURL)?a=\(tokenId)")
                  }
                  
                  if let url = nftURL {
                    openWalletURL(url)
                  }
                }
              } else {
                if WalletConstants.supportedTestNetworkChainIds.contains(nftDetailStore.networkInfo.chainId) {
                  if let components = nftDetailStore.networkInfo.blockExplorerUrls.first?.separatedBy("/?cluster="), let baseURL = components.first {
                    let cluster = components.last ?? ""
                    if let nftURL = URL(string: "\(baseURL)/address/\(nftDetailStore.nft.contractAddress)/?cluster=\(cluster)") {
                      openWalletURL(nftURL)
                    }
                  }
                } else {
                  if let explorerURL = nftDetailStore.networkInfo.blockExplorerUrls.first, let nftURL = URL(string: "\(explorerURL)/address/\(nftDetailStore.nft.contractAddress)") {
                    openWalletURL(nftURL)
                  }
                }
              }
            } label: {
              Text(nftDetailStore.nft.contractAddress.truncatedAddress)
                .font(.subheadline)
                .foregroundColor(Color(.braveBlurpleTint))
            }
          }
          NFTDetailRow(title: Strings.Wallet.nftDetailBlockchain) {
            Text(nftDetailStore.networkInfo.chainName)
              .font(.subheadline)
              .foregroundColor(Color(.braveLabel))
          }
          NFTDetailRow(title: Strings.Wallet.nftDetailTokenStandard) {
            Text(nftDetailStore.nft.isErc721 ? Strings.Wallet.nftDetailERC721 : Strings.Wallet.nftDetailSPL)
              .font(.subheadline)
              .foregroundColor(Color(.braveLabel))
          }
        }
      } header: {
        Text(Strings.Wallet.nftDetailOverview)
          .listRowInsets(.zero)
      }
      if let nftMetadata = nftDetailStore.nftMetadata, let description = nftMetadata.description, !description.isEmpty {
        Section {
          Text(description)
            .font(.subheadline)
            .foregroundColor(Color(.braveLabel))
        } header: {
          Text(Strings.Wallet.nftDetailDescription)
            .listRowInsets(.zero)
        }
      }
      if let attributes = nftDetailStore.nftMetadata?.attributes {
        Section {
          List {
            ForEach(attributes) { attribute in
              NFTDetailRow(title: attribute.type) {
                Text(attribute.value)
                  .font(.subheadline)
                  .foregroundColor(Color(.braveLabel))
              }
            }
          }
        } header: {
          Text(Strings.Wallet.nftDetailProperties)
            .listRowInsets(.zero)
        }
      }
    }
    .onChange(of: nftDetailStore.nftMetadata, perform: { newValue in
      if let newMetadata = newValue {
        onNFTMetadataRefreshed?(newMetadata)
      }
    })
    .onAppear {
      nftDetailStore.update()
    }
    .background(Color(UIColor.braveGroupedBackground).ignoresSafeArea())
    .navigationBarTitle(nftDetailStore.nft.nftTokenTitle)
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Menu {
          if nftDetailStore.nft.visible {
            Button(action: {
              buySendSwapDestination = BuySendSwapDestination(
                kind: .send,
                initialToken: nftDetailStore.nft
              )
            }) {
              Label(Strings.Wallet.nftDetailSendNFTButtonTitle, braveSystemImage: "leo.send")
            }
            .buttonStyle(BraveFilledButtonStyle(size: .large))
          }
          Button(action: {
            if nftDetailStore.nft.visible { // a collected visible NFT, mark as hidden
              nftDetailStore.updateNFTStatus(visible: false, isSpam: false, isDeletedByUser: false, completion: {
                onNFTStatusUpdated?()
              })
            } else { // either a hidden NFT or a junk NFT, mark as visible
              nftDetailStore.updateNFTStatus(visible: true, isSpam: false, isDeletedByUser: false, completion: {
                onNFTStatusUpdated?()
              })
            }
          }) {
            if nftDetailStore.nft.visible { // a collected visible NFT
              Label(Strings.recentSearchHide, braveSystemImage: "leo.eye.off")
            } else if nftDetailStore.nft.isSpam { // a spam NFT
              Label(Strings.Wallet.nftUnspam, braveSystemImage: "leo.disable.outline")
            } else { // a hidden but not spam NFT
              Label(Strings.Wallet.nftUnhide, braveSystemImage: "leo.eye.on")
            }
          }
          Button(action: {
            isPresentingRemoveAlert = true
          }) {
            Label(Strings.Wallet.nftRemoveFromWallet, braveSystemImage: "leo.trash")
          }
        } label: {
          Label(Strings.Wallet.otherWalletActionsAccessibilityTitle, braveSystemImage: "leo.more.horizontal")
            .labelStyle(.iconOnly)
            .foregroundColor(Color(.braveBlurpleTint))
        }
      }
    }
    .background(
      WalletPromptView(
        isPresented: $isPresentingRemoveAlert,
        primaryButton: .init(
          title: Strings.Wallet.manageSiteConnectionsConfirmAlertRemove,
          action: { _ in
            nftDetailStore.updateNFTStatus(visible: false, isSpam: nftDetailStore.nft.isSpam, isDeletedByUser: true, completion: {
              onNFTStatusUpdated?()
              presentationMode.dismiss()
            })
            isPresentingRemoveAlert = false
          }
        ),
        secondaryButton: .init(
          title: Strings.CancelString,
          action: { _ in
            isPresentingRemoveAlert = false
          }
        ),
        showCloseButton: false,
        content: {
          VStack(spacing: 16) {
            Text(Strings.Wallet.nftRemoveFromWalletAlertTitle)
              .font(.headline)
              .foregroundColor(Color(.bravePrimary))
            Text(Strings.Wallet.nftRemoveFromWalletAlertDescription)
              .font(.footnote)
              .foregroundStyle(Color(.secondaryBraveLabel))
          }
        })
    )
  }
}

struct NFTDetailRow<ValueContent: View>: View {
  var title: String
  var valueContent: () -> ValueContent
  
  init(
    title: String,
    @ViewBuilder valueContent: @escaping () -> ValueContent
  ) {
    self.title = title
    self.valueContent = valueContent
  }
  var body: some View {
    HStack {
      Text(title)
        .font(.subheadline)
        .foregroundColor(Color(.secondaryLabel))
      Spacer()
      valueContent()
        .multilineTextAlignment(.trailing)
    }
  }
}
