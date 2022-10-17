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
  
  private func shouldRequestReview() -> Bool {
    return true
  }
  
}
