// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveUI

class PartnerCardView: FeedCardBackgroundButton, FeedCardContent {
    var actionHandler: ((Int, FeedItemAction) -> Void)?
    var contextMenu: FeedItemMenu?
    var promotedButtonTapped: (() -> Void)?
    
    let feedView = FeedItemView(layout: .partner).then {
        $0.thumbnailImageView.contentMode = .scaleAspectFit
    }
    
    private var contextMenuDelegate: NSObject?
    
    required init() {
        super.init(frame: .zero)
        
        addSubview(feedView)
        feedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        addTarget(self, action: #selector(tappedSelf), for: .touchUpInside)
        feedView.promotedButton.addTarget(self, action: #selector(tappedPromotedButton), for: .touchUpInside)
        
        if #available(iOS 13.0, *) {
            let contextMenuDelegate = FeedContextMenuDelegate(
                performedPreviewAction: { [weak self] in
                    self?.actionHandler?(0, .opened())
                },
                menu: { [weak self] in
                    return self?.contextMenu?.menu?(0)
                }
            )
            addInteraction(UIContextMenuInteraction(delegate: contextMenuDelegate))
            self.contextMenuDelegate = contextMenuDelegate
        } else {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
            addGestureRecognizer(longPress)
        }
        
        isAccessibilityElement = false
        accessibilityElements = [feedView, feedView.promotedButton]
        feedView.accessibilityTraits.insert(.button)
        shouldGroupAccessibilityChildren = true
    }
    
    override var accessibilityLabel: String? {
        get { feedView.accessibilityLabel }
        set { assertionFailure("Accessibility label is inherited from a subview: \(String(describing: newValue)) ignored") }
    }
    
    @objc private func tappedSelf() {
        actionHandler?(0, .opened())
    }
    
    @objc private func longPressed(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began, let legacyContext = contextMenu?.legacyMenu?(0) {
            actionHandler?(0, .longPressed(legacyContext))
        }
    }
    
    @objc private func tappedPromotedButton() {
        promotedButtonTapped?()
    }
}
