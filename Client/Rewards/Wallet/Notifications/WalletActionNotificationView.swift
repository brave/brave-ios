/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct WalletActionNotification {
  struct Category {
    let icon: UIImage
    let title: String
    let action: String
    
    static let grant = Category(
      icon: UIImage(imageLiteralResourceName: "icn-grant"),
      title: RewardsStrings.NotificationTokenGrantTitle,
      action: RewardsStrings.CLAIM.uppercased()
    )
    
    static let tipsProcessed = Category(
      icon: UIImage(imageLiteralResourceName: "icn-contribute"),
      title: RewardsStrings.NotificationRecurringTipTitle,
      action: RewardsStrings.OK.uppercased()
    )
    
    static let contribute = Category(
      icon: UIImage(imageLiteralResourceName: "icn-contribute"),
      title: RewardsStrings.NotificationAutoContributeTitle,
      action: RewardsStrings.OK.uppercased()
    )
    
    static let verifiedPublisher = Category(
      icon: UIImage(imageLiteralResourceName: "icn-contribute"),
      title: RewardsStrings.NotificationPendingContributionTitle,
      action: RewardsStrings.OK.uppercased()
    )
  }
  
  let category: Category
  let body: String
  let date: Date
}

class WalletActionNotificationView: WalletNotificationView {
  
  let notification: WalletActionNotification
  
  let actionButton = ActionButton()
  
  init(notification: WalletActionNotification) {
    self.notification = notification
    super.init(frame: .zero)
    
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = 15.0
    
    iconImageView.image = notification.category.icon
    let bodyLabel = UILabel().then {
      $0.numberOfLines = 0
      $0.textAlignment = .center
      $0.attributedText = bodyAttributedString()
    }
    actionButton.do {
      $0.backgroundColor = RewardsBraveUX.braveOrange
      $0.layer.borderWidth = 0.0
      $0.setTitle(notification.category.action, for: .normal)
      $0.titleLabel?.font = .systemFont(ofSize: 14.0, weight: .bold)
      $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 13, bottom: 6, right: 13)
    }
    stackView.addArrangedSubview(bodyLabel)
    stackView.setCustomSpacing(15.0, after: bodyLabel)
    stackView.addArrangedSubview(actionButton)
  }
  
  /// Forms the body string: "{title} | {body} {short-date}"
  private func bodyAttributedString() -> NSAttributedString {
    let string = NSMutableAttributedString()
    string.append(NSAttributedString(
      string: notification.category.title,
      attributes: [
        .font: UIFont.systemFont(ofSize: 14.0, weight: .medium),
        .foregroundColor: UIColor.black,
      ]
    ))
    string.append(NSAttributedString(
      string: " | ",
      attributes: [
        .font: UIFont.systemFont(ofSize: 14.0),
        .foregroundColor: UIColor.gray,
      ]
    ))
    string.append(NSAttributedString(
      string: notification.body,
      attributes: [
        .font: UIFont.systemFont(ofSize: 14.0),
        .foregroundColor: RewardsPalette.grey100,
      ]
    ))
    string.append(NSAttributedString(
      string: " ",
      attributes: [ .font: UIFont.systemFont(ofSize: 14.0) ]
    ))
    let dateFormatter = DateFormatter().then {
      $0.dateFormat = "MMM d"
    }
    string.append(NSAttributedString(
      string: dateFormatter.string(from: notification.date),
      attributes: [
        .font: UIFont.systemFont(ofSize: 14.0),
        .foregroundColor: RewardsPalette.grey200,
      ]
    ))
    return string
  }
}
