// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveCore
import BraveShared

/// A view that displays the tab's secure content state and the URL while scrolling into the page
class CollapsedURLBarView: UIView {
  private let stackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.isUserInteractionEnabled = false
  }
  
  private let lockImageView = ToolbarButton(top: true).then {
    $0.setImage(UIImage(named: "lock_verified", in: .current, compatibleWith: nil)!.template, for: .normal)
    $0.isHidden = true
    $0.tintColor = .bravePrimary
    $0.isAccessibilityElement = true
    $0.imageView?.contentMode = .center
    $0.contentHorizontalAlignment = .center
    $0.accessibilityLabel = Strings.tabToolbarLockImageAccessibilityLabel
    $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
  }
  
  private let urlLabel = UILabel().then {
    $0.font = .preferredFont(forTextStyle: .caption1)
    $0.textColor = .bravePrimary
    $0.adjustsFontForContentSizeCategory = true
    $0.lineBreakMode = .byTruncatingHead
  }
  
  private func updateLockImageView() {
    lockImageView.isHidden = false
    
    switch secureContentState {
    case .localHost:
      lockImageView.isHidden = true
    case .insecure:
      lockImageView.setImage(UIImage(named: "insecure-site-icon", in: .current, compatibleWith: nil)!, for: .normal)
    case .secure, .unknown:
      lockImageView.setImage(UIImage(named: "lock_verified", in: .current, compatibleWith: nil)!.template, for: .normal)
    }
  }
  
  var secureContentState: TabSecureContentState = .unknown {
    didSet {
      updateLockImageView()
    }
  }
  
  var currentURL: URL? {
    didSet {
      urlLabel.text = currentURL.map {
        URLFormatter.formatURL(forDisplayOmitSchemePathAndTrivialSubdomains: $0.absoluteString)
      }
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    isUserInteractionEnabled = false
    
    addSubview(stackView)
    stackView.addArrangedSubview(lockImageView)
    stackView.addArrangedSubview(urlLabel)
    
    let line = UIView.separatorLine
    addSubview(line)
    
    stackView.snp.makeConstraints {
      $0.top.equalToSuperview()
      $0.bottom.equalToSuperview().inset(4)
      $0.leading.greaterThanOrEqualToSuperview().inset(12)
      $0.trailing.lessThanOrEqualToSuperview().inset(12)
      $0.centerX.equalToSuperview()
    }
    
    line.snp.makeConstraints {
      $0.top.equalTo(self.snp.bottom)
      $0.leading.trailing.equalToSuperview()
    }
  }
  
  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
}
