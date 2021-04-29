// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import Storage
import SwiftKeychainWrapper
import CoreSpotlight

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    var authenticator: AppAuthenticator?
    
    // Don't track crashes if we're building the development environment due to the fact that terminating/stopping
    // the simulator via Xcode will count as a "crash" and lead to restore popups in the subsequent launch
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
                                  braveRewardsManager: appDelegate.braveRewardsManager,
                                  backgroundDataSource: appDelegate.backgroundDataSource,
                                  feedDataSource: appDelegate.feedDataSource)
        
        guard let bvc = bvc else { return }
        bvc.edgesForExtendedLayout = []

        // Add restoration class, the factory that will return the ViewController we will restore with.
        bvc.restorationIdentifier = NSStringFromClass(BrowserViewController.self)
        bvc.restorationClass = SceneDelegate.self
        
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController(rootViewController: bvc)
        navigationController.delegate = self
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        
        window.rootViewController = navigationController
        
        self.window = window
        window.makeKeyAndVisible()
        
        SceneObserver.setupApplication(window: window)
        authenticator = AppAuthenticator(protectedWindow: window, promptImmediately: true, isPasscodeEntryCancellable: false)
        
        bvc.removeScheduledAdGrantReminders()
        
        // fix
        //bvc.shouldShowIntroScreen =
          //  DefaultBrowserIntroManager.prepareAndShowIfNeeded(isNewUser: isFirstLaunch)
    }
    
    // MARK: - Lifecycle
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        authenticator?.hideBackgroundedBlur()
        
        // handle quick actions is available
        let quickActions = QuickActions.sharedInstance
        if let shortcut = quickActions.launchedShortcutItem, let bvc = bvc {
            // dispatch asynchronously so that BVC is all set up for handling new tabs
            // when we try and open them
            quickActions.handleShortCutItem(shortcut, withBrowserViewController: bvc)
            quickActions.launchedShortcutItem = nil
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        if let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo(), authInfo.isPasscodeRequiredImmediately {
            authenticator?.willEnterForeground()
        }
        
        bvc?.showWalletTransferExpiryPanelIfNeeded()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if KeychainWrapper.sharedAppContainerKeychain.authenticationInfo() != nil {
            authenticator?.showBackgroundBlur()
        }
    }
    
    // MARK: - Navigation
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url, let routerpath = NavigationPath(url: url) else {
            return
        }
        bvc?.handleNavigationPath(path: routerpath)
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let bvc = bvc else { return }
        
        let handledShortCutItem = QuickActions.sharedInstance
            .handleShortCutItem(shortcutItem, withBrowserViewController: bvc)
        
        completionHandler(handledShortCutItem)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo,
                let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                let url = URL(string: urlString) {
                bvc?.switchToTabForURLOrOpen(url, isPrivileged: true)
            }
        }
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

extension SceneDelegate: UIViewControllerRestoration {
    public static func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        return nil
    }
}
