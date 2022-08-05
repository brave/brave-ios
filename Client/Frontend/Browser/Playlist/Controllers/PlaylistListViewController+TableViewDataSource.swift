// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SwiftUI
import AVKit
import AVFoundation
import Data
import Shared
import BraveUI

private let log = Logger.browserLogger

// MARK: UITableViewDataSource

extension PlaylistListViewController: UITableViewDataSource {
  private static let formatter = DateComponentsFormatter().then {
    $0.allowedUnits = [.day, .hour, .minute, .second]
    $0.unitsStyle = .abbreviated
    $0.maximumUnitCount = 2
  }

  func getAssetDurationFormatted(item: PlaylistInfo, _ completion: @escaping (String) -> Void) {
    PlaylistManager.shared.getAssetDuration(item: item) { duration in
      let domain = URL(string: item.pageSrc)?.baseDomain ?? "0s"
      if let duration = duration {
        if duration.isInfinite {
          // Live video/audio
          completion(Strings.PlayList.playlistLiveMediaStream)
        } else if abs(duration.distance(to: 0.0)) > 0.00001 {
          completion(Self.formatter.string(from: duration) ?? domain)
        } else {
          completion(domain)
        }
      } else {
        // Media Item is expired or some sort of error occurred retrieving its duration
        // Whatever the reason, we mark it as expired now
        completion(Strings.PlayList.expiredLabelTitle)
      }
    }
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    true
  }

  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    !tableView.isEditing
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    PlaylistManager.shared.currentFolder == nil ? Constants.tableRedactedCellCount : PlaylistManager.shared.numberOfAssets
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    Constants.tableRowHeight
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    UITableView.automaticDimension
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    Constants.tableHeaderHeight
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if PlaylistManager.shared.currentFolder == nil {
      guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.playlistCellRedactedIdentifier, for: indexPath) as? PlaylistCellRedacted else {
        return UITableViewCell()
      }

      return cell
    }
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.playListCellIdentifier, for: indexPath) as? PlaylistCell else {
      return UITableViewCell()
    }

    return cell
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let cell = cell as? PlaylistCell,
          let item = PlaylistManager.shared.itemAtIndex(indexPath.row)
    else {
      return
    }

    cell.prepareForDisplay()
    let domain = URL(string: item.pageSrc)?.baseDomain ?? "0s"

    cell.do {
      $0.showsReorderControl = false
      $0.titleLabel.text = item.name
      $0.detailLabel.text = domain
      $0.contentView.backgroundColor = .clear
      $0.backgroundColor = .clear
      $0.thumbnailView.image = nil
      $0.thumbnailView.backgroundColor = .black
      $0.selectedBackgroundView = UIView().then {
        $0.backgroundColor = .tertiaryBraveBackground
      }
    }

    let cacheState = PlaylistManager.shared.state(for: item.tagId)
    self.updateCellDownloadStatus(
      indexPath: indexPath,
      cell: cell,
      state: cacheState,
      percentComplete: nil)

    // Load the HLS/Media thumbnail. If it fails, fall-back to favIcon
    if let assetUrl = URL(string: item.src), let favIconUrl = URL(string: item.pageSrc) {
      cell.thumbnailActivityIndicator.startAnimating()
      cell.thumbnailGenerator.loadThumbnail(assetUrl: assetUrl, favIconUrl: favIconUrl) { [weak cell] image in
        guard let cell = cell else { return }

        cell.thumbnailView.image = image ?? FaviconFetcher.defaultFaviconImage
        cell.thumbnailView.backgroundColor = .black
        cell.thumbnailView.contentMode = .scaleAspectFit
        cell.thumbnailActivityIndicator.stopAnimating()
      }
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let folder = PlaylistManager.shared.currentFolder else {
      return tableView.dequeueReusableHeaderFooterView(withIdentifier: Constants.playListMenuHeaderRedactedIdentifier)
    }
    
    guard folder.playlistItems?.isEmpty == false else {
      return nil
    }
    
    let isPersistent = folder.managedObjectContext?.persistentStoreCoordinator?.persistentStores.first(where: { $0.type == "InMemory" }) == nil
    let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Constants.playListMenuHeaderIdentifier) as? PlaylistMenuHeader
    return header?.then { header in
      header.titleLabel.text = folder.title
      header.subtitleLabel.text = folder.creatorName
      header.subtitleLabel.isHidden = folder.creatorName == nil
      header.setState(isPersistent ? .menu : .add)
      
      header.onAddPlaylist = {
        Task { @MainActor [weak folder] in
          guard let folder = folder else { return }
          let persistentFolderId = await PlaylistSharedFolderModel.saveToDiskStorage(memoryFolder: folder)
          PlaylistManager.shared.currentFolder = PlaylistFolder.getFolder(uuid: persistentFolderId)
        }
      }
      
      header.menu = { [weak header, weak folder] in
        guard isPersistent,
              let folder = folder,
              let folderId = folder.uuid
        else { return nil }
        
        let syncAction = UIAction(title: "Sync Now", image: UIImage(named: "playlist_sync", in: .current, compatibleWith: nil)) { _ in
          guard let sharedFolderId = folder.sharedFolderId else { return }
          
          Task { @MainActor in
            do {
              let model = try await PlaylistSharedFolderModel.fetchPlaylist(playlistId: sharedFolderId)
              var oldItems = Set(folder.playlistItems?.map({ PlaylistInfo(item: $0) }) ?? [])
              let deletedItems = oldItems.subtracting(model.mediaItems)
              let newItems = Set(model.mediaItems).subtracting(oldItems)
              oldItems = []
              
              deletedItems.forEach({ PlaylistManager.shared.delete(itemId: $0.tagId) })
              
              await withCheckedContinuation { continuation in
                PlaylistItem.updateItems(Array(newItems), folderUUID: folderId) {
                  continuation.resume()
                }
              }
              
              PlaylistManager.shared.currentFolder = PlaylistFolder.getFolder(uuid: folderId)
            } catch {
              log.error("CANNOT SYNC SHARED PLAYLIST: \(error)")
            }
          }
        }
        
        let editAction = UIAction(title: "Edit", image: UIImage(braveSystemNamed: "brave.edit")) { [weak self] _ in
          self?.onEditItems()
        }
        
        let renameAction = UIAction(title: "Rename", image: UIImage(named: "playlist_rename_folder", in: .current, compatibleWith: nil)) { [weak self] _ in
          let folderID = folder.objectID
          var editView = PlaylistEditFolderView(currentFolder: folderID, currentFolderTitle: folder.title ?? "")

          editView.onCancelButtonPressed = { [weak self] in
            self?.presentedViewController?.dismiss(animated: true, completion: nil)
          }

          editView.onEditFolder = { [weak self] folderTitle in
            guard let self = self else { return }
            PlaylistFolder.updateFolder(folderID: folderID) { result in
              switch result {
              case .failure(let error):
                log.error("Error Saving Folder Title: \(error)")

                DispatchQueue.main.async {
                  let alert = UIAlertController(title: Strings.genericErrorTitle, message: Strings.PlaylistFolders.playlistFolderErrorSavingMessage, preferredStyle: .alert)

                  alert.addAction(
                    UIAlertAction(
                      title: Strings.OBErrorOkay, style: .default,
                      handler: { _ in
                        self.presentedViewController?.dismiss(animated: true, completion: nil)
                      }))
                  self.present(alert, animated: true, completion: nil)
                }

              case .success(let folder):
                folder.title = folderTitle
                
                DispatchQueue.main.async {
                  header?.titleLabel.text = folderTitle
                  self.title = folderTitle
                  self.presentedViewController?.dismiss(animated: true, completion: nil)
                }
              }
            }
          }

          let hostingController = UIHostingController(rootView: editView.environment(\.managedObjectContext, folder.managedObjectContext ?? DataController.swiftUIContext)).then {
            $0.modalPresentationStyle = .formSheet
          }

          self?.present(hostingController, animated: true, completion: nil)
        }
        
        let deleteOfflineAction = UIAction(title: "Remove Offline Data", image: UIImage(named: "playlist_delete_download", in: .current, compatibleWith: nil)) { [weak self] _ in
          folder.playlistItems?.forEach {
            if let itemId = $0.uuid {
              PlaylistManager.shared.deleteCache(itemId: itemId)
            }
          }
          
          self?.tableView.reloadData()
        }
        
//        let saveOfflineAction = UIAction(title: "Save Offline Data", image: UIImage(systemName: "icloud.and.arrow.down")) { [weak self] _ in
//          folder.playlistItems?.forEach {
//            PlaylistManager.shared.download(item: PlaylistInfo(item: $0))
//          }
//
//          self?.tableView.reloadData()
//        }
        
        let deleteAction = UIAction(title: "Delete Playlist", image: UIImage(named: "playlist_delete_item", in: .current, compatibleWith: nil), attributes: .destructive) { [weak self] _ in
          PlaylistManager.shared.delete(folder: folder)
          self?.navigationController?.popToRootViewController(animated: true)
        }
        
        if folder.sharedFolderId != nil {
          return UIMenu(children: [syncAction, editAction, renameAction, deleteOfflineAction, deleteAction])
        }
        
        if folder.uuid == PlaylistFolder.savedFolderUUID {
          return UIMenu(children: [editAction, deleteOfflineAction, deleteAction])
        }
        
        return UIMenu(children: [editAction, renameAction, deleteOfflineAction, deleteAction])
      }()
    }
  }
}
