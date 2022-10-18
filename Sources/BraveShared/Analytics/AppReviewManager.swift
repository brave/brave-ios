// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Combine
import Foundation
import Shared
import StoreKit
import UIKit

/// Singleton Manager handles App Review Criteria
public final class AppReviewManager: ObservableObject {
  
  /// A main criteria that should be satisfied before checking sub-criteria
  enum AppReviewMainCriteriaType: CaseIterable {
    case launchCount
    case daysInUse
    case sessionCrash
  }
  
  /// A sub-criteria that should be satisfied if one of the main criterias are valid
  enum AppReviewSubCriteriaType: CaseIterable {
    case numberOfBookmarks
    case paidVPNSubscription
    case walletConnectedDapp
    case numberOfPlaylistItems
    case syncEnabledWithTabSync
  }
  
  @Published public var isReviewRequired = false
  
  // MARK: Lifecycle
  
  public static var shared = AppReviewManager()
  
  // MARK: Review Handler Methods
  
  public func handleAppReview(for currentScene: UIWindowScene?) {
    if AppConstants.buildChannel.isPublic && shouldRequestReview() {
      // Request Review when the main-queue is free or on the next cycle.
      DispatchQueue.main.async {
        guard let windowScene = currentScene else { return }
        SKStoreReviewController.requestReview(in: windowScene)
      }
    }
  }
  
  /// <#Description#>
  /// - Returns: <#description#>
  private func shouldRequestReview() -> Bool {
    var mainCriteriaSatisfied = false
    var subCriteriaSatisfied = false
        
    // One of the main criterias should be met before additional situation can be checked
    for mainCriteria in AppReviewMainCriteriaType.allCases {
      mainCriteriaSatisfied = checkMainCriteriaSatisfied(for: mainCriteria)
      if mainCriteriaSatisfied {
        break
      }
    }
    
    // Additionally if a main criteria is accomplished one of following conditions must also be met
    if mainCriteriaSatisfied {
      // One of the sub criterias also should be satisfied
      for subCriteria in AppReviewSubCriteriaType.allCases {
        subCriteriaSatisfied = checkSubCriteriaSatisfied(for: subCriteria)
        if subCriteriaSatisfied {
          break
        }
      }
    }
    
    return mainCriteriaSatisfied && subCriteriaSatisfied
  }
  
  /// <#Description#>
  /// - Parameter type: <#type description#>
  /// - Returns: <#description#>
  private func checkMainCriteriaSatisfied(for type: AppReviewMainCriteriaType) -> Bool {
    switch type {
    case .launchCount:
      return true
    case .daysInUse:
      return true
    case .sessionCrash:
      return true
    }
  }
  
  /// <#Description#>
  /// - Parameter type: <#type description#>
  /// - Returns: <#description#>
  private func checkSubCriteriaSatisfied(for type: AppReviewSubCriteriaType) -> Bool {
    switch type {
    case .numberOfBookmarks:
      return true
    case .paidVPNSubscription:
      return true
    case .walletConnectedDapp:
      return true
    case .numberOfPlaylistItems:
      return true
    case .syncEnabledWithTabSync:
      return true
    }
  }
}
