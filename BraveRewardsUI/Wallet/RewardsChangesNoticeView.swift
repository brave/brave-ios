// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveUI

class RewardsChangesNoticeView: UIStackView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    axis = .vertical
    spacing = 12
    
    addArrangedSubview(label)
    addArrangedSubview(learnMoreButton)
  }
  
  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
  
  private let label = UILabel().then {
    $0.text = Strings.platformChangesNoticeMessage
    $0.appearanceTextColor = Colors.grey700
    $0.font = .systemFont(ofSize: 15)
    $0.numberOfLines = 0
  }
  
  let learnMoreButton = UIButton(type: .system).then {
    $0.setTitle(Strings.platformChangesNoticeLearnMoreTitle, for: .normal)
    $0.titleLabel?.numberOfLines = 0
    $0.appearanceTintColor = Colors.blurple500
    $0.setTitleColor(Colors.blurple500, for: .normal)
    $0.contentHorizontalAlignment = .leading
    $0.titleLabel?.font = .systemFont(ofSize: 15)
  }
}
