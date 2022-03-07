// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI

struct EditNonceView: View {
  @Environment(\.sizeCategory) private var sizeCategory
  @State private var nonce = ""
  
  @ViewBuilder private var editNonceButtons: some View {
    Button(action: {}) {
      Text("Cancel")
    }
    .buttonStyle(BraveOutlineButtonStyle(size: .large))
    Button(action: {}) {
      Text("Save")
    }
    .buttonStyle(BraveFilledButtonStyle(size: .large))
  }
  
  var body: some View {
    List {
      Section {
        TextField("Enter custom nonce value", text: $nonce)
          .keyboardType(.numberPad)
      } header: {
        Text("Nonce")
          .textCase(.none)
      } footer: {
        Text("Transaction may not be propagated in the network.")
      }
      Section {
        Group {
          if sizeCategory.isAccessibilityCategory {
            VStack {
              editNonceButtons
            }
          } else {
            HStack {
              editNonceButtons
            }
          }
        }
        .frame(maxWidth: .infinity)
        .listRowInsets(.zero)
        .listRowBackground(Color(.braveGroupedBackground))
      }
    }
    .listStyle(InsetGroupedListStyle())
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("Advanced settings")
  }
}

#if DEBUG
struct EditNonceView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      EditNonceView()
    }
  }
}
#endif
