/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

private struct ActivityStreamHighlightCellUX {
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.black : UIColor(rgb: 0x353535)
    static let BorderWidth: CGFloat = 0.5
    static let CellSideOffset = 20
    static let TitleLabelOffset = 2
    static let CellTopBottomOffset = 12
    static let SiteImageViewSize: CGSize = UIDevice.current.userInterfaceIdiom == .pad ? CGSize(width: 99, height: 120) : CGSize(width: 99, height: 90)
    static let StatusIconSize = 12
    static let FaviconSize = CGSize(width: 45, height: 45)
    static let DescriptionLabelColor = UIColor(rgb: 0x919191) // Not found in Photon colors
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CornerRadius: CGFloat = 3
    static let BorderColor = UIColor(white: 0, alpha: 0.1)
}

class ActivityStreamHighlightCell: UICollectionViewCell {

    fileprivate lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.MediumSizeHeavyWeightAS
        titleLabel.textColor = ActivityStreamHighlightCellUX.LabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 3
        return titleLabel
    }()

    fileprivate lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        descriptionLabel.textColor = ActivityStreamHighlightCellUX.DescriptionLabelColor
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 1
        return descriptionLabel
    }()

    fileprivate lazy var domainLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        descriptionLabel.textColor = ActivityStreamHighlightCellUX.DescriptionLabelColor
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 1
        descriptionLabel.setContentCompressionResistancePriority(1000, for: UILayoutConstraintAxis.vertical)
        return descriptionLabel
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.scaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.contentMode = UIViewContentMode.center
        siteImageView.layer.cornerRadius = ActivityStreamHighlightCellUX.CornerRadius
        siteImageView.layer.borderColor = ActivityStreamHighlightCellUX.BorderColor.cgColor
        siteImageView.layer.borderWidth = ActivityStreamHighlightCellUX.BorderWidth
        siteImageView.layer.masksToBounds = true
        return siteImageView
    }()

    fileprivate lazy var statusIcon: UIImageView = {
        let statusIcon = UIImageView()
        statusIcon.contentMode = UIViewContentMode.scaleAspectFit
        statusIcon.clipsToBounds = true
        statusIcon.layer.cornerRadius = ActivityStreamHighlightCellUX.CornerRadius
        return statusIcon
    }()

    fileprivate lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = ActivityStreamHighlightCellUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        isAccessibilityElement = true

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusIcon)
        contentView.addSubview(domainLabel)

        siteImageView.snp.makeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.trailing.equalTo(contentView)
            make.centerX.equalTo(contentView)
            make.height.equalTo(ActivityStreamHighlightCellUX.SiteImageViewSize)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        domainLabel.snp.makeConstraints { make in
            make.leading.equalTo(siteImageView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(siteImageView.snp.bottom).offset(5)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(siteImageView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(domainLabel.snp.bottom).offset(5)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(statusIcon.snp.trailing).offset(ActivityStreamHighlightCellUX.TitleLabelOffset)
            make.bottom.equalTo(contentView)
        }

        statusIcon.snp.makeConstraints { make in
            make.size.equalTo(ActivityStreamHighlightCellUX.StatusIconSize)
            make.centerY.equalTo(descriptionLabel.snp.centerY)
            make.leading.equalTo(siteImageView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.siteImageView.image = nil
        contentView.backgroundColor = UIColor.clear
        siteImageView.backgroundColor = UIColor.clear
    }

    func configureWithSite(_ site: Site) {
        if let mediaURLStr = site.metadata?.mediaURL,
            let mediaURL = URL(string: mediaURLStr) {
            self.siteImageView.sd_setImage(with: mediaURL)
            self.siteImageView.contentMode = .scaleAspectFill
        } else {
            let itemURL = site.tileURL
            self.siteImageView.setFavicon(forSite: site, onCompletion: { [weak self] (color, url)  in
                if itemURL == url {
                    self?.siteImageView.image = self?.siteImageView.image?.createScaled(ActivityStreamHighlightCellUX.FaviconSize)
                    self?.siteImageView.backgroundColor = color
                }
            })
            self.siteImageView.contentMode = .center
        }

        self.domainLabel.text = site.tileURL.hostSLD
        self.titleLabel.text = site.title.count <= 1 ? site.url : site.title

        if let bookmarked = site.bookmarked, bookmarked {
            self.descriptionLabel.text = Strings.HighlightBookmarkText
            self.statusIcon.image = UIImage(named: "context_bookmark")
        } else {
            self.descriptionLabel.text = Strings.HighlightVistedText
            self.statusIcon.image = UIImage(named: "context_viewed")
        }
    }

    func configureWithPocketStory(_ pocketStory: PocketStory) {
        self.siteImageView.sd_setImage(with: pocketStory.imageURL)
        self.siteImageView.contentMode = .scaleAspectFill

        self.domainLabel.text = pocketStory.domain
        self.titleLabel.text = pocketStory.title

        self.descriptionLabel.text = Strings.PocketTrendingText
        self.statusIcon.image = UIImage(named: "context_pocket")
    }
}

private struct HighlightIntroCellUX {
    static let margin: CGFloat = 20
    static let foxImageWidth: CGFloat = 168
}

class HighlightIntroCell: UICollectionViewCell {

    lazy var titleLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = DynamicFontHelper.defaultHelper.MediumSizeBoldFontAS
        textLabel.textColor = UIColor.black
        textLabel.numberOfLines = 1
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.8
        return textLabel
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = DynamicFontHelper.defaultHelper.MediumSizeRegularWeightAS
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)

        titleLabel.text = Strings.HighlightIntroTitle
        descriptionLabel.text = Strings.HighlightIntroDescription

        let titleInsets = UIEdgeInsets(top: HighlightIntroCellUX.margin, left: 0, bottom: 0, right: 0)
        titleLabel.snp.makeConstraints { make in
            make.leading.top.trailing.equalTo(self.contentView).inset(titleInsets)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(HighlightIntroCellUX.margin/2)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
