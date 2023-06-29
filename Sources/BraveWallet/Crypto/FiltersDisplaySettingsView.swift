/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import BraveCore
import DesignSystem
import Preferences

enum GroupBy: Equatable, CaseIterable, Identifiable {
  case none
  case accounts
  case networks
  
  var title: String {
    switch self {
    case .none: return "None"
    case .accounts: return "Accounts"
    case .networks: return "Networks"
    }
  }
  var id: String { title }
}

enum SortOrder: Equatable, CaseIterable, Identifiable {
  case ascending
  case descending
  
  var title: String {
    switch self {
    case .ascending: return "Low to High"
    case .descending: return "High to Low"
    }
  }
  var id: String { title }
}

struct Filters {
  /// How the assets should be grouped. Default is none / no grouping.
  let groupBy: GroupBy
  /// Ascending order is smallest fiat to largest fiat. Default is descending order.
  let sortOrder: SortOrder
  /// If we are hiding small balances (less than $1 value). Default is true.
  let isHidingSmallBalances: Bool
  
  /// All accounts and if they are currently selected. Default is all accounts selected.
  var accounts: [Selectable<BraveWallet.AccountInfo>]
  /// All networks and if they are currently selected. Default is all selected except known test networks.
  var networks: [Selectable<BraveWallet.NetworkInfo>]
}

class FiltersDisplaySettingsStore: ObservableObject {
  
  @Published var groupBy: GroupBy = .none
  /// Ascending order is smallest fiat to largest fiat. Default is descending order.
  @Published var sortOrder: SortOrder = .descending
  /// If we are hiding small balances (less than $1 value). Default is true.
  @Published var isHidingSmallBalances: Bool = true
  
  /// All accounts and if they are currently selected. Default is all accounts selected.
  @Published var accounts: [Selectable<BraveWallet.AccountInfo>] = []
  /// All networks and if they are currently selected. Default is all selected except known test networks.
  @Published var networks: [Selectable<BraveWallet.NetworkInfo>] = []
  
  /// Returns true if all accounts are selected
  var allAccountsSelected: Bool {
    accounts.allSatisfy(\.isSelected)
  }
  
  /// Returns true if all visible networks are selected
  var allNetworksSelected: Bool {
    networks
      .filter {
        if !Preferences.Wallet.showTestNetworks.value {
          return !WalletConstants.supportedTestNetworkChainIds.contains($0.model.chainId)
        }
        return true
      }
      .allSatisfy(\.isSelected)
  }
  
  let saveAction: (Filters) -> Void
  
  init(
    filters: Filters,
    saveAction: @escaping (Filters) -> Void
  ) {
    self.sortOrder = filters.sortOrder
    self.isHidingSmallBalances = filters.isHidingSmallBalances
    self.accounts = filters.accounts
    self.networks = filters.networks
    self.saveAction = saveAction
  }
  
  func restoreToDefaults() {
    self.groupBy = .none
    // Descending order (largest fiat to smallest) by default
    self.sortOrder = .descending
    // Small balances hidden by default
    self.isHidingSmallBalances = true
    
    // All accounts selected by default
    self.accounts = self.accounts.map {
      .init(isSelected: true, model: $0.model)
    }
    // All non-test networks selected by default
    self.networks = self.networks.map {
      let isTestnet = WalletConstants.supportedTestNetworkChainIds.contains($0.model.chainId)
      return .init(isSelected: !isTestnet, model: $0.model)
    }
  }
  
  func selectAllAccounts() {
    self.accounts = self.accounts.map {
      .init(isSelected: true, model: $0.model)
    }
  }
  
  func selectAllNetworks() {
    self.networks = self.networks.map {
      .init(isSelected: true, model: $0.model)
    }
  }
}

struct FiltersDisplaySettingsView: View {
  
  @ObservedObject var store: FiltersDisplaySettingsStore
  var keyringStore: KeyringStore
  var networkStore: NetworkStore
  
  @State private var isShowingNetworksDetail: Bool = false
  @Environment(\.dismiss) private var dismiss
  
  /// Size of the circle containing the icon for each filter.
  /// The `relativeTo: .headline` should match icon's `TextStyle` in `FilterLabelView`.
  @ScaledMetric(relativeTo: .headline) private var iconContainerSize: CGFloat = 40
  private var maxIconContainerSize: CGFloat = 80
  private let rowPadding: CGFloat = 16
  
  init(
    store: FiltersDisplaySettingsStore,
    keyringStore: KeyringStore,
    networkStore: NetworkStore
  ) {
    self.store = store
    self.keyringStore = keyringStore
    self.networkStore = networkStore
  }
  
  var body: some View {
    NavigationView {
      ScrollView {
        LazyVStack(spacing: 0) {
          /*
           Disabled until Portfolio supports grouping
          groupBy
            .padding(.vertical, rowPadding)
           */

          sortAssets
            .padding(.vertical, rowPadding)

          hideSmallBalances
            .padding(.vertical, rowPadding)

          DividerLine()

          accountFilters
            .padding(.vertical, rowPadding)

          networkFilters
            .padding(.vertical, rowPadding)

        }
        .padding(.horizontal)
      }
      .background(Color(uiColor: WalletV2Design.containerBackground))
      .safeAreaInset(edge: .bottom, content: {
        saveChangesContainer
      })
      .navigationTitle("Filters and Display Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(action: { store.restoreToDefaults() }) {
            Text("Reset")
              .fontWeight(.semibold)
              .foregroundColor(Color(uiColor: WalletV2Design.textInteractive))
          }
        }
      }
    }
  }
  
  private var groupBy: some View {
    FilterPickerRowView(
      title: "Group By",
      description: "Group assets by",
      icon: .init(
        braveSystemName: "leo.list.bullet-default",
        iconContainerSize: min(iconContainerSize, maxIconContainerSize)
      ),
      allOptions: GroupBy.allCases,
      selection: $store.groupBy
    ) { groupBy in
      Text(groupBy.title)
    }
  }
  
  private var sortAssets: some View {
    FilterPickerRowView(
      title: "Sort Assets",
      description: "Sort by fiat amount",
      icon: .init(
        braveSystemName: "leo.arrow.down",
        iconContainerSize: min(iconContainerSize, maxIconContainerSize)
      ),
      allOptions: SortOrder.allCases,
      selection: $store.sortOrder
    ) { sortOrder in
      Text(sortOrder.title)
    }
  }
  
  private var hideSmallBalances: some View {
    Toggle(isOn: $store.isHidingSmallBalances) {
      FilterLabelView(
        title: "Hide Small Balances",
        description: "Assets with value less than $1",
        icon: .init(
          braveSystemName: "leo.eye.on",
          iconContainerSize: min(iconContainerSize, maxIconContainerSize)
        )
      )
    }
    .tint(Color(.braveBlurpleTint))
  }
  
  private var accountFilters: some View {
    NavigationLink(destination: {
      AccountFilterView(
        accounts: $store.accounts
      )
    }, label: {
      FilterDetailRowView(
        title: "Select Accounts",
        description: "Select accounts to filter by",
        icon: .init(
          braveSystemName: "leo.user.accounts",
          iconContainerSize: iconContainerSize
        ),
        selectionView: {
          if store.allAccountsSelected {
            AllSelectedView(title: "All accounts")
          } else if store.accounts.contains(where: { $0.isSelected }) { // at least 1 selected
            MultipleAccountBlockiesView(
              accountAddresses: store.accounts.filter(\.isSelected).map(\.model.address)
            )
          }
        }
      )
    })
  }
  
  private var networkFilters: some View {
    NavigationLink(destination: {
      NetworkFilterView(
        networks: store.networks,
        networkStore: networkStore,
        showsCancelButton: false,
        requiresSave: false,
        saveAction: { selectedNetworks in
          store.networks = selectedNetworks
        }
      )
    }) {
      FilterDetailRowView(
        title: "Select Networks",
        description: "Select networks to filter by",
        icon: .init(
          braveSystemName: "leo.internet",
          iconContainerSize: iconContainerSize
        ),
        selectionView: {
          if store.allNetworksSelected {
            AllSelectedView(title: "All networks")
          } else if store.networks.contains(where: { $0.isSelected }) { // at least 1 selected
            MultipleNetworkIconsView(
              networks: store.networks.filter(\.isSelected).map(\.model)
            )
          }
        }
      )
    }
  }
  
  private var saveChangesContainer: some View {
    VStack {
      Button(action: {
        let filters = Filters(
          groupBy: store.groupBy,
          sortOrder: store.sortOrder,
          isHidingSmallBalances: store.isHidingSmallBalances,
          accounts: store.accounts,
          networks: store.networks
        )
        store.saveAction(filters)
        dismiss()
      }) {
        Text("Save Changes")
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 4)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
      
      Button(action: { dismiss() }) {
        Text("Cancel")
          .fontWeight(.semibold)
          .foregroundColor(Color(uiColor: WalletV2Design.textInteractive))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 4)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 14)
    .background(
      Color(uiColor: WalletV2Design.containerBackground)
        .ignoresSafeArea()
    )
    .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: -8)
  }
}

#if DEBUG
struct FiltersDisplaySettingsView_Previews: PreviewProvider {
  static var previews: some View {
    FiltersDisplaySettingsView(
      store: .previewStore,
      keyringStore: .previewStore,
      networkStore: .previewStore
    )
  }
}

extension FiltersDisplaySettingsStore {
  static var previewStore: FiltersDisplaySettingsStore {
    FiltersDisplaySettingsStore(
      filters: .init(
        groupBy: .none,
        sortOrder: .descending,
        isHidingSmallBalances: true,
        accounts: [
          .init(isSelected: true, model: .mockEthAccount),
          .init(isSelected: true, model: .mockSolAccount)
        ],
        networks: [
          .init(isSelected: true, model: .mockMainnet),
          .init(isSelected: true, model: .mockSolana),
          .init(isSelected: true, model: .mockPolygon),
          .init(isSelected: false, model: .mockSolanaTestnet),
          .init(isSelected: false, model: .mockGoerli)
        ]
      ),
      saveAction: { _ in }
    )
  }
}
#endif

private struct AllSelectedView: View {
  let title: String
  
  var body: some View {
    Text(title)
      .foregroundColor(Color(uiColor: WalletV2Design.extendedGray50))
      .font(.footnote.weight(.semibold))
      .padding(.horizontal, 2)
      .padding(4)
      .background(Color(uiColor: WalletV2Design.extendedGray20))
      .clipShape(RoundedRectangle(cornerRadius: 6))
  }
}

struct FilterIconInfo {
  let braveSystemName: String
  let iconContainerSize: CGFloat
}

// View with icon, title and description.
private struct FilterLabelView: View {
  
  let title: String
  let description: String
  let icon: FilterIconInfo?
  
  var body: some View {
    HStack {
      if let icon {
        Color(uiColor: WalletV2Design.containerHighlight)
          .clipShape(Circle())
          .frame(width: icon.iconContainerSize, height: icon.iconContainerSize)
          .overlay {
            Image(braveSystemName: icon.braveSystemName)
              .imageScale(.medium)
              .font(.headline)
              .foregroundColor(Color(uiColor: WalletV2Design.iconDefault))
          }
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body.weight(.semibold))
          .foregroundColor(Color(uiColor: WalletV2Design.text01))
        Text(description)
          .font(.footnote)
          .foregroundColor(Color(uiColor: WalletV2Design.textSecondary))
      }
      .multilineTextAlignment(.leading)
    }
  }
}

// `FilterLabelView` with a detail disclosure.
private struct FilterDetailRowView<SelectionView: View>: View {

  let title: String
  let description: String
  let icon: FilterIconInfo?
  @ViewBuilder let selectionView: () -> SelectionView

  var body: some View {
    HStack {
      FilterLabelView(
        title: title,
        description: description,
        icon: icon
      )
      Spacer()
      selectionView()
      Image(systemName: "chevron.right")
        .font(.body.weight(.semibold))
        .foregroundColor(Color(.separator))
    }
  }
}

/// Displays provided options in a context menu allowing a single selection.
struct FilterPickerRowView<T: Equatable & Identifiable & Hashable, Content: View>: View {
  
  let title: String
  let description: String
  let icon: FilterIconInfo?
  
  let allOptions: [T]
  @Binding var selection: T
  let content: (T) -> Content
  
  var body: some View {
    HStack {
      FilterLabelView(
        title: title,
        description: description,
        icon: icon
      )
      Spacer()
      Menu(content: {
        ForEach(allOptions) { option in
          Button(action: { selection = option }) {
            HStack {
              Image(braveSystemName: "leo.check.normal")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .hidden(isHidden: selection.id != option.id)
              content(option)
            }
          }
        }
      }, label: {
        HStack(spacing: 8) {
          content(selection)
          Image(braveSystemName: "leo.carat.down")
        }
      })
      .foregroundColor(Color(WalletV2Design.textInteractive))
    }
  }
}

struct DividerLine: View {
  var body: some View {
    Color(uiColor: WalletV2Design.dividerSubtle)
      .frame(height: 1)
  }
}
