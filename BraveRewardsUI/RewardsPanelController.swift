/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import BraveRewards

public class RewardsPanelController: PopoverNavigationController {
  
  public enum InitialPage {
    case `default`
    case settings
  }

  public static let batLogoImage = UIImage(frameworkResourceNamed: "bat-small")
  
  public init(_ rewards: BraveRewards, tabId: UInt64, url: URL, faviconURL: URL?, pageHTML: String? = nil, delegate: RewardsUIDelegate, dataSource: RewardsDataSource, initialPage: InitialPage = .default) {
    super.init()
    
    let state = RewardsState(ledger: rewards.ledger, ads: rewards.ads, tabId: tabId, url: url, faviconURL: faviconURL, delegate: delegate, dataSource: dataSource)
    
    if !rewards.ledger.isWalletCreated {
      viewControllers = [CreateWalletViewController(state: state)]
    } else {
      var vcs: [UIViewController] = [WalletViewController(state: state)]
      if initialPage == .settings {
        vcs.append(SettingsViewController(state: state))
      }
      viewControllers = vcs
    }
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationBar.appearanceBarTintColor = navigationBar.barTintColor
    navigationBar.tintColor = Colors.blurple400
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
    
    toolbar.appearanceBarTintColor = toolbar.barTintColor
    toolbar.tintColor = Colors.blurple400
    
    if #available(iOS 13.0, *) {
      overrideUserInterfaceStyle = .light
    }
  }
}
