// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data

extension Playlist {
  static func from(folder: PlaylistFolder) -> Self {
    .init(id: folder.id, title: folder.title ?? "", items: (folder.playlistItems ?? []).map({ .from(item: $0) }))
  }
}

extension Item {
  static func from(item: PlaylistItem) -> Self {
    .init(
      id: item.id,
      dateAdded: item.dateAdded,
      name: item.name,
      source: URL(string: item.mediaSrc)!,
      pageSource: URL(string: item.pageSrc)!,
      duration: item.duration,
      parent: item.playlistFolder?.id
    )
  }
}

extension PlaylistService.Storage where Element == Playlist {
  public static var coreData: PlaylistService.Storage<Playlist> {
    .init(
      create: { playlist in
        await withCheckedContinuation { c in
          PlaylistFolder.addFolder(title: playlist.title, uuid: playlist.id) { uuid in
            c.resume(returning: uuid)
          }
        }
      },
      readMany: {
        let frc = PlaylistFolder.frc(savedFolder: true, sharedFolders: true)
        do {
          try frc.performFetch()
          return (frc.fetchedObjects ?? []).map(Playlist.from)
        } catch {
          return []
        }
      },
      readOne: { id in
        return PlaylistFolder.getFolder(uuid: id).map(Playlist.from)
      },
      update: { playlist in
        guard let id = PlaylistFolder.getFolder(uuid: playlist.id)?.objectID else { return }
        PlaylistFolder.updateFolder(folderID: id) { result in
          if case .success(let folder) = result {
            folder.title = playlist.title
          }
        }
        //        folder.order = Int32(playlist.order) // Derive order from list?
        
        // Shared folder stuff
        //        folder.sharedFolderId = playlist.sharedFolderId
        //        folder.sharedFolderUrl = playlist.sharedFolderUrl
        //        folder.sharedFolderETag = playlist.sharedFolderETag
        //        folder.creatorName = playlist.creatorName
        //        folder.creatorLink = playlist.creatorLink
      },
      delete: { playlistID in
        await withCheckedContinuation { c in
          PlaylistFolder.removeFolder(playlistID, completion: {
            c.resume()
          })
        }
      }
    )
  }
}

extension PlaylistService.Storage where Element == Item {
  public static var coreData: PlaylistService.Storage<Item> {
    .init(
      create: { item in
        await withCheckedContinuation { c in
          PlaylistItem.addItem(item.info, folderUUID: item.parent, cachedData: nil)
        }
      },
      readMany: {
        return PlaylistItem.all().map(Item.from)
      },
      readOne: { id in
        return PlaylistItem.getItem(uuid: id).map(Item.from)
      },
      update: { item in
        await withCheckedContinuation { c in
          PlaylistItem.updateItem(item.info) {
            c.resume()
          }
        }
      },
      delete: { id in
        await withCheckedContinuation { c in
          PlaylistItem.removeItem(uuid: id) {
            c.resume()
          }
        }
      }
    )
  }
}

extension Item {
  public var info: PlaylistInfo {
    // FIXME: Remove PlaylistInfo, add method to add item directly
    return PlaylistInfo(
      name: name,
      src: source.absoluteString,
      pageSrc: pageSource.absoluteString,
      pageTitle: "",
      mimeType: "",
      duration: duration,
      lastPlayedOffset: 0,
      detected: false,
      dateAdded: dateAdded,
      tagId: "",
      order: 0,
      isInvisible: false
    )
  }
}

