// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit
import BraveUI

class WelcomeViewSearchEnginesView: UIView {
    private struct DesignUX {
        static let padding = 16.0
        static let contentPadding = 30.0
        static let cornerRadius = 16.0
        static let buttonHeight = 48.0
    }
    
    private let scrollView = UIScrollView()
    
    private let contentView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = DesignUX.padding
        $0.layoutMargins = UIEdgeInsets(equalInset: DesignUX.contentPadding)
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        scrollView.contentLayoutGuide.snp.makeConstraints {
            $0.top.bottom.equalTo(contentView)
            $0.width.equalToSuperview()
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addButton(icon: UIImage, title: String, action: @escaping () -> Void) {
        let button = SearchEngineButton(icon: icon, title: title).then {
            $0.addAction(UIAction(identifier: .init(rawValue: "primary.action"), handler: { _ in
                action()
            }), for: .primaryActionTriggered)
        }
        
        contentView.addArrangedSubview(button)
    }
}

private class SearchEngineButton: RoundInterfaceButton {
    struct DesignUX {
        static let cornerRadius = 40.0
        static let contentPaddingX = 15.0
        static let contentPaddingY = 10.0
        static let iconSize = 24.0
    }
    
    private let contentView = UIStackView().then {
        $0.spacing = 10.0
        $0.layoutMargins = UIEdgeInsets(top: DesignUX.contentPaddingY,
                                        left: DesignUX.contentPaddingX,
                                        bottom: DesignUX.contentPaddingY,
                                        right: DesignUX.contentPaddingX)
        $0.isUserInteractionEnabled = false
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    private let iconView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let titleView = UILabel().then {
        $0.textAlignment = .left
        $0.textColor = .bravePrimary
        $0.font = .systemFont(ofSize: 17.0)
    }
    
    private let accessoryView = UIImageView().then {
        $0.contentMode = .center
        $0.image = #imageLiteral(resourceName: "welcome-view-search-engine-arrow")
    }
    
    init(icon: UIImage, title: String) {
        super.init(frame: .zero)
        
        iconView.image = icon
        titleView.text = title
        backgroundColor = .secondaryBraveBackground
        
        contentMode = .left
        addSubview(contentView)
        [iconView, titleView, accessoryView].forEach {
            self.contentView.addArrangedSubview($0)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        iconView.snp.makeConstraints {
            $0.width.equalTo(DesignUX.iconSize)
            $0.height.equalTo(DesignUX.iconSize)
        }
        
        accessoryView.snp.makeConstraints {
            $0.width.equalTo(DesignUX.iconSize)
            $0.height.equalTo(DesignUX.iconSize)
        }
        
        titleView.do {
            $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let roundedLayerName = "rounded.layer"
        
        let layers = contentView.layer.sublayers
        layers?.filter({ $0.name == roundedLayerName }).forEach {
            $0.removeFromSuperlayer()
        }
        
        let maskBounds = contentView.bounds
        let path = UIBezierPath(roundedRect: maskBounds,
                                byRoundingCorners: .allCorners,
                                cornerRadii: CGSize(width: DesignUX.cornerRadius,
                                                    height: DesignUX.cornerRadius))

        // Create the shape layer and set its path
        let maskLayer = CAShapeLayer().then {
            $0.frame = maskBounds
            $0.path = path.cgPath
        }

        let roundedLayer = CALayer().then {
            $0.backgroundColor = UIColor.secondaryBraveBackground.cgColor
            $0.frame = maskBounds
            $0.mask = maskLayer
            $0.name = roundedLayerName
        }

        contentView.layer.insertSublayer(roundedLayer, at: 0)
        
        layer.shadowColor = #colorLiteral(red: 0.4633028507, green: 0.4875121117, blue: 0.5066562891, alpha: 1).cgColor
        layer.shadowOpacity = 0.36
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = DesignUX.cornerRadius
    }
}
