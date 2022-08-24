// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import Data
import CoreData

public struct PlaylistSharedFolderModel: Codable {
  public let version: String
  public let folderId: String
  public let folderName: String
  public let folderImage: String
  public let creatorName: String
  public let creatorLink: String
  public let updateAt: String
  public var folderUrl: String?
  public var eTag: String?
  public var mediaItems: [PlaylistInfo]
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    version = try container.decode(String.self, forKey: .version)
    folderId = try container.decode(String.self, forKey: .folderId)
    folderName = try container.decode(String.self, forKey: .folderName)
    folderImage = try container.decode(String.self, forKey: .folderImage)
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
    try container.encode(folderId, forKey: .folderId)
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
    case folderId = "folderid"
    case folderName = "foldername"
    case folderImage = "folderimage"
    case creatorName = "creatorname"
    case creatorLink = "creatorlink"
    case updateAt = "updateat"
    case mediaItems = "mediaitems"
  }
}

public struct PlaylistSharedFolderNetwork {
  enum Status: String, Error {
    case invalidURL
    case invalidResponse
    case cacheNotModified
  }
  
  @MainActor
  public static func fetchPlaylist(folderUrl: String) async throws -> PlaylistSharedFolderModel {
    guard let playlistURL = URL(string: folderUrl)?.appendingPathComponent("playlist").appendingPathExtension("json") else {
      throw Status.invalidURL
    }
    
    let authenticator = BasicAuthCredentialsManager(for: Array(DomainUserScript.bravePlaylistFolderSharingHelper.associatedDomains))
    let session = URLSession(configuration: .ephemeral, delegate: authenticator, delegateQueue: .main)
    defer { session.finishTasksAndInvalidate() }
    
    var request = URLRequest(url: playlistURL)
    request.httpMethod = "GET"
    
    if let eTag = PlaylistFolder.getSharedFolder(sharedFolderUrl: folderUrl)?.sharedFolderETag {
      request.setValue(eTag, forHTTPHeaderField: "If-None-Match")
    }
    
    let (data, response) = try await NetworkManager(session: session).dataRequest(with: request)
    guard let response = response as? HTTPURLResponse,
              response.statusCode == 304 || response.statusCode >= 200 || response.statusCode <= 299 else {
      throw Status.invalidResponse
    }
    
    if response.statusCode == 304 {
      throw Status.cacheNotModified
    }
    
    var model = try JSONDecoder().decode(PlaylistSharedFolderModel.self, from: data)
    model.folderUrl = folderUrl
    model.eTag = response.allHeaderFields["ETag"] as? String
    return model
  }
  
  @MainActor
  public static func createInMemoryStorage(for model: PlaylistSharedFolderModel) async -> PlaylistFolder {
    await withCheckedContinuation { continuation in
      // Create a local shared folder
      PlaylistFolder.addInMemoryFolder(title: model.folderName,
                                       creatorName: model.creatorName,
                                       creatorLink: model.creatorLink,
                                       sharedFolderId: model.folderId,
                                       sharedFolderUrl: model.folderUrl,
                                       sharedFolderETag: model.eTag) { folder, folderId in
        // Add the items to the folder
        PlaylistItem.addInMemoryItems(model.mediaItems, folderUUID: folderId) {
          // Items were added
          continuation.resume(returning: folder)
        }
      }
    }
  }
  
  @MainActor
  public static func saveToDiskStorage(memoryFolder: PlaylistFolder) async -> String {
    await withCheckedContinuation({ continuation in
      PlaylistFolder.saveInMemoryFolderToDisk(folder: memoryFolder) { folderId in
        PlaylistItem.saveInMemoryItemsToDisk(items: Array(memoryFolder.playlistItems ?? []), folderUUID: folderId) {
          continuation.resume(returning: folderId)
        }
      }
    })
  }
  
  public static func fetchMediaItemInfo(item: PlaylistSharedFolderModel, viewForInvisibleWebView: UIView) async -> [PlaylistInfo] {
    @Sendable @MainActor
    func fetchTask(item: PlaylistInfo) async -> PlaylistInfo {
      await withCheckedContinuation { continuation in
        var webLoader: PlaylistWebLoader?
        webLoader = PlaylistWebLoader(handler: { newItem in
            if let newItem = newItem {
              PlaylistManager.shared.getAssetDuration(item: newItem) { duration in
                let item = PlaylistInfo(name: item.name,
                                   src: newItem.src,
                                   pageSrc: newItem.pageSrc,
                                   pageTitle: item.pageTitle,
                                   mimeType: newItem.mimeType,
                                   duration: duration ?? newItem.duration,
                                   detected: newItem.detected,
                                   dateAdded: newItem.dateAdded,
                                   tagId: item.tagId)
                
                // Destroy the web loader when the callback is complete.
                webLoader?.removeFromSuperview()
                webLoader = nil
                continuation.resume(returning: item)
              }
            } else {
              // Destroy the web loader when the callback is complete.
              webLoader?.removeFromSuperview()
              webLoader = nil
              continuation.resume(returning: item)
            }
          }
        ).then {
          viewForInvisibleWebView.insertSubview($0, at: 0)
        }

        if let url = URL(string: item.pageSrc) {
          webLoader?.load(url: url)
        } else {
          webLoader = nil
        }
      }
    }

    return await withTaskGroup(of: PlaylistInfo.self, returning: [PlaylistInfo].self) { group in
      item.mediaItems.forEach { item in
        group.addTask {
          return await fetchTask(item: item)
        }
      }
      
      var result = [PlaylistInfo]()
      for await value in group {
        result.append(value)
      }
      return result
    }
  }
}
