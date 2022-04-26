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
          .osAvailabilityModifiers { content in
            if #available(iOS 15.0, *) {
              content
                .modifier(
                  SwipeActionsViewModifier_FB9812596 {
                    withAnimation {
                      siteConnectionStore.removeAllPermissions(from: [siteConnection])
                    }
                  })
            } else {
              content
            }
          }
        }
      }
      .onDelete { indexes in
        let visibleSiteConnections = siteConnectionStore.siteConnections.filter(by: filterText)
        let siteConnectionsToRemove = indexes.map { visibleSiteConnections[$0] }
        withAnimation {
          siteConnectionStore.removeAllPermissions(from: siteConnectionsToRemove)
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle(Strings.Wallet.mangeSiteConnectionsTitle)
    .navigationBarTitleDisplayMode(.inline)
    .filterable(text: $filterText, prompt: Strings.Wallet.mangeSiteConnectionsFilterPlaceholder)
    .toolbar {
      ToolbarItemGroup(placement: .bottomBar) {
        Spacer()
        Button(action: {
          isShowingConfirmAlert = true
        }) {
          Text(Strings.Wallet.mangeSiteConnectionsRemoveAll)
            .foregroundColor(siteConnectionStore.siteConnections.isEmpty ? Color(.braveDisabled) : .red)
        }
        .disabled(siteConnectionStore.siteConnections.isEmpty)
      }
    }
    .onAppear(perform: siteConnectionStore.fetchSiteConnections)
    .alert(isPresented: $isShowingConfirmAlert) {
      Alert(
        title: Text(Strings.Wallet.mangeSiteConnectionsConfirmAlertTitle),
        message: Text(Strings.Wallet.mangeSiteConnectionsConfirmAlertMessage),
        primaryButton: Alert.Button.destructive(
          Text(Strings.Wallet.mangeSiteConnectionsConfirmAlertRemove),
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
        Text(String.localizedStringWithFormat(Strings.Wallet.manageSiteConnectionsAccount, siteConnection.connectedAddresses.count, siteConnection.connectedAddresses.count == 1 ? Strings.Wallet.manageSiteConnectionsAccountSingular : Strings.Wallet.manageSiteConnectionsAccountPlural))
          .foregroundColor(Color(.secondaryBraveLabel))
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

// Modifier workaround for FB9812596 to avoid crashing on iOS 14 on Release builds
@available(iOS 15.0, *)
private struct SwipeActionsViewModifier_FB9812596: ViewModifier {
  var action: () -> Void
  
  func body(content: Content) -> some View {
    content
      .swipeActions(edge: .trailing) {
        Button(role: .destructive, action: action) {
          Label(Strings.Wallet.delete, systemImage: "trash")
        }
      }
  }
}

private struct SiteConnectionDetailView: View {
  
  let siteConnection: SiteConnection
  @ObservedObject var siteConnectionStore: ManageSiteConnectionsStore
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  @State private var isShowingConfirmAlert = false
  
  var body: some View {
    List {
      Section(header: Text(Strings.Wallet.manageSiteConnectionsDetailHeader)) {
        ForEach(siteConnection.connectedAddresses, id: \.self) { address in
          AccountView(address: address, name: siteConnectionStore.accountInfo(for: address)?.name ?? "")
            .osAvailabilityModifiers { content in
              if #available(iOS 15.0, *) {
                content
                  .modifier(
                    SwipeActionsViewModifier_FB9812596 {
                      withAnimation(.default) {
                        if let url = URL(string: siteConnection.url) {
                          siteConnectionStore.removePermissions(from: [address], url: url)
                        }
                      }
                    })
              } else {
                content
              }
            }
        }
        .onDelete { indexSet in
          let addressesToRemove = indexSet.map({ siteConnection.connectedAddresses[$0] })
          withAnimation(.default) {
            if let url = URL(string: siteConnection.url) {
              siteConnectionStore.removePermissions(from: addressesToRemove, url: url)
            }
          }
        }
      }
    }
    .navigationTitle(siteConnection.url)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .bottomBar) {
        Spacer()
        Button(action: {
          isShowingConfirmAlert = true
        }) {
          Text(Strings.Wallet.mangeSiteConnectionsRemoveAll)
            .foregroundColor(siteConnectionStore.siteConnections.isEmpty ? Color(.braveDisabled) : .red)
        }
      }
    }
    .alert(isPresented: $isShowingConfirmAlert) {
      Alert(
        title: Text(Strings.Wallet.mangeSiteConnectionsConfirmAlertTitle),
        message: Text(Strings.Wallet.mangeSiteConnectionsDetailConfirmAlertMessage),
        primaryButton: Alert.Button.destructive(
          Text(Strings.Wallet.mangeSiteConnectionsConfirmAlertRemove),
          action: {
            siteConnectionStore.removeAllPermissions(from: [siteConnection])
          }
        ),
        secondaryButton: Alert.Button.cancel(Text(Strings.CancelString))
      )
    }
  }
}
