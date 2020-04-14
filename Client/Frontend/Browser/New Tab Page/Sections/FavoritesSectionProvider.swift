// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveUI
import Data
import CoreData
import Shared

private let log = Logger.browserLogger

enum BookmarksAction {
    case opened(inNewTab: Bool = false, switchingToPrivateMode: Bool = false)
    case edited
}

class FavoritesSectionProvider: NSObject, NTPObservableSectionProvider {
    var sectionDidChange: (() -> Void)?
    var action: (Bookmark, BookmarksAction) -> Void
    
    private var frc: NSFetchedResultsController<Bookmark>
    
    init(action: @escaping (Bookmark, BookmarksAction) -> Void) {
        self.action = action
        frc = Bookmark.frc(forFavorites: true, parentFolder: nil)
        super.init()
        frc.fetchRequest.fetchLimit = 6
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            log.error("Favorites fetch error")
        }
    }
    
    /// The number of times that each row contains
    func numberOfItems(in collectionView: UICollectionView, availableWidth: CGFloat) -> Int {
        /// Two considerations:
        /// 1. icon size minimum
        /// 2. trait collection
        
        let icons = (less: 4, more: 6)
        let minIconPoints: CGFloat = 80
        
        // If icons fall below a certain size, then use less icons.
        if (availableWidth / CGFloat(icons.more)) < minIconPoints {
            return icons.less
        }
        
        let cols = collectionView.traitCollection.horizontalSizeClass == .compact ? icons.less : icons.more
        return cols
    }
    
    func registerCells(to collectionView: UICollectionView) {
        collectionView.register(FavoriteCell.self, forCellWithReuseIdentifier: FavoriteCell.identifier)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let bookmark = frc.fetchedObjects?[safe: indexPath.item] else {
            return
        }
        action(bookmark, .opened())
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let fetchedCount = frc.fetchedObjects?.count ?? 0
        return min(fetchedCount, numberOfItems(in: collectionView, availableWidth: fittingSizeForCollectionView(collectionView, section: section).width))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavoriteCell.identifier, for: indexPath) as! FavoriteCell
        return configureCell(cell: cell, at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = fittingSizeForCollectionView(collectionView, section: indexPath.section).width
        let cellWidth = width / CGFloat(numberOfItems(in: collectionView, availableWidth: width))
        // The tile's height is determined the aspect ratio of the thumbnails width. We also take into account
        // some padding between the title and the image.
        let scale = 1.0 / UIScreen.main.scale
        return CGSize(width: (scale * (cellWidth / scale)).rounded(.down),
                      height: 1000)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let favourite = frc.fetchedObjects?[indexPath.item] else { return nil }
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { (elemenst) -> UIMenu? in
            let openInNewTab = UIAction(title: Strings.openNewTabButtonTitle, image: nil, identifier: nil, discoverabilityTitle: nil) { (action) in
                self.action(favourite, .opened(inNewTab: true, switchingToPrivateMode: false))
            }
            let edit = UIAction(title: Strings.editBookmark, image: nil, identifier: nil, discoverabilityTitle: nil) { (action) in
                self.action(favourite, .edited)
            }
            let delete = UIAction(title: Strings.removeFavorite, image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .destructive) { (action) in
                favourite.delete()
            }
            
            var urlChildren: [UIAction] = [openInNewTab]
            if !PrivateBrowsingManager.shared.isPrivateBrowsing {
                let openInNewPrivateTab = UIAction(title: Strings.openNewPrivateTabButtonTitle, image: nil, identifier: nil, discoverabilityTitle: nil) { (action) in
                    self.action(favourite, .opened(inNewTab: true, switchingToPrivateMode: true))
                }
                urlChildren.append(openInNewPrivateTab)
            }
            
            let urlMenu = UIMenu(title: "", options: .displayInline, children: urlChildren)
            let favMenu = UIMenu(title: "", options: .displayInline, children: [edit, delete])
            return UIMenu(title: favourite.title ?? favourite.url ?? "", identifier: nil, children: [urlMenu, favMenu])
        }
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? FavoriteCell else {
                return nil
        }
        return UITargetedPreview(view: cell.imageView)
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? FavoriteCell else {
                return nil
        }
        return UITargetedPreview(view: cell.imageView)
    }
    
    @discardableResult
    fileprivate func configureCell(cell: FavoriteCell, at indexPath: IndexPath) -> UICollectionViewCell {
        let fav = frc.object(at: IndexPath(item: indexPath.item, section: 0))
        
        cell.textLabel.text = fav.displayTitle ?? fav.url
        cell.imageView.setIconMO(nil, forURL: URL(string: fav.url ?? ""), scaledDefaultIconSize: CGSize(width: 40, height: 40), completed: { (color, url) in
            if fav.url == url?.absoluteString {
                cell.imageView.backgroundColor = color
            }
        })
        cell.accessibilityLabel = cell.textLabel.text
        //        cell.toggleEditButton(isEditing)
        
        return cell
    }
}

extension FavoritesSectionProvider: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        sectionDidChange?()
    }
}
