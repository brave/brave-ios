// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

protocol TabSyncHeaderViewDelegate {
    func toggleSection(_ header: TabSyncHeaderView, section: Int)
}

class TabSyncHeaderView: UITableViewHeaderFooterView {
    
  var delegate: TabSyncHeaderViewDelegate?
  var section: Int = 0
    
  let titleLabel = UILabel().then {
    $0.textColor = .braveLabel
  }
  
  let arrowLabel = UILabel().then {
    $0.textColor = .braveLabel
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
  }
    
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    contentView.backgroundColor = .clear
        
    contentView.addSubview(arrowLabel)
    contentView.addSubview(titleLabel)

    arrowLabel.snp.makeConstraints {
      $0.top.leading.bottom.equalTo(layoutMarginsGuide)
      $0.trailing.equalTo(arrowLabel.snp.leading)
    }
    
    arrowLabel.snp.makeConstraints {
      $0.top.bottom.leading.equalTo(layoutMarginsGuide)
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
