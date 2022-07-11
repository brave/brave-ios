// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared
import Data
import UIKit

/// Displays a large favicon given some favorite
class LargeFaviconView: UIView {
  func loadFavicon(siteURL: URL, domain: Domain? = nil, monogramFallbackCharacter: Character? = nil) {
    // Setup the favicon fetcher to pull a large icon for the given
    // domain
    faviconTask?.cancel()
    faviconTask = FaviconFetcher.loadIcon(url: siteURL,
                                          kind: .largeIcon,
                                          persistent: !PrivateBrowsingManager.shared.isPrivateBrowsing,
                                          completion: { [weak self] favicon in
      guard let self = self else { return }
      self.imageView.image = favicon?.image
      self.backgroundColor = favicon?.backgroundColor
      self.imageView.contentMode = .scaleAspectFit
      self.backgroundView.isHidden = !(favicon?.backgroundColor == .clear) || favicon?.isMonogramImage == true
    })
  }

  func cancelLoading() {
    faviconTask?.cancel()
    faviconTask = nil
    imageView.image = nil
    imageView.contentMode = .scaleAspectFit
    backgroundColor = .clear
    layoutMargins = .zero
    backgroundView.isHidden = false
  }

  private var faviconTask: FaviconFetcher.Cancellable?

  private let imageView = UIImageView().then {
    $0.contentMode = .scaleAspectFit
  }

  private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .regular)).then {
    $0.isHidden = true
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    layer.cornerRadius = 8
    layer.cornerCurve = .continuous

    clipsToBounds = true
    layer.borderColor = BraveUX.faviconBorderColor.cgColor
    layer.borderWidth = BraveUX.faviconBorderWidth

    layoutMargins = .zero

    addSubview(backgroundView)
    addSubview(imageView)

    backgroundView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    imageView.snp.makeConstraints {
      $0.center.equalTo(self)
      $0.leading.top.greaterThanOrEqualTo(layoutMarginsGuide)
      $0.trailing.bottom.lessThanOrEqualTo(layoutMarginsGuide)
    }
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
}
