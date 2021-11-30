/* Copyright 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SwiftUI
import BraveCore
import PanModal
import BraveUI
import struct Shared.Strings

struct CryptoPagesView: View {
  var walletStore: WalletStore
  @ObservedObject var cryptoStore: CryptoStore
  @ObservedObject var keyringStore: KeyringStore
  
  @State private var isShowingSettings: Bool = false
  @State private var isShowingSearch: Bool = false
  @State private var fetchedUnapprovedTransactionsThisSession: Bool = false
  
  var body: some View {
    _CryptoPagesView(
      walletStore: walletStore,
      cryptoStore: cryptoStore,
      isShowingTransactions: $cryptoStore.isPresentingTransactionConfirmations,
      isConfirmationsButtonVisible: !cryptoStore.unapprovedTransactions.isEmpty
    )
      .onAppear {
        // If a user chooses not to confirm/reject their transactions we shouldn't
        // do it again until they close and re-open wallet
        if !fetchedUnapprovedTransactionsThisSession {
          // Give the animation time
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fetchedUnapprovedTransactionsThisSession = true
            self.cryptoStore.fetchUnapprovedTransactions()
          }
        }
      }
      .ignoresSafeArea()
      .navigationTitle(Strings.Wallet.cryptoTitle)
      .navigationBarTitleDisplayMode(.inline)
      .introspectViewController(customize: { vc in
        vc.navigationItem.do {
          let appearance: UINavigationBarAppearance = {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.braveLabel]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.braveLabel]
            appearance.backgroundColor = .braveBackground
            appearance.shadowColor = .clear
            return appearance
          }()
          $0.standardAppearance = appearance
          $0.compactAppearance = appearance
          $0.scrollEdgeAppearance = appearance
        }
      })
      .background(
        NavigationLink(
          destination: WalletSettingsView(keyringStore: keyringStore),
          isActive: $isShowingSettings
        ) {
          Text(Strings.Wallet.settings)
        }
          .hidden()
      )
      .background(
        Color.clear
          .sheet(isPresented: $isShowingSearch) {
            AssetSearchView(
              walletStore: walletStore,
              cryptoStore: cryptoStore
            )
          }
      )
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button(action: {
            isShowingSearch = true
          }) {
            Label(Strings.Wallet.searchTitle, systemImage: "magnifyingglass")
              .labelStyle(.iconOnly)
              .foregroundColor(Color(.braveOrange))
          }
          Menu {
            Button(action: {
              walletStore.keyringStore.lock()
            }) {
              Label(Strings.Wallet.lock, image: "brave.lock")
                .imageScale(.medium) // Menu inside nav bar implicitly gets large
            }
            Divider()
            Button(action: { isShowingSettings = true }) {
              Label(Strings.Wallet.settings, image: "brave.gear")
                .imageScale(.medium) // Menu inside nav bar implicitly gets large
            }
          } label: {
            Label(Strings.Wallet.otherWalletActionsAccessibilityTitle, systemImage: "ellipsis.circle")
              .labelStyle(.iconOnly)
              .osAvailabilityModifiers { content in
                if #available(iOS 15.0, *) {
                  content
                } else {
                  // iOS 14 does not correctly apply a large image scale to a `Menu`s label inside of a
                  // `ToolbarItemGroup` like it does with a `Button` using `DefaultButtonStyle`
                  content
                    .imageScale(.large)
                }
              }
              .foregroundColor(Color(.braveOrange))
          }
        }
    }
  }
  
  private struct _CryptoPagesView: UIViewControllerRepresentable {
    var walletStore: WalletStore
    var cryptoStore: CryptoStore
    var isShowingTransactions: Binding<Bool>
    var isConfirmationsButtonVisible: Bool
    
    func makeUIViewController(context: Context) -> CryptoPagesViewController {
      CryptoPagesViewController(
        walletStore: walletStore,
        cryptoStore: cryptoStore,
        buySendSwapDestination: context.environment.buySendSwapDestination,
        isShowingTransactions: isShowingTransactions
      )
    }
    func updateUIViewController(_ uiViewController: CryptoPagesViewController, context: Context) {
      uiViewController.confirmationsButton.isHidden = !isConfirmationsButtonVisible
    }
  }
}

private class CryptoPagesViewController: TabbedPageViewController {
  private let walletStore: WalletStore
  private let cryptoStore: CryptoStore
  private let swapButton = SwapButton()
  let confirmationsButton = ConfirmationsButton()
  
  @Binding private var buySendSwapDestination: BuySendSwapDestination?
  @Binding private var isShowingTransactions: Bool
  
  init(
    walletStore: WalletStore,
    cryptoStore: CryptoStore,
    buySendSwapDestination: Binding<BuySendSwapDestination?>,
    isShowingTransactions: Binding<Bool>
  ) {
    self.walletStore = walletStore
    self.cryptoStore = cryptoStore
    self._buySendSwapDestination = buySendSwapDestination
    self._isShowingTransactions = isShowingTransactions
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = Strings.Wallet.cryptoTitle
    navigationItem.largeTitleDisplayMode = .never
    view.backgroundColor = .braveGroupedBackground
    
    pages = [
      UIHostingController(rootView: PortfolioView(
        cryptoStore: cryptoStore,
        keyringStore: walletStore.keyringStore,
        networkStore: cryptoStore.networkStore,
        portfolioStore: cryptoStore.portfolioStore
      )).then {
        $0.title = Strings.Wallet.portfolioPageTitle
      },
      UIHostingController(rootView: AccountsView(
        cryptoStore: cryptoStore,
        keyringStore: walletStore.keyringStore
      )).then {
        $0.title = Strings.Wallet.accountsPageTitle
      }
    ]
    
    view.addSubview(swapButton)
    swapButton.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.bottom.equalTo(view.safeAreaLayoutGuide).priority(.high)
      $0.bottom.lessThanOrEqualTo(view).inset(8)
    }
    
    pages.forEach {
      $0.additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: swapButton.intrinsicContentSize.height + 8, right: 0)
    }
    
    swapButton.addTarget(self, action: #selector(tappedSwapButton), for: .touchUpInside)
    
    view.addSubview(confirmationsButton)
    confirmationsButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(16)
      $0.centerY.equalTo(swapButton)
      $0.bottom.lessThanOrEqualTo(view).inset(8)
    }
    confirmationsButton.addTarget(self, action: #selector(tappedConfirmationsButton), for: .touchUpInside)
  }
  
  @objc private func tappedConfirmationsButton() {
    isShowingTransactions = true
  }
  
  @objc private func tappedSwapButton() {
    let controller = FixedHeightHostingPanModalController(
      rootView: BuySendSwapView(action: { [weak self] destination in
        self?.dismiss(animated: true, completion: {
          self?.buySendSwapDestination = destination
        })
      })
    )
    presentPanModal(
      controller,
      sourceView: swapButton,
      sourceRect: swapButton.bounds
    )
  }
}

private class ConfirmationsButton: SpringButton {
  private let imageView = UIImageView(
    image: UIImage(imageLiteralResourceName: "brave.bell.badge")
      .applyingSymbolConfiguration(.init(pointSize: 18))
  ).then {
    $0.tintColor = .white
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = .braveBlurpleTint
    addSubview(imageView)
    
    imageView.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
    snp.makeConstraints {
      $0.width.equalTo(snp.height)
    }
    
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = .init(width: 0, height: 1)
    layer.shadowRadius = 1
    layer.shadowOpacity = 0.3
    
    accessibilityLabel = Strings.Wallet.confirmTransactionsTitle
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = bounds.height / 2.0
    layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
  }
  
  override var intrinsicContentSize: CGSize {
    .init(width: 36, height: 36)
  }
}
