// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import Preferences
import Shared

// MARK: - PlayListSide

enum PlayListSide: String, CaseIterable {
  case left
  case right
}

// MARK: - PlayListDownloadType

enum PlayListDownloadType: String, CaseIterable {
  case on
  case off
  case wifi
}

extension Preferences {
  final public class Playlist {
    /// The Option to show video list left or right side
    static let listViewSide = Option<String>(key: "playlist.listViewSide", default: PlayListSide.left.rawValue)
    /// The count of how many times  Add to Playlist URL-Bar onboarding has been shown
    static let addToPlaylistURLBarOnboardingCount = Option<Int>(key: "playlist.addToPlaylistURLBarOnboardingCount", default: 0)
    /// The last played item url
    static let lastPlayedItemUrl = Option<String?>(key: "playlist.last.played.item.url", default: nil)
    /// The last played item time
    static let lastPlayedItemTime = Option<Double>(key: "playlist.last.played.item.time", default: 0.0)
    /// Whether to play the video when controller loaded
    static let firstLoadAutoPlay = Option<Bool>(key: "playlist.firstLoadAutoPlay", default: false)
    /// The Option to download video yes / no / only wi-fi
    static let autoDownloadVideo = Option<String>(key: "playlist.autoDownload", default: PlayListDownloadType.on.rawValue)
    /// The Option to disable playlist MediaSource web-compatibility
    static let webMediaSourceCompatibility = Option<Bool>(key: "playlist.webMediaSourceCompatibility", default: UIDevice.isIpad)
    /// The option to start the playback where user left-off
    static let playbackLeftOff = Option<Bool>(key: "playlist.playbackLeftOff", default: true)
    /// The option to disable long-press-to-add-to-playlist gesture.
    static let enableLongPressAddToPlaylist =
    Option<Bool>(key: "playlist.longPressAddToPlaylist", default: true)
    /// The option to enable or disable the 3-dot menu badge for playlist
    static let enablePlaylistMenuBadge =
    Option<Bool>(key: "playlist.enablePlaylistMenuBadge", default: true)
    /// The option to enable or disable the URL-Bar button for playlist
    static let enablePlaylistURLBarButton =
    Option<Bool>(key: "playlist.enablePlaylistURLBarButton", default: true)
    /// The option to enable or disable the continue where left-off playback in CarPlay
    static let enableCarPlayRestartPlayback =
    Option<Bool>(key: "playlist.enableCarPlayRestartPlayback", default: false)
    /// The last time all playlist folders were synced
    static let lastPlaylistFoldersSyncTime =
    Option<Date?>(key: "playlist.lastPlaylistFoldersSyncTime", default: nil)
    /// Sync shared folders automatically preference
    static let syncSharedFoldersAutomatically =
    Option<Bool>(key: "playlist.syncSharedFoldersAutomatically", default: true)
  }
}
