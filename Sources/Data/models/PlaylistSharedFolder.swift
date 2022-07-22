// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct PlaylistSharedFolderModel: Codable {
  public let version: String
  public let playlistId: String
  public let folderName: String
  public let folderImage: URL
  public let creatorName: String
  public let creatorLink: String
  public let updateAt: String
  public var mediaItems: [PlaylistInfo]
  
  public init(playlistId: String) {
    version = "1"
    self.playlistId = playlistId
    folderName = ""
    folderImage = NSURL() as URL
    creatorName = ""
    creatorLink = ""
    updateAt = ""
    mediaItems = []
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    version = try container.decode(String.self, forKey: .version)
    playlistId = try container.decode(String.self, forKey: .playlistId)
    folderName = try container.decode(String.self, forKey: .folderName)
    folderImage = try container.decode(URL.self, forKey: .folderImage)
    creatorName = try container.decode(String.self, forKey: .creatorName)
    creatorLink = try container.decode(String.self, forKey: .creatorLink)
    updateAt = try container.decode(String.self, forKey: .updateAt)
    mediaItems = try container.decode([MediaItem].self, forKey: .mediaItems).map { item in
      PlaylistInfo(name: item.title, src: item.url.absoluteString, pageSrc: item.url.absoluteString, pageTitle: item.title, mimeType: "video", duration: 0.0, detected: true, dateAdded: Date(), tagId: item.mediaItemId)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(version, forKey: .version)
    try container.encode(playlistId, forKey: .playlistId)
    try container.encode(folderName, forKey: .folderName)
    try container.encode(folderImage, forKey: .folderImage)
    try container.encode(creatorName, forKey: .creatorName)
    try container.encode(creatorLink, forKey: .creatorLink)
    try container.encode(updateAt, forKey: .updateAt)
    
    let items = mediaItems.compactMap({ item -> MediaItem? in
      guard let url = URL(string: item.pageSrc) else { return nil }
      return MediaItem(mediaItemId: item.tagId.isEmpty ? UUID().uuidString : item.tagId,
                title: item.pageTitle,
                url: url)
    })
    
    try container.encode(items, forKey: .mediaItems)
  }
  
  private struct MediaItem: Codable {
    public init() {
      mediaItemId = UUID().uuidString
      title = ""
      url = NSURL() as URL
    }
    
    public init(mediaItemId: String, title: String, url: URL) {
      self.mediaItemId = mediaItemId
      self.title = title
      self.url = url
    }
    
    public let mediaItemId: String
    public let title: String
    public let url: URL
    
    private enum CodingKeys: String, CodingKey {
      case mediaItemId = "mediaitemid"
      case title
      case url
    }
  }
  
  private enum CodingKeys: String, CodingKey {
    case version
    case playlistId
    case folderName = "foldername"
    case folderImage = "folderimage"
    case creatorName = "creatorname"
    case creatorLink = "creatorlink"
    case updateAt = "updateat"
    case mediaItems = "mediaitems"
  }
}
