// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveUI

protocol TabSyncHeaderViewDelegate {
    func toggleSection(_ header: TabSyncHeaderView, section: Int)
}

class TabSyncHeaderView: UITableViewHeaderFooterView, TableViewReusable {
    
  var delegate: TabSyncHeaderViewDelegate?
  var section: Int = 0
    
  let titleLabel = UILabel().then {
    $0.textColor = .braveLabel
    $0.font = .preferredFont(forTextStyle: .footnote, weight: .semibold)
    $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  }
  
  let arrowLabel = UILabel().then {
    $0.textColor = .braveLabel
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    $0.font = .preferredFont(forTextStyle: .headline)
    $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
  }
    
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    contentView.backgroundColor = .clear
        
    contentView.addSubview(arrowLabel)
    contentView.addSubview(titleLabel)

    titleLabel.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(TwoLineCellUX.borderViewMargin)
      $0.top.bottom.equalToSuperview()
    }
    
    arrowLabel.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(TwoLineCellUX.borderViewMargin)
      $0.top.bottom.trailing.equalToSuperview()
      $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).inset(-TwoLineCellUX.borderViewMargin)
    }

    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHeader(_:))))
  }
    
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
    
  @objc func tapHeader(_ gestureRecognizer: UITapGestureRecognizer) {
    guard let cell = gestureRecognizer.view as? TabSyncHeaderView else {
      return
    }
        
    delegate?.toggleSection(self, section: cell.section)
  }
    
  func setCollapsed(_ collapsed: Bool) {
    let animation = CABasicAnimation(keyPath: "transform.rotation").then {
      $0.toValue = collapsed ? 0.0 : .pi / 2
      $0.duration = 0.2
      $0.isRemovedOnCompletion = false
      $0.fillMode = CAMediaTimingFillMode.forwards
    }

    arrowLabel.layer.add(animation, forKey: nil)
  }
}
