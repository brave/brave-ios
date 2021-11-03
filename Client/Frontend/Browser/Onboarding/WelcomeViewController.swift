// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit

class WelcomeViewController: UIViewController {
    private let backgroundImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "LaunchBackground")
        $0.contentMode = .scaleAspectFill
    }
    
    private let topImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "welcome-view-top-image")
        $0.contentMode = .scaleAspectFill
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let calloutContainer = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = -95.0
    }
    
    private let calloutView = WelcomeViewCallout(pointsUp: false)
    
    private let iconView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "welcome-view-icon")
        $0.contentMode = .scaleAspectFit
    }
    
    private let bottomImageView = UIImageView().then {
        $0.image = #imageLiteral(resourceName: "welcome-view-bottom-image")
        $0.contentMode = .scaleAspectFill
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [backgroundImageView, topImageView, bottomImageView, calloutContainer].forEach {
            view.addSubview($0)
        }
        
        [calloutView, iconView].forEach {
            calloutContainer.addArrangedSubview($0)
        }
        
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        topImageView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
        }
        
        calloutContainer.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
        
        bottomImageView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        calloutView.setContentView({() -> UIView  in
            let title = UILabel().then {
                $0.text = "Welcome to Brave!"
                $0.textColor = .black
                $0.textAlignment = .center
                $0.font = .systemFont(ofSize: 28.0)
            }
            return title
        }())
    }
}

private class WelcomeViewCallout: UIView {
    private struct DesignUX {
        static let padding = 20.0
        static let contentPadding = 32.0
        static let cornerRadius = 16.0
    }
    
    private let arrowView = CalloutArrowView().then {
        $0.backgroundColor = .white
    }
    
    private let contentView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.layoutMargins = UIEdgeInsets(equalInset: DesignUX.contentPadding)
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    init(pointsUp: Bool) {
        super.init(frame: .zero)
        
        if pointsUp {
            addSubview(arrowView)
            addSubview(contentView)
            
            arrowView.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalToSuperview()
                $0.width.equalTo(20.0)
                $0.height.equalTo(13.0)
            }
            
            contentView.snp.makeConstraints {
                $0.top.equalTo(arrowView.snp.bottom)
                $0.leading.greaterThanOrEqualToSuperview().offset(DesignUX.padding)
                $0.trailing.lessThanOrEqualToSuperview().offset(-DesignUX.padding)
                $0.centerX.equalToSuperview()
                $0.leading.bottom.equalToSuperview()
            }
        } else {
            addSubview(contentView)
            addSubview(arrowView)
            arrowView.transform = CGAffineTransform.identity.rotated(by: .pi)
            
            arrowView.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.bottom.equalToSuperview()
                $0.width.equalTo(20.0)
                $0.height.equalTo(13.0)
            }
            
            contentView.snp.makeConstraints {
                $0.leading.greaterThanOrEqualToSuperview().offset(DesignUX.padding)
                $0.trailing.lessThanOrEqualToSuperview().offset(-DesignUX.padding)
                $0.centerX.equalToSuperview()
                $0.top.equalToSuperview()
                $0.bottom.equalTo(arrowView.snp.top)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
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
            $0.backgroundColor = UIColor.white.cgColor
            $0.frame = maskBounds
            $0.mask = maskLayer
        }

        contentView.layer.insertSublayer(roundedLayer, at: 0)
    }
    
    func setContentView(_ view: UIView) {
        contentView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        contentView.addArrangedSubview(view.then {
            $0.setContentHuggingPriority(.required, for: .vertical)
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
        })
    }
}

private class CalloutArrowView: UIView {
    private let maskLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        maskLayer.frame = bounds
        maskLayer.path = createTrianglePath(rect: bounds).cgPath
        layer.mask = maskLayer
    }
    
    private func createTrianglePath(rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        
        // Middle Top
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        
        // Bottom Left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        // Bottom Right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        // Middle Top
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}
