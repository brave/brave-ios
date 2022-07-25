// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import UIKit

class EmptyStateOverlayView: UIView {

  private let iconImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.tintColor = .braveLabel
  }

  private let informationLabel = UILabel().then {
    $0.textAlignment = .center
    $0.font = .preferredFont(for: .title3, weight: .medium)
    $0.textColor = .braveLabel
    $0.numberOfLines = 0
    $0.adjustsFontSizeToFitWidth = true
  }
  
  private let descriptionLabel = UILabel().then {
    $0.textAlignment = .center
    $0.font = .preferredFont(forTextStyle: .subheadline)
    $0.textColor = .braveLabel
    $0.numberOfLines = 0
    $0.adjustsFontSizeToFitWidth = true
  }

  required init(title: String? = nil, description: String? = nil, icon: UIImage? = nil) {
    super.init(frame: .zero)

    backgroundColor = .secondaryBraveBackground

    if let icon = icon {
      iconImageView.image = icon.template
    }

    addSubview(iconImageView)

    iconImageView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.size.greaterThanOrEqualTo(60)
      // Sets proper top constraint for iPhone 6 in portrait and for iPad.
      make.centerY.equalToSuperview().offset(-180).priority(100)
      // Sets proper top constraint for iPhone 4, 5 in portrait.
      make.top.greaterThanOrEqualToSuperview().offset(50)
    }

    if let title = title {
      informationLabel.text = title
    }

    addSubview(informationLabel)

    informationLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(iconImageView.snp.bottom).offset(15)
      make.width.equalToSuperview().multipliedBy(0.75)
    }
    
    if let description = description {
      descriptionLabel.text = description
    }
    
    addSubview(descriptionLabel)
    
    descriptionLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(informationLabel.snp.bottom).offset(15)
      make.width.equalToSuperview().multipliedBy(0.75)
    }
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }

  func updateInfoLabel(with text: String) {
    informationLabel.text = text
  }
  
  func updateDescriptionLabel(with text: String) {
    descriptionLabel.text = text
  }
}
