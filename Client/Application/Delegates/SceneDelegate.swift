// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import Storage

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    private let crashedLastSession =
        !Preferences.AppState.backgroundedCleanly.value && AppConstants.buildChannel != .debug
    
    var tabManager: TabManager?
    var bvc: BrowserViewController?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene,
              let appDelegate = (UIApplication.shared.delegate as? AppDelegate) else {
            return
        }
        
        tabManager = TabManager(prefs: appDelegate.profile!.prefs, imageStore: appDelegate.imageStore!)
        
        bvc = BrowserViewController(profile: appDelegate.profile!,
                                  tabManager: tabManager!,
                                  crashedLastSession: false,
                                  braveRewardsManager: appDelegate.braveRewardsManager)
        
        guard let bvc = bvc else { return }
        bvc.edgesForExtendedLayout = []

        // Add restoration class, the factory that will return the ViewController we will restore with.
        bvc.restorationIdentifier = NSStringFromClass(BrowserViewController.self)
        //browserViewController.restorationClass = AppDelegate.self
        
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController(rootViewController: bvc)
        navigationController.delegate = self
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        
        window.rootViewController = navigationController
        
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        bvc?.showWalletTransferExpiryPanelIfNeeded()
    }
    
    
}

// MARK: - Root View Controller Animations
extension SceneDelegate: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return BrowserToTrayAnimator()
        case .pop:
            return TrayToBrowserAnimator()
        default:
            return nil
        }
    }
}
