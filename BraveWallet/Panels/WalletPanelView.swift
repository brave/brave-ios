// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

public protocol WalletSiteConnectionDelegate {
  /// A list of accounts connected to this webpage (addresses)
  var connectedAccounts: [String] { get }
  /// Update the connection status for a given account
  func updateConnectionStatusForAccountAddress(_ address: String)
}

public struct WalletPanelView: View {
  @ObservedObject var keyringStore: KeyringStore
  @ObservedObject var networkStore: NetworkStore
  
  @Environment(\.pixelLength) private var pixelLength
  @Environment(\.sizeCategory) private var sizeCategory
  @ScaledMetric private var blockieSize = 54
  
  public init(keyringStore: KeyringStore, networkStore: NetworkStore) {
    self.keyringStore = keyringStore
    self.networkStore = networkStore
  }
  
  private var connectButton: some View {
    Button {
      
    } label: {
      HStack {
        Image(systemName: "checkmark")
        Text("Connected…")
          .fontWeight(.bold)
          .lineLimit(1)
      }
      .foregroundColor(.white)
      .font(.caption.weight(.semibold))
      .padding(.init(top: 6, leading: 12, bottom: 6, trailing: 12))
      .background(
        Color.white.opacity(0.5)
          .clipShape(Capsule().inset(by: 0.5).stroke())
      )
      .clipShape(Capsule())
      .contentShape(Capsule())
    }
  }
  
  private var networkPickerButton: some View {
    Button {
      
    } label: {
      HStack {
        Text(networkStore.selectedChain.shortChainName)
          .fontWeight(.bold)
          .lineLimit(1)
        Image(systemName: "chevron.down.circle")
      }
      .foregroundColor(.white)
      .font(.caption.weight(.semibold))
      .padding(.init(top: 6, leading: 12, bottom: 6, trailing: 12))
      .background(
        Color.white.opacity(0.5)
          .clipShape(Capsule().inset(by: 0.5).stroke())
      )
      .clipShape(Capsule())
      .contentShape(Capsule())
    }
  }
  
  public var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack(spacing: 0) {
        Text("Brave Wallet")
          .font(.headline)
          .padding(16)
          .frame(maxWidth: .infinity)
          .overlay(
            Color.white.opacity(0.3) // Divider
              .frame(height: pixelLength),
            alignment: .bottom
          )
          .background(
            Color.clear
          )
        VStack {
          if sizeCategory.isAccessibilityCategory {
            VStack {
              connectButton
              networkPickerButton
            }
          } else {
            HStack {
              connectButton
              Spacer()
              networkPickerButton
            }
          }
          VStack(spacing: 12) {
            Button {
              
            } label: {
              Blockie(address: keyringStore.selectedAccount.address)
                .frame(width: blockieSize, height: blockieSize)
                .overlay(
                  Circle().strokeBorder(lineWidth: 2, antialiased: true)
                )
                .overlay(
                  Image(systemName: "chevron.down.circle.fill")
                    .font(.footnote)
                    .background(Color(.braveLabel).clipShape(Circle())),
                  alignment: .bottomLeading
                )
            }
            VStack(spacing: 4) {
              Text(keyringStore.selectedAccount.name)
                .font(.headline)
              Text(keyringStore.selectedAccount.address.truncatedAddress)
                .font(.callout)
            }
          }
          VStack(spacing: 4) {
            Text("0.31178 ETH")
              .font(.title2.weight(.bold))
            Text("$872.48")
              .font(.callout)
          }
          .padding(.vertical)
          HStack(spacing: 0) {
            Button {
              
            } label: {
              Image("brave.arrow.left.arrow.right")
                .imageScale(.large)
                .padding(.horizontal, 44)
                .padding(.vertical, 8)
            }
            Color.white.opacity(0.6)
              .frame(width: pixelLength)
            Button {
            } label: {
              Image("brave.history")
                .imageScale(.large)
                .padding(.horizontal, 44)
                .padding(.vertical, 8)
            }
          }
          .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.white.opacity(0.6), style: .init(lineWidth: pixelLength)))
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 24, trailing: 12))
      }
    }
    .foregroundColor(.white)
    .background(
      LinearGradient(
        colors: [.green, .blue],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    )
    .frame(idealWidth: 320)
  }
}

#if DEBUG
struct WalletPanelView_Previews: PreviewProvider {
  static var previews: some View {
    WalletPanelView(
      keyringStore: .previewStoreWithWalletCreated,
      networkStore: .previewStore
    )
      .fixedSize(horizontal: false, vertical: true)
      .previewLayout(.sizeThatFits)
  }
}
#endif
