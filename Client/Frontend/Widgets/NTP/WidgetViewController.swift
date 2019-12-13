/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

protocol WidgetViewControllerDelegate {
    func shouldHideWidget<Widget: WidgetViewController>(widget: Widget)
}

class WidgetViewController: UIView {
    var delegate: WidgetViewControllerDelegate?
    
    let gradientFill = CAGradientLayer()
    let stateViewContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 8
        layer.masksToBounds = true
        layer.addSublayer(gradientFill)
        
        addSubview(stateViewContainer)
        stateViewContainer.snp.makeConstraints {
            $0.edges.equalTo(self).inset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        gradientFill.frame = bounds
    }
}
