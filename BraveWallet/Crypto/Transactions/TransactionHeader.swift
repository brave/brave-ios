// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveCore
import Strings
import SwiftUI

struct TransactionHeader: View {
  
  let fromAccountAddress: String
  let fromAccountName: String
  let toAccountAddress: String
  let toAccountName: String
  let originInfo: BraveWallet.OriginInfo?
  let transactionType: String
  let value: String
  let fiat: String?
  
  @Environment(\.sizeCategory) private var sizeCategory
  
  var body: some View {
    VStack(spacing: 8) {
      VStack(spacing: 8) {
        BlockieGroup(
          fromAddress: fromAccountAddress,
          toAddress: toAccountAddress,
          size: 48
        )
        Group {
          if sizeCategory.isAccessibilityCategory {
            VStack {
              Text(fromAccountName)
              Image(systemName: "arrow.down")
              Text(toAccountName)
            }
          } else {
            HStack {
              Text(fromAccountName)
              Image(systemName: "arrow.right")
              Text(toAccountName)
            }
          }
        }
        .foregroundColor(Color(.bravePrimary))
        .font(.callout)
      }
      .accessibilityElement()
      .accessibility(addTraits: .isStaticText)
      .accessibility(
        label: Text(String.localizedStringWithFormat(
          Strings.Wallet.transactionFromToAccessibilityLabel, fromAccountName, toAccountName
        ))
      )
      if let originInfo = originInfo {
        Text(urlOrigin: originInfo.origin)
          .foregroundColor(Color(.braveLabel))
          .font(.subheadline)
          .padding(.top, 8) // match vertical padding for tx type, value & fiat VStack
      }
      VStack(spacing: 4) {
        Text(transactionType)
          .font(.footnote)
        Text(value)
          .fontWeight(.semibold)
          .foregroundColor(Color(.bravePrimary))
        if let fiat = fiat {
          Text(fiat) // Value in Fiat
            .font(.footnote)
        }
      }
      .padding(.vertical, 8)
    }
  }
}
