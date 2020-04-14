// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// The new tab page collection view layout
///
/// Handles correcting center-aligned single items in a flow layout while using
/// automatic sizing cells as well as laying out specific outliers in the
/// collection view.
class NewTabPageFlowLayout: UICollectionViewFlowLayout {
    /// The section belonging to the image credit provider
    ///
    /// This section lays out special: bottom-left regardless other items in
    /// the collection view.
    ///
    /// This may need to change in the future
    var imageCreditSection: Int?
    
    override init() {
        super.init()
        estimatedItemSize = Self.automaticSize
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attribute = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes,
            let collectionView = collectionView else {
                return nil
        }

        if attribute.representedElementCategory != .cell {
            return attribute
        }

        // Left align the cells since they automatically center if there's only
        // 1 item in the section and use automaticSize...
        if estimatedItemSize == UICollectionViewFlowLayout.automaticSize {
            let indexPath = attribute.indexPath
            if collectionView.numberOfItems(inSection: indexPath.section) == 1 {
                let sectionInset: UIEdgeInsets
                let minimumInteritemSpacing: CGFloat
                if let flowLayoutDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
                    sectionInset = flowLayoutDelegate.collectionView?(collectionView, layout: self, insetForSectionAt: indexPath.section) ?? self.sectionInset
                    minimumInteritemSpacing = flowLayoutDelegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: indexPath.section) ?? self.minimumInteritemSpacing
                } else {
                    sectionInset = self.sectionInset
                    minimumInteritemSpacing = self.minimumInteritemSpacing
                }

                if attribute.indexPath.item == 0 {
                    attribute.frame.origin.x = sectionInset.left
                } else {
                    if let previousItemAttribute = layoutAttributesForItem(at: IndexPath(item: indexPath.item - 1, section: indexPath.section)) {
                        attribute.frame.origin.x = previousItemAttribute.frame.maxX + minimumInteritemSpacing
                    }
                }
            }
        }

        // Lays out bottom-left regardless
        if let imageCreditSection = imageCreditSection, indexPath.section == imageCreditSection {
            var r = attribute.frame
            r.origin.y = collectionView.frame.height - collectionView.safeAreaInsets.bottom - attribute.size.height - 16
            r.origin.x = 16
            attribute.frame = r
        }

        return attribute
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else {
                return nil
        }
        attributes.forEach {
            if $0.representedElementCategory == .cell {
                if let frame = self.layoutAttributesForItem(at: $0.indexPath)?.frame {
                    $0.frame = frame
                }
            }
        }
        return attributes
    }
}
