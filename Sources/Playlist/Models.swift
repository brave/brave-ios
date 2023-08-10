// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data

public struct Playlist: Identifiable, Hashable {
  public var id: String
  public var title: String
  public var items: [Item]
}

extension String {
  static let defaultPlaylistID: Playlist.ID = "7B6CC019-8946-4182-ACE8-42FE7B704C43" // PlaylistFolder.savedFolderUUID
}

public struct Item: Identifiable, Hashable {
  public var id: String
  public var dateAdded: Date
  public var name: String
  public var source: URL
  public var pageSource: URL
  public var duration: TimeInterval
  public var parent: Playlist.ID?
}

// PlaylistInfo
public struct DiscoveredItem: Identifiable, Hashable, Equatable {
  // A unique id for the item discovered on the web page (previously tagId)
  public let id: String
  public let dateAdded: Date
  public let source: URL
  public let pageSource: URL
  public let name: String
  public let pageTitle: String
  public let mimeType: String
  public let duration: TimeInterval
  public let lastPlayedOffset: TimeInterval
  
  public let detected: Bool
  public let isInvisible: Bool
}
