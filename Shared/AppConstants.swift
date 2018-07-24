/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public enum AppBuildChannel: String {
    case release = "release"
    case beta = "beta"
    case developer = "developer"
}

public enum KVOConstants: String {
    case loading = "loading"
    case estimatedProgress = "estimatedProgress"
    case URL = "URL"
    case title = "title"
    case canGoBack = "canGoBack"
    case canGoForward = "canGoForward"
    case contentSize = "contentSize"
}

public struct AppConstants {
    public static let IsRunningTest = NSClassFromString("XCTestCase") != nil || ProcessInfo.processInfo.arguments.contains(LaunchArguments.Test)

    /// Build Channel.
    public static let BuildChannel: AppBuildChannel = {
        #if MOZ_CHANNEL_RELEASE
            return AppBuildChannel.release
        #elseif MOZ_CHANNEL_BETA
            return AppBuildChannel.beta
        #elseif MOZ_CHANNEL_FENNEC
            return AppBuildChannel.developer
        #endif
    }()

    public static let scheme: String = {
        guard let identifier = Bundle.main.bundleIdentifier else {
            return "unknown"
        }

        let scheme = identifier.replacingOccurrences(of: "com.brave.ios.", with: "")
        if scheme == "FirefoxNightly.enterprise" {
            return "FirefoxNightly"
        }
        return scheme
    }()

    public static let PrefSendUsageData = "settings.sendUsageData"

    /// Whether we just mirror (false) or actively do a full bookmark merge and upload (true).
    public static var shouldMergeBookmarks = false

    /// Should we send a repair request to other clients when the bookmarks buffer validation fails.
    public static let MOZ_BOOKMARKS_REPAIR_REQUEST: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    /// Enables support for International Domain Names (IDN)
    /// Disabled because of https://bugzilla.mozilla.org/show_bug.cgi?id=1312294
    public static let MOZ_PUNYCODE: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return false
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    /// The maximum length of a URL stored by Firefox. Shared with Places on desktop.
    public static let DB_URL_LENGTH_MAX = 65536

    /// The maximum length of a page title stored by Firefox. Shared with Places on desktop.
    public static let DB_TITLE_LENGTH_MAX = 4096

    /// The maximum length of a bookmark description stored by Firefox. Shared with Places on desktop.
    public static let DB_DESCRIPTION_LENGTH_MAX = 1024
}
