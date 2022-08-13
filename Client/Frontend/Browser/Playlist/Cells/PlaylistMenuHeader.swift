// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveUI
import BraveShared

class PlaylistMenuHeader: UITableViewHeaderFooterView {
  enum State {
    case add
    case menu
  }
  
  let titleLabel = UILabel().then {
    $0.font = .preferredFont(forTextStyle: .title3, weight: .medium)
    $0.textColor = .bravePrimary
    $0.numberOfLines = 2
  }
  
  let subtitleLabel = UILabel().then {
    $0.font = .preferredFont(forTextStyle: .footnote)
    $0.textColor = .bravePrimary
    $0.numberOfLines = 2
  }
  
  private let menuButton = RoundInterfaceButton(type: .custom).then {
    $0.setTitleColor(.bravePrimary, for: .normal)
    $0.titleLabel?.numberOfLines = 0
    $0.titleLabel?.minimumScaleFactor = 0.7
    $0.titleLabel?.adjustsFontSizeToFitWidth = true
    $0.titleLabel?.font = .preferredFont(for: .subheadline, weight: .bold)
    $0.imageView?.tintColor = .bravePrimary
    $0.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)
    $0.contentMode = .scaleAspectFit
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    $0.setContentHuggingPriority(.required, for: .horizontal)
  }
  
  private var state: State = .add
  
  public var onAddPlaylist: (() -> Void)?
  
  public var menu: UIMenu? {
    didSet {
      menuButton.menu = menu
      menuButton.showsMenuAsPrimaryAction = menu != nil
    }
  }
  
  public func setMenuEnabled(enabled: Bool) {
    if menu == nil {
      menuButton.isUserInteractionEnabled = true
    } else {
      menuButton.isUserInteractionEnabled = enabled
    }
    
    menuButton.imageView?.tintColor = menuButton.isUserInteractionEnabled ? .bravePrimary : .braveDisabled
  }
  
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    
    let hStack = UIStackView(arrangedSubviews: [
      UIStackView(arrangedSubviews: [
        titleLabel,
        subtitleLabel
      ]).then {
        $0.axis = .vertical
      },
      menuButton
    ]).then {
      $0.spacing = 20.0
      $0.isLayoutMarginsRelativeArrangement = true
      $0.layoutMargins = UIEdgeInsets(equalInset: 15.0)
    }
    
    contentView.addSubview(hStack)
    hStack.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    menuButton.addTarget(self, action: #selector(onMenuButtonPressed(_:)), for: .touchUpInside)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setState(_ state: State) {
    self.state = state
    
    switch state {
    case .add:
      menuButton.setTitle(Strings.PlaylistFolderSharing.addButtonTitle, for: .normal)
      menuButton.setImage(nil, for: .normal)
      menuButton.backgroundColor = .braveBlurple
      menuButton.accessibilityLabel = Strings.PlaylistFolderSharing.addButtonAccessibilityTitle
      menuButton.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)
    case .menu:
      menuButton.setTitle(nil, for: .normal)
      menuButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
      menuButton.backgroundColor = .clear
      menuButton.accessibilityLabel = Strings.PlaylistFolderSharing.menuButtonAccessibilityTitle
      menuButton.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 0.0)
    }
  }
  
  @objc
  private func onMenuButtonPressed(_ button: UIButton) {
    switch state {
    case .add:
      onAddPlaylist?()
    case .menu:
      break
    }
  }
}
