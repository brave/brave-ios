// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared

extension Preferences {
  public final class URP {
    static let nextCheckDate = Option<TimeInterval?>(key: "urp.next-check-date", default: nil)
    static let retryCountdown = Option<Int?>(key: "urp.retry-countdown", default: nil)
    static let downloadId = Option<String?>(key: "urp.referral.download-id", default: nil)
    public static let referralCode = Option<String?>(key: "urp.referral.code", default: nil)
    static let referralCodeDeleteDate = Option<TimeInterval?>(key: "urp.referral.delete-date", default: nil)
    /// Whether the ref code lookup has still yet to occur
    public static let referralLookupOutstanding = Option<Bool?>(key: "urp.referral.lookkup-completed", default: nil)
  }

}
