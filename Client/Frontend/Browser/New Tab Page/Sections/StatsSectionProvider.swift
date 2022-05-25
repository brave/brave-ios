// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveUI
import UIKit

class StatsSectionProvider: NSObject, NTPSectionProvider {
  let action: () -> Void
  
  init(action: @escaping () -> Void) {
    self.action = action
  }
  
  @objc private func tappedButton() {
    action()
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 1
  }
  
  func registerCells(to collectionView: UICollectionView) {
    collectionView.register(NewTabCenteredCollectionViewCell<BraveShieldStatsView>.self)
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(for: indexPath) as NewTabCenteredCollectionViewCell<BraveShieldStatsView>
    cell.view.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    var size = fittingSizeForCollectionView(collectionView, section: indexPath.section)
    size.height = 110
    return size
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    
    return UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
  }
}

class BraveShieldStatsView: SpringButton {
  private lazy var adsStatView: StatView = {
    let statView = StatView(frame: CGRect.zero)
    statView.title = Strings.shieldsAdAndTrackerStats.capitalized
    statView.color = .statsAdsBlockedTint
    return statView
  }()
  
  private lazy var dataSavedStatView: StatView = {
    let statView = StatView(frame: .zero)
    statView.title = Strings.dataSavedStat
    statView.color = .statsDataSavedTint
    return statView
  }()
  
  private lazy var timeStatView: StatView = {
    let statView = StatView(frame: .zero)
    statView.title = Strings.shieldsTimeStats
    statView.color = .statsTimeSavedTint
    return statView
  }()
  
  private let statsStackView = UIStackView().then {
    $0.distribution = .fillEqually
    $0.spacing = 8
  }
  
  private let topStackView = UIStackView().then {
    $0.distribution = .equalSpacing
    $0.alignment = .center
    $0.isLayoutMarginsRelativeArrangement = true
    $0.directionalLayoutMargins = .init(.init(top: 8, leading: 0, bottom: -4, trailing: 0))
  }
  
  private let contentStackView = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
    $0.isLayoutMarginsRelativeArrangement = true
    $0.directionalLayoutMargins = .init(.init(top: 0, leading: 16, bottom: 16, trailing: 16))
  }
  
  private let privacyReportLabel = UILabel().then {
    let image = UIImage(named: "privacy_reports_shield", in: .current, compatibleWith: nil)!.template
    $0.textColor = .white
    $0.textAlignment = .center
    
    $0.attributedText = {
      let imageAttachment = NSTextAttachment().then {
        $0.image = image
        if let image = $0.image {
          $0.bounds = .init(x: 0, y: -3, width: image.size.width, height: image.size.height)
        }
      }
      
      var string = NSMutableAttributedString(attachment: imageAttachment)
      
      let padding = NSTextAttachment()
      padding.bounds = CGRect(width: 6, height: 0)
      
      string.append(NSAttributedString(attachment: padding))
      
      string.append(NSMutableAttributedString(
        string: Strings.PrivacyHub.privacyReportsTitle,
        attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .medium)]
      ))
      return string
    }()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    if !PrivateBrowsingManager.shared.isPrivateBrowsing {
      let background = UIView()
      background.backgroundColor = .init(white: 0, alpha: 0.25)
      background.layer.cornerRadius = 12
      background.layer.cornerCurve = .continuous
      background.isUserInteractionEnabled = false
      insertSubview(background, at: 0)
      background.snp.makeConstraints {
        $0.edges.equalToSuperview()
      }
      
      let image = UIImageView(image: UIImage(named: "privacy_reports_3dots", in: .current, compatibleWith: nil)!.template)
      image.tintColor = .white
      topStackView.addStackViewItems(.view(privacyReportLabel), .view(image))
    }
    
    isEnabled = !PrivateBrowsingManager.shared.isPrivateBrowsing
    statsStackView.addStackViewItems(.view(adsStatView), .view(dataSavedStatView), .view(timeStatView))
    contentStackView.addStackViewItems(.view(topStackView), .view(statsStackView))
    addSubview(contentStackView)
    
    contentStackView.isUserInteractionEnabled = false
    update()
    
    contentStackView.snp.makeConstraints {
      $0.edges.equalToSuperview()
      $0.width.equalTo(640)
    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(update), name: NSNotification.Name(rawValue: BraveGlobalShieldStats.didUpdateNotification), object: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc private func update() {
    adsStatView.stat = (BraveGlobalShieldStats.shared.adblock + BraveGlobalShieldStats.shared.trackingProtection).kFormattedNumber
    dataSavedStatView.stat = BraveGlobalShieldStats.shared.dataSaved
    timeStatView.stat = BraveGlobalShieldStats.shared.timeSaved
  }
}

private class StatView: UIView {
  var color: UIColor = .braveLabel {
    didSet {
      statLabel.textColor = color
    }
  }
  
  var stat: String = "" {
    didSet {
      statLabel.text = "\(stat)"
    }
  }
  
  var title: String = "" {
    didSet {
      titleLabel.text = "\(title)"
    }
  }
  
  fileprivate var statLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 32, weight: UIFont.Weight.medium)
    label.minimumScaleFactor = 0.5
    label.adjustsFontSizeToFitWidth = true
    return label
  }()
  
  fileprivate var titleLabel: UILabel = {
    let label = UILabel()
    label.textColor = .white
    label.textAlignment = .center
    label.numberOfLines = 0
    label.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.medium)
    return label
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.alignment = .center
    
    stackView.addStackViewItems(.view(statLabel), .view(titleLabel))
    
    addSubview(stackView)
    
    stackView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
