// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct CustomNetworksView: View {
  @ObservedObject var networkStore: NetworkStore
  @State private var isPresentingNetworkDetails: CustomNetworkDetails?
  
  private struct CustomNetworkDetails: Identifiable {
    var isAddMode: Bool
    var id: String {
      "\(isAddMode)"
    }
  }
  
  var body: some View {
    List {
      EmptyView()
    }
      .navigationBarTitle("Networks")
      .toolbar {
        ToolbarItemGroup(placement: .confirmationAction) {
          Button(action: {
            isPresentingNetworkDetails = .init(isAddMode: true)
          }) {
            Label("The title of the add network screen", systemImage: "plus")
              .labelStyle(.iconOnly)
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
      .sheet(item: $isPresentingNetworkDetails) { details in
        NavigationView {
          CustomNetworkDetailsView(
            networkStore: .previewStore,
            isAddMode: details.isAddMode
          )
        }
        .navigationViewStyle(StackNavigationViewStyle())
      }
  }
}

struct CustomNetworksView_Previews: PreviewProvider {
    static var previews: some View {
      CustomNetworksView(networkStore: .previewStore)
    }
}
