/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class TabBarCell: UICollectionViewCell {
    let title = UILabel()
    let close = UIButton()
    let separatorLine = UIView()
    let separatorLineRight = UIView()
    weak var tabManager: TabManager?
    var currentIndex: Int = -1 {
        didSet {
            isSelected = currentIndex == tabManager?.currentDisplayedIndex
        }
    }
    weak var browser: Tab? {

        didSet {
            // FIXME: web page state delegate
            /*
             if let wv = self.browser?.webView {
             wv.delegatesForPageState.append(BraveWebView.Weak_WebPageStateDelegate(value: self))
             }
             */
        }
    }
    var closeTabCallback: ((Tab) -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear

        close.addTarget(self, action: #selector(closeTab), for: .touchUpInside)

        [close, title, separatorLine, separatorLineRight].forEach { contentView.addSubview($0) }

        title.textAlignment = .center
        title.snp.makeConstraints({ (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(self).inset(16)
            make.right.equalTo(close.snp.left)
        })

        close.setImage(UIImage(named: "close_tab_bar")?.withRenderingMode(.alwaysTemplate), for: .normal)
        close.snp.makeConstraints({ (make) in
            make.top.bottom.equalTo(self)
            make.right.equalTo(self).inset(2)
            make.width.equalTo(30)
        })

        close.tintColor = UIApplication.isInPrivateMode ? UIColor.white : UIColor.black

        // Close button is a bit wider to increase tap area, this aligns 'X' image closer to the right.
        close.imageEdgeInsets.left = 6

        separatorLine.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        separatorLine.snp.makeConstraints { (make) in
            make.left.equalTo(self)
            make.width.equalTo(0.5)
            make.height.equalTo(self)
            make.centerY.equalTo(self.snp.centerY)
        }

        separatorLineRight.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        separatorLineRight.isHidden = true
        separatorLineRight.snp.makeConstraints { (make) in
            make.right.equalTo(self)
            make.width.equalTo(0.5)
            make.height.equalTo(self)
            make.centerY.equalTo(self.snp.centerY)
        }

        isSelected = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet(selected) {
            if selected {
                title.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightSemibold)
                close.isHidden = false

                title.textColor = UIApplication.isInPrivateMode ? UIColor.white : UIColor.black
                close.tintColor = UIApplication.isInPrivateMode ? UIColor.white : UIColor.black
                backgroundColor = UIApplication.isInPrivateMode ? BraveUX.barsDarkBackgroundSolidColor : BraveUX.barsBackgroundSolidColor
            }
            else if currentIndex != tabManager?.currentDisplayedIndex {
                // prevent swipe and release outside- deselects cell.
                title.font = UIFont.systemFont(ofSize: 12)

                title.textColor = UIApplication.isInPrivateMode ? UIColor(white: 1.0, alpha: 0.4) : UIColor(white: 0.0, alpha: 0.4)
                close.isHidden = true
                close.tintColor = UIApplication.isInPrivateMode ? UIColor.white : UIColor.black
                backgroundColor = UIApplication.isInPrivateMode ? UIColor.black : UIColor.lightGray
            }
        }
    }

    func closeTab() {
        guard let tab = browser else { return }
        closeTabCallback?(tab)
    }

    fileprivate var titleUpdateScheduled = false
    func updateTitleThrottled(for tab: Tab) {
        if titleUpdateScheduled {
            return
        }
        titleUpdateScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.titleUpdateScheduled = false
            self?.title.text = tab.displayTitle
        }
    }
}
