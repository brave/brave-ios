// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public enum WalletNotificationAction {
  /// The user clicked the wallet connection notification
  case connectWallet
  /// The user swiped the notification away
  case dismissed
  /// The user ignored the wallet connection notification for a given amount of time for it to automatically dismiss
  case timedOut
}

public class WalletNotification: BraveNotification {
  private struct Constant {
    static let id = "wallet-notification"
  }
  
  public var priority: BraveNotificationPriority
  public var view: UIView
  public var id: String { WalletNotification.Constant.id }
  public var dismissAction: (() -> Void)?
  public var isHorizontalSwipe: Bool = false
  
  private let walletHandler: (WalletNotificationAction) -> Void
  
  public func willDismiss(timedOut: Bool) {
    walletHandler(timedOut ? .timedOut : .dismissed)
  }
  
  public func isSwipeToLeft() -> Bool {
    return false
  }
  
  init(
    priority: BraveNotificationPriority,
    walletHandler: @escaping (WalletNotificationAction) -> Void
  ) {
    self.priority = priority
    self.view = WalletConnectionView()
    self.walletHandler = walletHandler
    self.setup()
  }
  
  private func setup() {
    guard let walletPanel = view as? WalletConnectionView else { return }
    walletPanel.addTarget(self, action: #selector(tappedWalletConnectionView(_:)), for: .touchUpInside)
  }
  
  @objc private func tappedWalletConnectionView(_ sender: WalletConnectionView) {
    dismissAction?()
    walletHandler(.connectWallet)
  }
}
