// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared

enum BrandedImageCalloutState {
    
    /// Encourage user to enable Brave Rewards to get paid for watching branded images.
    case getPaidTurnRewardsOn
    /// Encourage user to enable Brave Ads to get paid for watching branded images.
    case getPaidTurnAdsOn
    /// Info that user can get paid for watching images after turning Brave Ads on.
    case youCanGetPaidTurnAdsOn
    /// User is eligible for payout for background images
    case gettingPaidAlready
    /// Don't show any callout
    case dontShow
    
    // todo: consider adding enums for image type and ads status(on/off/unavailible)
    
    static func getState(rewardsEnabled: Bool, adsEnabled: Bool, adsAvailableInRegion: Bool,
                         isSponsoredImage: Bool) -> BrandedImageCalloutState {
        
        let wasCalloutShowed = Preferences.NewTabPage.brandedImageShowed.value
        
        // If any of those callouts were shown once, we skip showing any other state.
        if wasCalloutShowed { return .dontShow }
        
        if !rewardsEnabled && isSponsoredImage { return .getPaidTurnRewardsOn }
        
        if rewardsEnabled {
            if !adsAvailableInRegion { return .dontShow }
            
            if adsEnabled && isSponsoredImage { return .gettingPaidAlready }
            
            if !adsEnabled && isSponsoredImage { return .getPaidTurnAdsOn }
            
            if !adsEnabled && !isSponsoredImage { return .youCanGetPaidTurnAdsOn }
        }
        
        return .dontShow
        
    }
    
    /// The initial view controller that is shown to user.
    /// Returns nil of no view controller should be presented
    var initialViewController: TranslucentBottomSheet? {
        let helper = BrandedImageCallout.self
                
        switch self {
        case .getPaidTurnRewardsOn:
            return helper.GetPaidForBrandedImageNonBlockingViewController()
        case .getPaidTurnAdsOn:
            return helper.GetPaidForBrandedImageNonBlockingViewController()
        case .youCanGetPaidTurnAdsOn:
            return helper.SupportWebCreatorsWithTokensView()
        case .gettingPaidAlready:
            return helper.YouAreGettingPaidNonBlockingViewController()
        case .dontShow:
            return nil
        }
    }
    
    /// The view controller that shows after user taps on 'Learn more' button if the current state supports it.
    /// Returns nil if no view controller should be present or there's no button to tap.
    var learnMoreViewController: UIViewController? {
        let helper = BrandedImageCallout.self
        
        switch self {
        case .getPaidTurnRewardsOn:
            return helper.GetPaidForBrandedImageRewardsOffViewController()
        case .getPaidTurnAdsOn:
            return helper.GetPaidForBrandedImageViewController()
        case .youCanGetPaidTurnAdsOn:
            return nil
        case .gettingPaidAlready:
            return helper.YouAreGettingPaidViewController()
        case .dontShow:
            return nil
        }
    }
}
