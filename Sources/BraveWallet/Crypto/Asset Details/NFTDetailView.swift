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
  
  @Environment(\.openWalletURLAction) private var openWalletURL
  
  @ViewBuilder private var noImageView: some View {
    Text(Strings.Wallet.nftDetailImageNotAvailable)
      .foregroundColor(Color(.secondaryBraveLabel))
      .frame(maxWidth: .infinity, minHeight: 300)
  }
  
  @ViewBuilder private var nftImage: some View {
    if let erc721Metadata = nftDetailStore.erc721Metadata {
      let test: String? = "https://d4rgq65mqvxhk.cloudfront.net/public/gift_icons/officialGift%2378548ed1-9c95-4634-b355-ca8c2a53da4f.svg"
      if let urlString = erc721Metadata.imageURLString {
        NFTImageView(urlString: urlString) {
          noImageView
        }
        .cornerRadius(10)
//        .frame(maxWidth: .infinity, minHeight: 300)
      } else {
        noImageView
      }
    } else {
      noImageView
    }
  }
  var body: some View {
    ScrollView(.vertical) {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          if nftDetailStore.isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, minHeight: 300)
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
        if let erc721Metadata = nftDetailStore.erc721Metadata, let description = erc721Metadata.description {
          VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Wallet.nftDetailDescription)
              .font(.headline.weight(.semibold))
              .foregroundColor(Color(.braveLabel))
            Text(description)
              .foregroundColor(Color(.braveLabel))
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
              Button(action: {
                if let explorerURL = nftDetailStore.networkInfo.blockExplorerUrls.first {
                  let baseURL = "\(explorerURL)/token/\(nftDetailStore.nft.contractAddress)"
                  var nftURL = URL(string: baseURL)
                  if let tokenId = Int(nftDetailStore.nft.tokenId.removingHexPrefix, radix: 16) {
                    nftURL = URL(string: "\(baseURL)?a=\(tokenId)")
                  }
                  
                  if let url = nftURL {
                    openWalletURL?(url)
                  }
                }
              }) {
                if let tokenId = Int(nftDetailStore.nft.tokenId.removingHexPrefix, radix: 16) {
                  Text(verbatim: "#\(tokenId)")
                    .foregroundColor(Color(.braveBlurple))
                } else {
                  Text("\(nftDetailStore.nft.name) #\(nftDetailStore.nft.tokenId)")
                    .foregroundColor(Color(.braveBlurple))
                }
              }
            }
          }
          .foregroundColor(Color(.braveLabel))
        }
      }
      .padding()
    }
    .onAppear {
      if nftDetailStore.erc721Metadata == nil {
        nftDetailStore.fetchMetadata()
      }
    }
    .background(Color(UIColor.braveGroupedBackground).ignoresSafeArea())
    .navigationBarTitle(Strings.Wallet.nftDetailTitle)
  }
}
