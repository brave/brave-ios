// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveUI

class BraveSearchPromotionCell: UITableViewCell {
  static let identifier = "BraveSearchPromotionCell"

  var enableSearchEngineTapped: (() -> Void)?
  var dismissTapped: (() -> Void)?

  private let mainStackView = UIStackView().then {
    $0.axis = .vertical
    $0.alignment = .leading
    $0.spacing = 6
  }

  private let titleLabel = UILabel().then {
    $0.text = "Support independent search with better privacy"
    $0.textColor = .bravePrimary
    $0.textAlignment = .left
    $0.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    $0.numberOfLines = 0
    $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
  }

  private let bodyLabel = UILabel().then {
    $0.text = "Brave Search doesn't track you, your queries, or your clicks."
    $0.textColor = .braveLabel
    $0.textAlignment = .left
    $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
    $0.numberOfLines = 0
    $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
  }

  private let enableButton = RoundInterfaceButton(type: .roundedRect).then {
    $0.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    $0.setTitleColor(.white, for: .normal)
    $0.setTitle("Try Brave Search", for: .normal)
    $0.backgroundColor = .braveOrange
    $0.snp.makeConstraints { make in
      make.height.equalTo(44)
      make.width.greaterThanOrEqualTo(120)
    }
    $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
  }

  private let promotionContentView = UIView().then {
    $0.clipsToBounds = true
    $0.layer.cornerRadius = 16
    $0.layer.cornerCurve = .continuous
    $0.backgroundColor = BraveVPNCommonUI.UX.purpleBackgroundColor
  }

  private let backgroundImage = UIImageView(image: #imageLiteral(resourceName: "enable_vpn_settings_banner")).then {
    $0.contentMode = .scaleAspectFill
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    backgroundColor = .secondaryBraveBackground

    contentView.addSubview(promotionContentView)
    promotionContentView.snp.makeConstraints {
      $0.edges.equalToSuperview().inset(8)
    }
    
    promotionContentView.addSubview(backgroundImage)
    backgroundImage.snp.makeConstraints { $0.edges.equalToSuperview() }

    [titleLabel, bodyLabel, enableButton].forEach(mainStackView.addArrangedSubview(_:))

    promotionContentView.addSubview(mainStackView)
    mainStackView.snp.makeConstraints {
      $0.edges.equalToSuperview().inset(16)
    }

    promotionContentView.snp.makeConstraints {
      $0.top.equalToSuperview().inset(8)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalToSuperview()
    }

    enableButton.addTarget(self, action: #selector(enableBraveSearchAction), for: .touchUpInside)
  }

  @available(*, unavailable)
  required init(coder: NSCoder) { fatalError() }

  @objc func enableBraveSearchAction() {
    enableSearchEngineTapped?()
  }

  @objc func closeView() {
    dismissTapped?()
  }
}
