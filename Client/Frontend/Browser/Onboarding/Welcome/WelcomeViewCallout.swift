// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit
import BraveUI
import pop

enum WelcomeViewCalloutState {
    case welcome(title: String)
    case privacy(title: String, details: String, buttonTitle: String, action: () -> Void)
    case defaultBrowser(title: String, details: String, primaryButtonTitle: String, secondaryButtonTitle: String, primaryAction: () -> Void, secondaryAction: () -> Void)
    case defaultBrowserWarning(title: String, details: String, primaryButtonTitle: String, secondaryButtonTitle: String, primaryAction: () -> Void, secondaryAction: () -> Void)
    case ready(title: String, details: String, moreDetails: String)
}

class WelcomeViewCallout: UIView {
    private struct DesignUX {
        static let padding = 20.0
        static let contentPadding = 30.0
        static let cornerRadius = 16.0
    }
    
    private let backgroundView = RoundedBackgroundView(cornerRadius: DesignUX.cornerRadius)
    
    private let arrowView = CalloutArrowView().then {
        $0.backgroundColor = .secondaryBraveBackground
    }
    
    private let contentView = UIStackView().then {
        $0.axis = .vertical
        $0.layoutMargins = UIEdgeInsets(equalInset: DesignUX.contentPadding)
        $0.isLayoutMarginsRelativeArrangement = true
    }
    
    // MARK: - Content
    private let titleLabel = UILabel().then {
        $0.textColor = .bravePrimary
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private let detailsLabel = UILabel().then {
        $0.textColor = .bravePrimary
        $0.textAlignment = .left
        $0.numberOfLines = 0
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private let primaryButton = RoundInterfaceButton(type: .custom).then {
        $0.setTitleColor(.secondaryBraveBackground, for: .normal)
        $0.backgroundColor = .braveBlurple
        $0.setTitle(" ", for: .normal)
    }
    
    private let secondaryButtonContentView = UIStackView().then {
        $0.axis = .horizontal
    }
    
    private let secondaryLabel = UILabel().then {
        $0.textColor = .bravePrimary
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private let secondaryButton = RoundInterfaceButton(type: .custom).then {
        $0.setTitleColor(.braveBlurple, for: .normal)
        $0.backgroundColor = .clear
        $0.setTitle(" ", for: .normal)
    }
    
    // MARK: - State
    private(set) var state: WelcomeViewCalloutState?
    
    init(pointsUp: Bool) {
        super.init(frame: .zero)
        doLayout(pointsUp: pointsUp)
        
        [titleLabel, detailsLabel, primaryButton, secondaryButtonContentView].forEach {
            contentView.addArrangedSubview($0)
            
            $0.alpha = 0.0
            $0.isHidden = true
        }
        
        [primaryButton, secondaryButton].forEach {
            $0.contentMode = pointsUp ? .bottom : .top
            $0.snp.makeConstraints {
                $0.height.equalTo(44.0)
            }
        }
        
        secondaryButtonContentView.addArrangedSubview(secondaryLabel)
        secondaryButtonContentView.addArrangedSubview(secondaryButton)
        
        [titleLabel, detailsLabel].forEach {
            $0.contentMode = pointsUp ? .bottom : .top
            
            $0.snp.makeConstraints {
                $0.height.greaterThanOrEqualTo(17.0)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.shadowColor = #colorLiteral(red: 0.4633028507, green: 0.4875121117, blue: 0.5066562891, alpha: 1).cgColor
        layer.shadowOpacity = 0.36
        layer.shadowOffset = CGSize(width: 5, height: 5)
        layer.shadowRadius = DesignUX.cornerRadius
    }
    
    private func doLayout(pointsUp: Bool) {
        arrowView.removeFromSuperview()
        contentView.removeFromSuperview()
        
        if pointsUp {
            addSubview(backgroundView)
            addSubview(arrowView)
            addSubview(contentView)
            arrowView.transform = .identity
            
            arrowView.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalToSuperview()
                $0.width.equalTo(20.0)
                $0.height.equalTo(13.0)
            }
            
            contentView.snp.makeConstraints {
                $0.top.equalTo(arrowView.snp.bottom)
                $0.leading.trailing.equalToSuperview().inset(DesignUX.padding)
                $0.bottom.equalToSuperview()
            }
        } else {
            addSubview(backgroundView)
            addSubview(contentView)
            addSubview(arrowView)
            arrowView.transform = CGAffineTransform.identity.rotated(by: .pi)
            
            contentView.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(DesignUX.padding)
                $0.top.equalToSuperview()
            }
            
            arrowView.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalTo(contentView.snp.bottom)
                $0.bottom.equalToSuperview()
                $0.width.equalTo(20.0)
                $0.height.equalTo(13.0)
            }
        }
        
        backgroundView.snp.makeConstraints {
            $0.edges.equalTo(contentView.snp.edges)
        }
    }
    
    func animateFromCopy(view: WelcomeViewCallout, duration: TimeInterval, delay: TimeInterval) {
        let views = [backgroundView, contentView, arrowView]
        let otherViews = [view.backgroundView, view.contentView, view.arrowView]
        
        for e in views.enumerated() {
            POPBasicAnimation(propertyNamed: kPOPViewFrame)?.do {
                $0.fromValue = e.element.frame
                $0.toValue = otherViews[e.offset].frame
                $0.duration = duration
                $0.beginTime = CACurrentMediaTime() + delay
                e.element.layer.pop_add($0, forKey: "frame")
            }
        }
    }
    
    func setState(state: WelcomeViewCalloutState) {
        self.state = state
        
        if case .ready = state {
            doLayout(pointsUp: true)
        }
        
        primaryButton.removeAction(identifiedBy: .init(rawValue: "primary.action"), for: .primaryActionTriggered)
        secondaryButton.removeAction(identifiedBy: .init(rawValue: "secondary.action"), for: .primaryActionTriggered)
        
        switch state {
        case .welcome(let title):
            titleLabel.do {
                $0.text = title
                $0.textAlignment = .center
                $0.font = .preferredFont(for: .title1, weight: .semibold)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            detailsLabel.do {
                $0.alpha = 0.0
                $0.isHidden = true
            }
            
            primaryButton.do {
                $0.alpha = 0.0
                $0.isHidden = true
            }
            
            secondaryButton.do {
                $0.alpha = 0.0
                $0.isHidden = true
            }
            
        case .privacy(let title, let details, let buttonTitle, let action):
            titleLabel.do {
                $0.text = title
                $0.textAlignment = .left
                $0.font = .preferredFont(for: .title3, weight: .bold)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            detailsLabel.do {
                $0.text = details
                $0.font = .preferredFont(forTextStyle: .body)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            primaryButton.do {
                $0.setTitle(buttonTitle, for: .normal)
                $0.titleLabel?.font = .preferredFont(forTextStyle: .body)
                $0.addAction(UIAction(identifier: .init(rawValue: "primary.action"), handler: { _ in
                    action()
                }), for: .touchUpInside)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            secondaryButton.do {
                $0.alpha = 0.0
                $0.isHidden = true
            }
            
            contentView.setCustomSpacing(8.0, after: titleLabel)
            contentView.setCustomSpacing(24.0, after: detailsLabel)
            
        case .defaultBrowser(let title, let details, let primaryButtonTitle, let secondaryButtonTitle, let primaryAction, let secondaryAction):
            contentView.do {
                $0.layoutMargins = UIEdgeInsets(top: 30, left: 30, bottom: 15, right: 30)
            }
            titleLabel.do {
                $0.text = title
                $0.textAlignment = .left
                $0.font = .preferredFont(for: .title3, weight: .bold)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            detailsLabel.do {
                $0.text = details
                $0.font = .preferredFont(forTextStyle: .body)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            primaryButton.do {
                $0.setTitle(primaryButtonTitle, for: .normal)
                $0.titleLabel?.font = .preferredFont(forTextStyle: .body)
                $0.addAction(UIAction(identifier: .init(rawValue: "primary.action"), handler: { _ in
                    primaryAction()
                }), for: .touchUpInside)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            secondaryButtonContentView.do {
                $0.alpha = 1.0
                $0.isHidden = false
            }
                
            secondaryButton.do {
                $0.setTitle(secondaryButtonTitle, for: .normal)
                $0.titleLabel?.font = .preferredFont(for: .body, weight: .bold)
                $0.addAction(UIAction(identifier: .init(rawValue: "secondary.action"), handler: { _ in
                    secondaryAction()
                }), for: .touchUpInside)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            contentView.setCustomSpacing(8.0, after: titleLabel)
            contentView.setCustomSpacing(24.0, after: detailsLabel)
            contentView.setCustomSpacing(10.0, after: primaryButton)
        case .defaultBrowserWarning(let title, let details, let primaryButtonTitle, let secondaryButtonTitle, let primaryAction, let secondaryAction):
            contentView.do {
                $0.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 20)
            }
                
            titleLabel.do {
                $0.text = title
                $0.textAlignment = .left
                $0.font = .systemFont(ofSize: 17.0, weight: .semibold)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            detailsLabel.do {
                $0.text = details
                $0.font = .systemFont(ofSize: 17.0)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            primaryButton.do {
                $0.setTitle(primaryButtonTitle, for: .normal)
                $0.titleLabel?.font = .systemFont(ofSize: 17.0)
                $0.addAction(UIAction(identifier: .init(rawValue: "primary.action"), handler: { _ in
                    primaryAction()
                }), for: .touchUpInside)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            secondaryButtonContentView.do {
                $0.alpha = 1.0
                $0.isHidden = false
            }
                
            secondaryLabel.do {
                $0.text = "Already default?"
                $0.textAlignment = .left
                $0.font = .systemFont(ofSize: 17.0, weight: .medium)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            secondaryButton.do {
                $0.setTitle(secondaryButtonTitle, for: .normal)
                    $0.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .bold)
                $0.addAction(UIAction(identifier: .init(rawValue: "secondary.action"), handler: { _ in
                    secondaryAction()
                }), for: .touchUpInside)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            contentView.setCustomSpacing(8.0, after: titleLabel)
            contentView.setCustomSpacing(24.0, after: detailsLabel)
            contentView.setCustomSpacing(10.0, after: primaryButton)
        case .ready(let title, let details, let moreDetails):
            titleLabel.do {
                $0.text = title
                $0.textAlignment = .left
                $0.font = .systemFont(ofSize: 17.0, weight: .medium)
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            detailsLabel.do {
                $0.text = "\(details)\n\(moreDetails)"
                $0.alpha = 1.0
                $0.isHidden = false
            }
            
            primaryButton.do {
                $0.alpha = 0.0
                $0.isHidden = true
            }
            
            secondaryButton.do {
                $0.alpha = 0.0
                $0.isHidden = true
            }
            
            contentView.setCustomSpacing(8.0, after: titleLabel)
            contentView.setCustomSpacing(0.0, after: detailsLabel)
            contentView.setCustomSpacing(0.0, after: primaryButton)
        }
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

private class RoundedBackgroundView: UIView {
    private let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        layer.backgroundColor = UIColor.secondaryBraveBackground.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
