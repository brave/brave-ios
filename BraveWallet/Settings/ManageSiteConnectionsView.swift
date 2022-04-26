// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveUI
import SwiftUI
import struct Shared.Strings

struct ManageSiteConnectionsView: View {

  @ObservedObject var siteConnectionStore: ManageSiteConnectionsStore
  @State private var filterText: String = ""
  @State private var isShowingConfirmAlert: Bool = false
  
  var body: some View {
    List {
      ForEach(siteConnectionStore.siteConnections.filter(by: filterText)) { siteConnection in
        NavigationLink(
          destination: SiteConnectionDetailView(
            siteConnection: siteConnection,
            siteConnectionStore: siteConnectionStore
          )
        ) {
          SiteRow(
            siteConnection: siteConnection
          )
        }
      }
      .onDelete { indexes in
        let visibleSiteConnections = siteConnectionStore.siteConnections.filter(by: filterText)
        let siteConnectionsToRemove = indexes.map { visibleSiteConnections[$0] }
        siteConnectionStore.removeAllPermissions(from: siteConnectionsToRemove)
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Manage Site Connections")
    .navigationBarTitleDisplayMode(.inline)
    .filterable(text: $filterText, prompt: "Filter")
    .toolbar {
      ToolbarItemGroup(placement: .bottomBar) {
        Spacer()
        Button(action: {
          isShowingConfirmAlert = true
        }) {
          Text("Remove All")
            .foregroundColor(siteConnectionStore.siteConnections.isEmpty ? Color(.braveDisabled) : .red)
        }
        .disabled(siteConnectionStore.siteConnections.isEmpty)
      }
    }
    .onAppear(perform: siteConnectionStore.fetchSiteConnections)
    .alert(isPresented: $isShowingConfirmAlert) {
      Alert(
        title: Text("Are you sure you wish to remove all permissions?"),
        message: Text("This will remove all Wallet connection permissions for all websites."), // TODO: copy
        primaryButton: Alert.Button.destructive(
          Text("Remove"),
          action: removeAll
        ),
        secondaryButton: Alert.Button.cancel(Text(Strings.CancelString))
      )
    }
  }
  
  func removeAll() {
    let visibleSiteConnections = siteConnectionStore.siteConnections.filter(by: filterText)
    siteConnectionStore.removeAllPermissions(from: visibleSiteConnections)
    filterText = ""
  }
}

/*
#if DEBUG
struct ManageSiteConnectionsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      ManageSiteConnectionsView(
        siteConnectionStore: .init()
      )
    }
  }
}
#endif
*/
 
private struct SiteRow: View {

  let siteConnection: SiteConnection

  private let maxBlockies = 3
  @ScaledMetric private var blockieSize: CGFloat = 16
  private let maxBlockieSize: CGFloat = 32
  @ScaledMetric private var blockieDotSize: CGFloat = 2
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(verbatim: siteConnection.url)
        .foregroundColor(Color(.bravePrimary))
      HStack {
        if siteConnection.connectedAddresses.count == 1 {
          Text("1 account")
            .foregroundColor(Color(.secondaryBraveLabel))
        } else {
          Text("\(siteConnection.connectedAddresses.count) accounts")
            .foregroundColor(Color(.secondaryBraveLabel))
        }
        accountBlockies
        Spacer()
      }
    }
  }
  
  @ViewBuilder private var accountBlockies: some View {
    if siteConnection.connectedAddresses.isEmpty {
      EmptyView()
    } else {
      HStack(spacing: -(min(blockieSize, maxBlockieSize) / 2)) {
        let numberOfBlockies = min(maxBlockies, siteConnection.connectedAddresses.count)
        ForEach(0..<numberOfBlockies, id: \.self) { index in
          Blockie(address: siteConnection.connectedAddresses[index])
            .frame(width: min(blockieSize, maxBlockieSize), height: min(blockieSize, maxBlockieSize))
            .zIndex(Double(numberOfBlockies - index))
        }
        if siteConnection.connectedAddresses.count > maxBlockies {
          Circle()
            .foregroundColor(Color(.braveBlurple))
            .frame(width: min(blockieSize, maxBlockieSize), height: min(blockieSize, maxBlockieSize))
            .overlay(
              HStack(spacing: 1) {
                Circle()
                  .frame(width: blockieDotSize, height: blockieDotSize)
                Circle()
                  .frame(width: blockieDotSize, height: blockieDotSize)
                Circle()
                  .frame(width: blockieDotSize, height: blockieDotSize)
              }
                .foregroundColor(.white)
            )
        }
      }
    }
  }
}

private struct SiteConnectionDetailView: View {
  
  let siteConnection: SiteConnection
  @ObservedObject var siteConnectionStore: ManageSiteConnectionsStore
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  var body: some View {
    List {
      ForEach(siteConnection.connectedAddresses, id: \.self) { address in
        Text(address)
      }
    }
    .navigationTitle(siteConnection.url)
    .navigationBarTitleDisplayMode(.inline)
  }
}
