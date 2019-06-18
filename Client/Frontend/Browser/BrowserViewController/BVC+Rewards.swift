// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveRewardsUI
import Data

/// Since BraveRewardsUI is a separate framework, we have to implement Popover conformance here.
extension RewardsPanelController: PopoverContentComponent {
    var extendEdgeIntoArrow: Bool {
        return true
    }
    var isPanToDismissEnabled: Bool {
        return self.visibleViewController === self.viewControllers.first
    }
}

extension BrowserViewController {
    func showBraveRewardsPanel() {
        if UIDevice.current.userInterfaceIdiom != .pad && UIApplication.shared.statusBarOrientation.isLandscape {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        
        guard let url = tabManager.selectedTab?.url else { return }
        let braveRewardsPanel = RewardsPanelController(
            rewards,
            url: url,
            faviconURL: url,
            delegate: self,
            dataSource: self
        )
        
        let popover = PopoverController(contentController: braveRewardsPanel, contentSizeBehavior: .preferredContentSize)
        popover.addsConvenientDismissalMargins = false
        popover.present(from: topToolbar.locationView.rewardsButton, on: self)
    }
}

extension BrowserViewController: RewardsUIDelegate {
    func presentBraveRewardsController(_ controller: UIViewController) {
        
    }
    
    func loadNewTabWithURL(_ url: URL) {
        
    }
}

extension BrowserViewController: RewardsDataSource {
    func displayString(for url: URL) -> String? {
        return url.host
    }
    
    func retrieveFavicon(with url: URL, completion: @escaping (UIImage?) -> Void) {
        let favicon = UIImageView()
        DispatchQueue.main.async {
            favicon.setIconMO(nil, forURL: url, completed: { (color, url) in
                completion(favicon.image)
            })
        }

    }
    
}
