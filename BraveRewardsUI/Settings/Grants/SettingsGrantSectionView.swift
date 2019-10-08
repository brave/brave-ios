/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SettingsGrantSectionView: SettingsSectionView {
  
  /// The grant type
  enum GrantType {
    /// A regular UGP grant, which does not show the user what the amount is
    case ugp
    /// An ads grant. The amount optionally should be a `BATValue`'s
    /// `displayString`
    case ads(amount: String?)
  }
  
  var claimGrantTapped: ((SettingsGrantSectionView) -> Void)?
  
  let claimGrantButton = Button().then {
    $0.loaderView = LoaderView(size: .small)
    $0.backgroundColor = BraveUX.braveOrange
    $0.tintColor = .white
    $0.titleLabel?.font = .systemFont(ofSize: 13.0, weight: .bold)
    $0.setTitle(Strings.SettingsGrantClaimButtonTitle.uppercased(), for: .normal)
    $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
  }
  
  init(type: GrantType) {
    super.init(frame: .zero)
    
    claimGrantButton.addTarget(self, action: #selector(tappedClaimGrantButton), for: .touchUpInside)
    
    switch type {
    case .ads(let amount):
      iconImageView.image = UIImage(frameworkResourceNamed: "icn-ads")
      if let amount = amount {
        textLabel.text = String(format: Strings.SettingsAdsGrantText, "\(amount) BAT ")
      } else {
        textLabel.text = Strings.SettingsAdsGrantText
      }
    case .ugp:
      iconImageView.image = UIImage(frameworkResourceNamed: "icn-grant")
      textLabel.text = Strings.SettingsGrantText
    }
    
    clippedContentView.addSubview(claimGrantButton)
    clippedContentView.addSubview(iconImageView)
    clippedContentView.addSubview(textLabel)
    
    snp.makeConstraints {
      $0.height.greaterThanOrEqualTo(48.0)
    }
    claimGrantButton.snp.makeConstraints {
      $0.top.bottom.trailing.equalTo(self)
    }
    iconImageView.snp.makeConstraints {
      $0.leading.centerY.equalTo(self.layoutMarginsGuide)
      $0.width.equalTo(iconImageView.image!.size.width * (2.0/3.0))
      $0.height.equalTo(iconImageView.snp.width)
    }
    textLabel.snp.makeConstraints {
      $0.top.greaterThanOrEqualTo(self.layoutMarginsGuide)
      $0.bottom.lessThanOrEqualTo(self.layoutMarginsGuide)
      $0.leading.equalTo(self.iconImageView.snp.trailing).offset(10.0)
      $0.trailing.equalTo(self.claimGrantButton.snp.leading).offset(-10.0)
      $0.centerY.equalTo(self)
    }
  }
  
  @objc private func tappedClaimGrantButton() {
    if !claimGrantButton.isLoading {
      claimGrantTapped?(self)
    }
  }
  
  // MARK: - Private UI
  
  private let iconImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFit
  }
  
  private let textLabel = UILabel().then {
    $0.textColor = SettingsUX.bodyTextColor
    $0.font = SettingsUX.bodyFont
    $0.numberOfLines = 0
  }
}
