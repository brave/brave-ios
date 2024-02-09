// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
@_exported import Strings

extension Strings {
  public struct AIChat {
    public static let contextLimitErrorTitle = NSLocalizedString(
      "wallet.contextLimitErrorTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "This conversation is too long and cannot continue.\nThere may be other models available with which Leo is capable of maintaining accuracy for longer conversations.",
      comment: "The title shown on limit reached error view, which is suggesting user to change default model"
    )
    public static let newChatActionTitle = NSLocalizedString(
      "wallet.newChatActionTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "New Chat",
      comment: "The title for button that starts a new chat"
    )
    public static let networkErrorViewTitle = NSLocalizedString(
      "wallet.networkErrorViewTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "There was a network issue connecting to Leo, check your connection and try again.",
      comment: "The title for view that shows network - connection error and suggesting to try again"
    )
    public static let retryActionTitle = NSLocalizedString(
      "wallet.retryActionTitle",
      tableName: "BraveLeo",
      bundle: .module,
      value: "Retry",
      comment: "The title for button for re-try"
    )
  }
}
