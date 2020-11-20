// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import BraveShared

class NewTabPageNotifications {
    /// Different types of notifications can be presented to users.
    enum NotificationType {
        /// Notification to inform the user about branded images program.
        case brandedImages(state: BrandedImageCalloutState)
    }
    
    private let rewards: BraveRewards
    
    init(rewards: BraveRewards) {
        self.rewards = rewards
    }
    
    func notificationToShow(isShowingBackgroundImage: Bool,
                            isShowingSponseredImage: Bool) -> NotificationType? {
        let isRewardsEnabled = rewards.ledger.isEnabled
        
        if !isShowingBackgroundImage {
            return nil
        }
        
        let state = BrandedImageCalloutState.getState(
            rewardsEnabled: isRewardsEnabled,
            adsEnabled: rewards.ads.isEnabled,
            adsAvailableInRegion: BraveAds.isCurrentLocaleSupported(),
            isSponsoredImage: isShowingSponseredImage
        )
        return .brandedImages(state: state)
    }
}
