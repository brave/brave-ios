/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class TabBarCell: UICollectionViewCell {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(closeTab), for: .touchUpInside)
        button.setImage(UIImage(named: "close_tab_bar")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIApplication.isInPrivateMode ? UIColor.white : UIColor.black
        // Close button is a bit wider to increase tap area, this aligns the 'X' image closer to the right.
        button.imageEdgeInsets.left = 6
        return button
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        return view
    }()

    lazy var separatorLineRight: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        view.isHidden = true
        return view
    }()

    var currentIndex: Int = -1 {
        didSet {
            isSelected = currentIndex == tabManager?.currentDisplayedIndex
        }
    }
    weak var tab: Tab?
    weak var tabManager: TabManager?

    var closeTabCallback: ((Tab) -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear

        [closeButton, titleLabel, separatorLine, separatorLineRight].forEach { contentView.addSubview($0) }
        initConstraints()

        isSelected = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initConstraints() {
        titleLabel.snp.makeConstraints{ make in
            make.top.bottom.equalTo(self)
            make.left.equalTo(self).inset(16)
            make.right.equalTo(closeButton.snp.left)
        }

        closeButton.snp.makeConstraints{ make in
            make.top.bottom.equalTo(self)
            make.right.equalTo(self).inset(2)
            make.width.equalTo(30)
        }

        separatorLine.snp.makeConstraints { make in
            make.left.equalTo(self)
            make.width.equalTo(0.5)
            make.height.equalTo(self)
            make.centerY.equalTo(self.snp.centerY)
        }

        separatorLineRight.snp.makeConstraints { make in
            make.right.equalTo(self)
            make.width.equalTo(0.5)
            make.height.equalTo(self)
            make.centerY.equalTo(self.snp.centerY)
        }
    }

    override var isSelected: Bool {
        didSet(selected) {
            closeButton.tintColor = UIApplication.isInPrivateMode ? UIColor.white : UIColor.black
            if selected {
                titleLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightSemibold)
                closeButton.isHidden = false
                titleLabel.textColor = UIApplication.isInPrivateMode ? UIColor.white : UIColor.black
                backgroundColor = UIApplication.isInPrivateMode ? BraveUX.barsDarkBackgroundSolidColor : BraveUX.barsBackgroundSolidColor
            }
            // Prevent swipe and release outside- deselects cell.
            else if currentIndex != tabManager?.currentDisplayedIndex {
                titleLabel.font = UIFont.systemFont(ofSize: 12)
                titleLabel.textColor = UIApplication.isInPrivateMode ? UIColor(white: 1.0, alpha: 0.4) : UIColor(white: 0.0, alpha: 0.4)
                closeButton.isHidden = true
                backgroundColor = UIApplication.isInPrivateMode ? UIColor.black : UIColor.lightGray
            }
        }
    }

    func closeTab() {
        guard let tab = tab else { return }
        closeTabCallback?(tab)
    }

    fileprivate var titleUpdateScheduled = false
    func updateTitleThrottled(for tab: Tab) {
        if titleUpdateScheduled {
            return
        }
        titleUpdateScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.titleUpdateScheduled = false
            strongSelf.titleLabel.text = tab.displayTitle
        }
    }
}
