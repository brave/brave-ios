/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

class WidgetsView: UIScrollView {
    private let stackView = UIStackView()
    private let binanceWidget = BinanceWidgetViewController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        alwaysBounceVertical = true
        alwaysBounceHorizontal = false
        isPagingEnabled = false
        isDirectionalLockEnabled = true
        keyboardDismissMode = .onDrag
        
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 20
        stackView.addArrangedSubview(binanceWidget)
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.topMargin.equalTo(40)
            $0.centerX.equalToSuperview()
        }
        
        binanceWidget.delegate = self
        binanceWidget.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 312, height: 245))
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WidgetsView: WidgetViewControllerDelegate {
    func shouldHideWidget<Widget>(widget: Widget) where Widget: WidgetViewController {
        if widget.isKind(of: BinanceWidgetViewController.self) {
            // close messaging for binance widget
            widget.isHidden = true
        }
    }
}
