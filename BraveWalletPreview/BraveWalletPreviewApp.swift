// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveCore
import BraveShared
import BraveUI
import BraveWallet
import ComposableArchitecture

class AppDelegate: NSObject, UIApplicationDelegate {
  var braveCoreMain: BraveCoreMain = .init(userAgent: "BraveWalletPreview")
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    braveCoreMain.scheduleLowPriorityStartupTasks()
    applyAppearanceDefaults()
    return true
  }
}

extension AppDelegate {
    func applyAppearanceDefaults() {
        UIToolbar.appearance().do {
            $0.tintColor = .braveOrange
            let appearance: UIToolbarAppearance = {
                let appearance = UIToolbarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .braveBackground
                appearance.backgroundEffect = nil
                return appearance
            }()
            $0.standardAppearance = appearance
            $0.compactAppearance = appearance
            #if swift(>=5.5)
            if #available(iOS 15.0, *) {
                $0.scrollEdgeAppearance = appearance
            }
            #endif
        }
        
        UINavigationBar.appearance().do {
            $0.tintColor = .braveOrange
            let appearance: UINavigationBarAppearance = {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.titleTextAttributes = [.foregroundColor: UIColor.braveLabel]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.braveLabel]
                appearance.backgroundColor = .braveBackground
                appearance.backgroundEffect = nil
                return appearance
            }()
            $0.standardAppearance = appearance
            $0.compactAppearance = appearance
            $0.scrollEdgeAppearance = appearance
        }
        
        UISwitch.appearance().onTintColor = UIColor.braveOrange
        
        /// Used as color a table will use as the base (e.g. background)
        let tablePrimaryColor = UIColor.braveGroupedBackground
        /// Used to augment `tablePrimaryColor` above
        let tableSecondaryColor = UIColor.secondaryBraveGroupedBackground
        
        UITableView.appearance().backgroundColor = tablePrimaryColor
        UITableView.appearance().separatorColor = .braveSeparator
        
        UITableViewCell.appearance().do {
            $0.tintColor = .braveOrange
            $0.backgroundColor = tableSecondaryColor
        }
        
        UILabel.appearance(whenContainedInInstancesOf: [UITableView.self]).textColor = .braveLabel
        UILabel.appearance(whenContainedInInstancesOf: [UICollectionReusableView.self])
            .textColor = .braveLabel
        
        UITextField.appearance().textColor = .braveLabel
        
        UISegmentedControl.appearance().do {
            $0.selectedSegmentTintColor = .init(dynamicProvider: {
                if $0.userInterfaceStyle == .dark {
                    return .secondaryButtonTint
                }
                return .white
            })
            $0.backgroundColor = .secondaryBraveBackground
            $0.setTitleTextAttributes([.foregroundColor: UIColor.bravePrimary], for: .selected)
            $0.setTitleTextAttributes([.foregroundColor: UIColor.braveLabel], for: .normal)
        }
    }
}


@main
struct BraveWalletPreviewApp: App {
  @UIApplicationDelegateAdaptor var delegate: AppDelegate
  
  var body: some Scene {
    WindowGroup {
      _WalletHostingController()
    }
  }
}

private struct _WalletHostingController: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> some UIViewController {
    guard
      let keyringController = BraveWallet.KeyringControllerFactory.get(privateMode: false),
      let rpcController = BraveWallet.EthJsonRpcControllerFactory.get(privateMode: false),
      let assetRatioController = BraveWallet.AssetRatioControllerFactory.get(privateMode: false),
      let walletService = BraveWallet.ServiceFactory.get(privateMode: false),
      let swapController = BraveWallet.SwapControllerFactory.get(privateMode: false),
      let txController = BraveWallet.EthTxControllerFactory.get(privateMode: false)
    else {
      fatalError()
    }
    
    let walletStore = WalletStore(
      keyringController: keyringController,
      rpcController: rpcController,
      walletService: walletService,
      assetRatioController: assetRatioController,
      swapController: swapController,
      tokenRegistry: BraveCoreMain.ercTokenRegistry,
      transactionController: txController
    )
    
    let vc = WalletHostingViewController(walletStore: walletStore)
    vc.delegate = context.coordinator
    return vc
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
  }
  
  class Coordinator: BraveWalletDelegate {
    func openWalletURL(_ url: URL) {
      print("Attempted to open \(url)")
    }
  }
}
