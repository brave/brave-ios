/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveCore
import DesignSystem

struct NFTDetailView: View {
  @ObservedObject var nftDetailStore: NFTDetailStore
  @Binding var buySendSwapDestination: BuySendSwapDestination?
  
  @ViewBuilder private var nftImage: some View {
    if let erc721MetaData = nftDetailStore.erc721MetaData {
      WebImageReader(url: erc721MetaData.imageURL) { image, isFinished in
        if let image = image {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(10)
        } else {
          Text(Strings.Wallet.nftDetailImageNotAvailable)
            .foregroundColor(Color(.secondaryBraveLabel))
            .frame(maxWidth: .infinity, idealHeight: 200)
        }
      }
    } else {
      Text(Strings.Wallet.nftDetailImageNotAvailable)
        .foregroundColor(Color(.secondaryBraveLabel))
        .frame(maxWidth: .infinity, idealHeight: 200)
    }
  }
  var body: some View {
    ScrollView() {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          if nftDetailStore.isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, idealHeight: 200)
          } else {
            nftImage
          }
          Text(nftDetailStore.nft.nftTokenTitle)
            .font(.title3.weight(.semibold))
            .foregroundColor(Color(.braveLabel))
          Text(nftDetailStore.nft.name)
            .foregroundColor(Color(.secondaryBraveLabel))
          Button(action: {
            buySendSwapDestination = BuySendSwapDestination(
              kind: .send,
              initialToken: nftDetailStore.nft
            )
          }) {
            Text(Strings.Wallet.nftDetailSendNFTButtonTitle)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(BraveFilledButtonStyle(size: .large))
        }
        if let erc721MetaData = nftDetailStore.erc721MetaData {
          if let description = erc721MetaData.description {
            VStack(alignment: .leading, spacing: 8) {
              Text(Strings.Wallet.nftDetailDescription)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color(.braveLabel))
              Text(description)
                .foregroundColor(Color(.braveLabel))
            }
          }
        }
        VStack(spacing: 16) {
          Group {
            HStack {
              Text(Strings.Wallet.nftDetailBlockchain)
                .font(.headline.weight(.semibold))
              Spacer()
              Text(nftDetailStore.networkInfo.chainName)
            }
            HStack {
              Text(Strings.Wallet.nftDetailTokenStandard)
                .font(.headline.weight(.semibold))
              Spacer()
              Text(Strings.Wallet.nftDetailERC721)
            }
            HStack {
              Text(Strings.Wallet.nftDetailTokenID)
                .font(.headline.weight(.semibold))
              Spacer()
              if let tokenId = Int(nftDetailStore.nft.tokenId.removingHexPrefix, radix: 16) {
                Text(verbatim: "#\(tokenId)")
              } else {
                Text("\(nftDetailStore.nft.name) #\(nftDetailStore.nft.tokenId)")
              }
            }
          }
          .foregroundColor(Color(.braveLabel))
        }
      }
      .padding()
    }
    .onAppear {
      nftDetailStore.fetchMetaData()
    }
    .navigationBarTitle(Strings.Wallet.nftDetailTitle)
  }
}
