// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import Shared
import BraveUI
import BraveCore

class WalletConnectionView: UIControl {
  private let stackView: UIStackView = {
    let result = UIStackView()
    result.axis = .horizontal
    result.spacing = 20
    result.alignment = .center
    result.isUserInteractionEnabled = false
    return result
  }()

  private let iconImageView: UIImageView = {
    let result = UIImageView(image: UIImage(braveSystemNamed: "brave.unlock")!)
    result.tintColor = .white
    result.contentMode = .scaleAspectFit
    result.setContentHuggingPriority(.required, for: .horizontal)
    result.setContentCompressionResistancePriority(.required, for: .horizontal)
    return result
  }()

  private let titleLabel: UILabel = {
    let result = UILabel()
    result.textColor = .white
    result.font = WalletConnectionView.regularFont
    result.adjustsFontForContentSizeCategory = true
    result.numberOfLines = 0
    result.text = Strings.Wallet.dappsConnectionNotificationTitle
    result.setContentCompressionResistancePriority(.required, for: .horizontal)
    result.setContentCompressionResistancePriority(.required, for: .vertical)
    if #available(iOS 15, *) {
      result.maximumContentSizeCategory = .accessibilityMedium
    }
    return result
  }()
  
  var origin: URLOrigin
  
  init(origin: URLOrigin) {
    self.origin = origin
    super.init(frame: .zero)
    setup()
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
      fatalError()
  }
  
  private func setup() {
    addSubview(stackView)
    stackView.snp.makeConstraints {
      $0.edges.equalToSuperview().inset(24)
    }
    stackView.addArrangedSubview(iconImageView)
    stackView.addArrangedSubview(titleLabel)
    
    iconImageView.snp.makeConstraints {
      $0.width.height.equalTo(20)
    }

    layer.backgroundColor = UIColor.braveBlurpleTint.cgColor
    layer.cornerRadius = 10
    
    titleLabel.attributedText = titleText(for: origin)
  }
  
  private static let regularFont: UIFont = .preferredFont(forTextStyle: .subheadline, weight: .regular)
  private static let emphasisedFont: UIFont = .preferredFont(forTextStyle: .subheadline, weight: .bold)
  
  private func titleText(for origin: URLOrigin) -> NSAttributedString {
    guard let originString = origin.url?.host else {
      return NSAttributedString(
        string: Strings.Wallet.dappsConnectionNotificationTitle,
        attributes: [.font: Self.regularFont]
      )
    }

    if let originEtldPlusOne = origin.url?.baseDomain {
      // eTLD+1 available, bold it
      let displayString = String.localizedStringWithFormat(Strings.Wallet.dappsConnectionNotificationOriginTitle, originString)
      let rangeForEldPlusOne = (displayString as NSString).range(of: originEtldPlusOne)
      let string = NSMutableAttributedString(
        string: displayString,
        attributes: [.font: Self.regularFont]
      )
      string.setAttributes([.font: Self.emphasisedFont], range: rangeForEldPlusOne)
      return string
    } else {
      // eTLD+1 unavailable
      let displayString = String.localizedStringWithFormat(Strings.Wallet.dappsConnectionNotificationOriginTitle, originString)
      return NSAttributedString(
        string: displayString,
        attributes: [.font: Self.regularFont]
      )
    }
  }
}
