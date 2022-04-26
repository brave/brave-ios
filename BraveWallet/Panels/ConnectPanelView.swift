// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveUI
import SwiftUI

// TODO: Remove all these files when swapping them with ads style alerts

public struct WalletPanelButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.7 : 1.0)
      .font(.body.weight(.medium))
      .foregroundColor(.black)
      .padding(EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
      .background(
        Group {
          if isEnabled {
            Color.white.opacity(configuration.isPressed ? 0.7 : 1.0)
          } else {
            Color(.braveDisabled)
          }
        }
      )
      .clipShape(Capsule())
      .contentShape(Capsule())
      .animation(.linear(duration: 0.15), value: isEnabled)
  }
}

public struct ConnectPanelView: View {
  @ObservedObject var keyringStore: KeyringStore
  
  @Environment(\.pixelLength) private var pixelLength
  @ScaledMetric private var faviconSize: Double = 48.0
  
  public init(keyringStore: KeyringStore) {
    self.keyringStore = keyringStore
  }
  
  private var faviconView: some View {
    Image(systemName: "globe")
      .frame(width: faviconSize, height: faviconSize)
      .background(Color.white.opacity(0.2))
      .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
  }
  
  private var messageText: String {
    // NSLocalizedString
    if !keyringStore.keyring.isKeyringCreated {
      return "Use this panel to securely access web3 and all your crypto assets."
    } else if keyringStore.keyring.isLocked {
      return "Unlock Brave Wallet to interact with this page."
    }
    return "This page would like to access your Brave Wallet."
  }
  
  private var actionButton: some View {
    Group {
      if !keyringStore.keyring.isKeyringCreated {
        Button("Learn More") {
          
        }
      } else if keyringStore.keyring.isLocked {
        Button {
          
        } label: {
          Label("Unlock", image: "brave.unlock")
        }
      } else {
        Button {
          
        } label: {
          Text("Continue")
        }
      }
    }
    .buttonStyle(WalletPanelButtonStyle())
  }
  
  public var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
        Section {
          VStack(spacing: 32) {
            VStack(spacing: 8) {
              faviconView
              Text(verbatim: "https://app.uniswap.com")
                .foregroundColor(.white.opacity(0.8))
                .font(.callout)
            }
            Text(messageText)
              .fontWeight(.medium)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
              .padding(.vertical)
            actionButton
          }
          .padding(32)
        } header: {
          Text("Brave Wallet")
            .font(.headline)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
              Color(.braveBlurpleTint)
                .overlay(
                  Color.white.opacity(0.3) // Divider
                    .frame(height: pixelLength),
                  alignment: .bottom
                )
            )
        }
      }
    }
    .foregroundColor(.white)
    .background(Color(.braveBlurpleTint).ignoresSafeArea())
  }
}

#if DEBUG
struct ConnectPanelView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ConnectPanelView(keyringStore: .previewStore)
      ConnectPanelView(keyringStore: {
        let store = KeyringStore.previewStoreWithWalletCreated
        store.lock()
        return store
      }())
      ConnectPanelView(keyringStore: .previewStoreWithWalletCreated)
    }
    .fixedSize(horizontal: false, vertical: true)
    .previewLayout(.sizeThatFits)
  }
}
#endif
