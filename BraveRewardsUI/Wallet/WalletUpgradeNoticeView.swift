// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveUI

class WalletUpgradeNoticeView: UIView, WalletContentView {
  var innerScrollView: UIScrollView? { scrollView }
  var displaysRewardsSummaryButton: Bool { true }
  
  private let scrollView = UIScrollView().then {
    $0.contentInsetAdjustmentBehavior = .never
    $0.delaysContentTouches = false
  }
  
  let noticeView = RewardsChangesNoticeView()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(scrollView)
    scrollView.addSubview(noticeView)
    scrollView.snp.makeConstraints {
      $0.edges.equalTo(self)
    }
    scrollView.contentLayoutGuide.snp.makeConstraints {
      $0.width.equalTo(self)
      $0.bottom.equalTo(noticeView).offset(25)
    }
    noticeView.snp.makeConstraints {
      $0.top.equalTo(scrollView.contentLayoutGuide).inset(25)
      $0.leading.trailing.equalTo(self).inset(25)
    }
  }
  
  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
}
