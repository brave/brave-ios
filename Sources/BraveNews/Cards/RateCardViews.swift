// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveStrings

public class SmallRateCardView: FeedCardBackgroundButton, FeedCardContent {
  public var actionHandler: ((Int, FeedItemAction) -> Void)?
  public var contextMenu: FeedItemMenu?

  public let feedView = FeedItemView(layout: .rateCard).then {
    $0.isUserInteractionEnabled = false
    $0.callToActionButton.setTitle(Strings.BraveNews.rateBraveCardRateActionTitle, for: .normal)
  }

  private var contextMenuDelegate: NSObject?

  public required init() {
    super.init(frame: .zero)

    addSubview(feedView)
    feedView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    addTarget(self, action: #selector(tappedSelf), for: .touchUpInside)

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

    isAccessibilityElement = true
    
    feedView.titleLabel.text = Strings.BraveNews.rateBraveCardTitle
    feedView.descriptionLabel.do {
      $0.text = Strings.BraveNews.rateBraveCardSubtitle
      $0.textColor = .white
    }
    feedView.thumbnailImageView.image = UIImage(sharedNamed: "brave.logo")
    feedView.callToActionButton.setTitleColor(.braveLighterBlurple, for: .normal)
  }

  public override var accessibilityLabel: String? {
    get { feedView.accessibilityLabel }
    set { assertionFailure("Accessibility label is inherited from a subview: \(String(describing: newValue)) ignored") }
  }

  @objc private func tappedSelf() {
    actionHandler?(0, .opened())
  }
}

public class SmallHeadlineRatePairCardView: UIView, FeedCardContent {
  public var actionHandler: ((Int, FeedItemAction) -> Void)?
  public var contextMenu: FeedItemMenu?

  private let stackView = UIStackView().then {
    $0.distribution = .fillEqually
    $0.spacing = 20
  }

  public let smallHeadlineRateCardViews: (smallHeadline: SmallHeadlineCardView, ratingCard: SmallRateCardView) = (SmallHeadlineCardView(), SmallRateCardView())

  public required init() {
    super.init(frame: .zero)

    addSubview(stackView)
    stackView.addArrangedSubview(smallHeadlineRateCardViews.smallHeadline)
    stackView.addArrangedSubview(smallHeadlineRateCardViews.ratingCard)

    smallHeadlineRateCardViews.smallHeadline.actionHandler = { [weak self] _, action in
      self?.actionHandler?(0, action)
    }
    smallHeadlineRateCardViews.ratingCard.actionHandler = { [weak self] _, action in
      self?.actionHandler?(1, action)
    }
    
    smallHeadlineRateCardViews.smallHeadline.contextMenu = FeedItemMenu({ [weak self] _ -> UIMenu? in
      return self?.contextMenu?.menu?(0)
    })
    smallHeadlineRateCardViews.ratingCard.contextMenu = FeedItemMenu({ [weak self] _ -> UIMenu? in
      return self?.contextMenu?.menu?(1)
    })

    stackView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
}
