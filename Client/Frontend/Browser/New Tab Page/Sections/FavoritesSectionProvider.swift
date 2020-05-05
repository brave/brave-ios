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
    var legacyLongPressAction: (UIAlertController) -> Void
    
    private var frc: NSFetchedResultsController<Bookmark>
    
    init(action: @escaping (Bookmark, BookmarksAction) -> Void,
         legacyLongPressAction: @escaping (UIAlertController) -> Void) {
        self.action = action
        self.legacyLongPressAction = legacyLongPressAction
        
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
    static func numberOfItems(in collectionView: UICollectionView, availableWidth: CGFloat) -> Int {
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
        return min(fetchedCount, Self.numberOfItems(in: collectionView, availableWidth: fittingSizeForCollectionView(collectionView, section: section).width))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // swiftlint:disable:next force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavoriteCell.identifier, for: indexPath) as! FavoriteCell
        let fav = frc.object(at: IndexPath(item: indexPath.item, section: 0))
        cell.textLabel.text = fav.displayTitle ?? fav.url
        cell.imageView.setIconMO(fav.domain?.favicon, forURL: URL(string: fav.url ?? ""), scaledDefaultIconSize: CGSize(width: 40, height: 40), completed: { (color, url) in
            if fav.url == url?.absoluteString {
                cell.imageView.backgroundColor = color
            }
        })
        cell.accessibilityLabel = cell.textLabel.text
        cell.longPressHandler = { [weak self] cell in
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let edit = UIAlertAction(title: Strings.editBookmark, style: .default) { (action) in
                self?.action(fav, .edited)
            }
            let delete = UIAlertAction(title: Strings.removeFavorite, style: .destructive) { (action) in
                fav.delete()
            }
            
            alert.addAction(edit)
            alert.addAction(delete)
            
            alert.popoverPresentationController?.sourceView = cell
            alert.popoverPresentationController?.permittedArrowDirections = [.down, .up]
            alert.addAction(UIAlertAction(title: Strings.close, style: .cancel, handler: nil))
            
            UIImpactFeedbackGenerator(style: .medium).bzzt()
            self?.legacyLongPressAction(alert)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = fittingSizeForCollectionView(collectionView, section: indexPath.section).width
        let scale = 1.0 / UIScreen.main.scale
        let cellWidth = (scale * (width / CGFloat(Self.numberOfItems(in: collectionView, availableWidth: width)) / scale)).rounded(.down)
        return CGSize(width: cellWidth,
                      height: FavoriteCell.height(forWidth: cellWidth))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
    }
    
    @available(iOS 13.0, *)
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let favourite = frc.fetchedObjects?[indexPath.item] else { return nil }
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { _ -> UIMenu? in
            let openInNewTab = UIAction(title: Strings.openNewTabButtonTitle, image: nil, identifier: nil, discoverabilityTitle: nil) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.action(favourite, .opened(inNewTab: true, switchingToPrivateMode: false))
                }
            }
            let edit = UIAction(title: Strings.editBookmark, image: nil, identifier: nil, discoverabilityTitle: nil) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.action(favourite, .edited)
                }
            }
            let delete = UIAction(title: Strings.removeFavorite, image: nil, identifier: nil, discoverabilityTitle: nil, attributes: .destructive) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    favourite.delete()
                }
            }
            
            var urlChildren: [UIAction] = [openInNewTab]
            if !PrivateBrowsingManager.shared.isPrivateBrowsing {
                let openInNewPrivateTab = UIAction(title: Strings.openNewPrivateTabButtonTitle, image: nil, identifier: nil, discoverabilityTitle: nil) { _ in
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
}

extension FavoritesSectionProvider: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        sectionDidChange?()
    }
}
