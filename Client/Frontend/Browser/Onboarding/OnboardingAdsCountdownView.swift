// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import Lottie

extension OnboardingAdsCountdownViewController {
    
    private struct UX {
        /// A negative spacing is needed to make rounded corners for details view visible.
        static let negativeSpacing: CGFloat = -16
        static let descriptionContentInset: CGFloat = 32
        static let linkColor: UIColor = BraveUX.BraveOrange
    }
    
    class View: UIView {
        
        let finishedButton = CommonViews.primaryButton(text: Strings.OBAgreeButton).then {
            $0.accessibilityIdentifier = "OnboardingRewardsAgreementViewController.AgreeButton"
            $0.backgroundColor = BraveUX.BraveOrange.withAlphaComponent(0.7)
            $0.isEnabled = false
        }
        
        let invalidButton = CommonViews.secondaryButton().then {
            $0.accessibilityIdentifier = "OnboardingRewardsAgreementViewController.SkipButton"
        }
        
        private let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = UX.negativeSpacing
        }
        
        let imageView = AnimationView(name: "onboarding-rewards").then {
            $0.contentMode = .scaleAspectFit
            $0.backgroundColor = #colorLiteral(red: 0.1176470588, green: 0.1254901961, blue: 0.1607843137, alpha: 1)
            $0.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            $0.backgroundBehavior = .pauseAndRestore
            $0.loopMode = .loop
            $0.play()
        }
        
        private let descriptionView = UIView().then {
            $0.layer.cornerRadius = 12
            $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        
        private let descriptionStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 32
        }
        
        private let titleLabel = CommonViews.primaryText(Strings.OBRewardsAgreementTitle).then {
            $0.numberOfLines = 0
        }
        
        let countdownView = AdsCountdownGradientView()
        
        let countdownLabel = UILabel().then {
            $0.font = UIFont.systemFont(ofSize: 54.0)
            $0.textColor = UIColor(rgb: 0x4F30AB)
            $0.text = "3"
        }
        
        private let buttonsStackView = UIStackView().then {
            $0.distribution = .equalCentering
            $0.isHidden = true
        }
        
        override var backgroundColor: UIColor? {
            didSet {
                // Needed to support rounding
                descriptionView.backgroundColor = backgroundColor
            }
        }
        
        init() {
            super.init(frame: .zero)
            
            [imageView, descriptionView].forEach(mainStackView.addArrangedSubview(_:))

            [finishedButton, invalidButton, UIView.spacer(.horizontal, amount: 0)]
                .forEach(buttonsStackView.addArrangedSubview(_:))
            
            [titleLabel, countdownView, buttonsStackView].forEach(descriptionStackView.addArrangedSubview(_:))
            
            addSubview(mainStackView)
            descriptionView.addSubview(descriptionStackView)
            
            countdownView.addSubview(countdownLabel)
            
            mainStackView.snp.makeConstraints {
                $0.leading.equalTo(self.safeArea.leading)
                $0.trailing.equalTo(self.safeArea.trailing)
                $0.bottom.equalTo(self.safeArea.bottom)
                $0.top.equalTo(self) // extend the view undeneath the safe area/notch
            }
            
            descriptionStackView.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UX.descriptionContentInset)
            }
            
            countdownView.snp.makeConstraints {
                $0.width.equalTo(156.0)
                $0.height.equalTo(156.0)
            }
            
            countdownLabel.snp.makeConstraints {
                $0.centerX.equalTo(countdownView.snp.centerX)
                $0.centerY.equalTo(countdownView.snp.centerY)
            }
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) { fatalError() }
    }
}

class AdsCountdownGradientView: UIView {
    private struct UX {
        static let strokeThickness: CGFloat = 5.0
        static let ballRadius: CGFloat = 10.0
        static let backgroundGray = UIColor(rgb: 0xCED4DA)
        static let gradientPurple = UIColor(rgb: 0x4F30AB)
        static let gradientPink = UIColor(rgb: 0xFF1893)
        static let gradientOrange = UIColor(rgb: 0xFA7250)
    }
    
    private let gradientLayer = { () -> CAGradientLayer in
        let layer = CAGradientLayer()
        layer.type = .conic
        layer.colors = [UX.gradientPurple,
                        UX.gradientPurple,
                        UX.gradientPink,
                        UX.gradientOrange,
                        UX.gradientOrange,
                        UX.gradientOrange].map({ $0.cgColor })
        
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 0.5, y: 0)
        return layer
    }()
    
    private let gradientBallLayer = { () -> CAGradientLayer in
        let layer = CAGradientLayer()
        layer.type = .conic
        layer.colors = [UX.gradientPurple, UX.gradientPurple].map({ $0.cgColor })
        
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 0.5, y: 0)
        return layer
    }()
    
    private let shapeLayer = { () -> CAShapeLayer in
        let layer = CAShapeLayer()
        layer.lineWidth = UX.strokeThickness
        layer.fillColor = nil
        layer.strokeColor = UX.backgroundGray.cgColor
        layer.shouldRasterize = true
        layer.strokeStart = 0.0
        layer.strokeEnd = 1.0
        return layer
    }()
    
    private let strokeLayer = { () -> CAShapeLayer in
        let layer = CAShapeLayer()
        layer.lineWidth = UX.strokeThickness
        layer.fillColor = nil
        layer.strokeColor = UIColor.white.cgColor
        layer.shouldRasterize = true
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
        return layer
    }()
    
    private let strokeBallLayer = { () -> CALayer in
        let layer = CALayer()
        layer.backgroundColor = UIColor.white.cgColor
        layer.shouldRasterize = true
        return layer
    }()
    
    private func createAnimationPath() -> UIBezierPath {
        let DEGREES_TO_RADIANS = { (degrees: CGFloat) -> CGFloat in
            return (.pi * degrees) / 180.0
        }
        
        let startAngle = DEGREES_TO_RADIANS(-90.0)
        let endAngle = DEGREES_TO_RADIANS(270.0)
        let center = CGPoint(x: bounds.origin.x + (bounds.size.width / 2.0), y: bounds.origin.y + (bounds.size.height / 2.0))

        let insetBounds = bounds.insetBy(dx: UX.ballRadius * 2.0, dy: UX.ballRadius * 2.0)
        let radius = min(insetBounds.width, insetBounds.height) / 2.0
        return UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        //Layout shapeLayer
        shapeLayer.removeFromSuperlayer()
        shapeLayer.frame = bounds
        shapeLayer.path = createAnimationPath().cgPath
        layer.addSublayer(shapeLayer)
        
        //Layout strokeLayer
        strokeLayer.removeFromSuperlayer()
        strokeLayer.frame = bounds
        strokeLayer.path = createAnimationPath().cgPath
        
        //Layout gradientLayer
        gradientLayer.removeFromSuperlayer()
        gradientLayer.mask = strokeLayer
        gradientLayer.frame = bounds
        layer.addSublayer(gradientLayer)
        
        //Layout strokeBallLayer
        strokeBallLayer.removeFromSuperlayer()
        strokeBallLayer.frame = CGRect(x: (bounds.origin.x + (bounds.size.width / 2.0)) - UX.ballRadius, y: UX.ballRadius, width: UX.ballRadius * 2.0, height: UX.ballRadius * 2.0)
        strokeBallLayer.cornerRadius = UX.ballRadius
        
        //Layout gradientBallLayer
        gradientBallLayer.removeFromSuperlayer()
        gradientBallLayer.mask = strokeBallLayer
        gradientBallLayer.frame = bounds
        layer.addSublayer(gradientBallLayer)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
    
    func animate(from startOffset: CGFloat, to endOffset: CGFloat, duration: CFTimeInterval) {
        CATransaction.begin()
        
        let backgroundAnimation = CABasicAnimation(keyPath: "strokeStart")
        backgroundAnimation.duration = duration
        backgroundAnimation.isRemovedOnCompletion = false
        backgroundAnimation.fromValue = startOffset
        backgroundAnimation.toValue = endOffset
        backgroundAnimation.fillMode = .forwards
        backgroundAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.duration = duration
        strokeAnimation.isRemovedOnCompletion = false
        strokeAnimation.fromValue = startOffset
        strokeAnimation.toValue = endOffset
        strokeAnimation.fillMode = .forwards
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        let ballAnimation = CAKeyframeAnimation(keyPath: "position")
        ballAnimation.duration = duration
        ballAnimation.isRemovedOnCompletion = false
        ballAnimation.calculationMode = .paced
        ballAnimation.path = createAnimationPath().cgPath
        ballAnimation.fillMode = .forwards
        ballAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        let gradientAnimationColours = [UX.gradientOrange,
                                        UX.gradientOrange,
                                        UX.gradientPink,
                                        UX.gradientOrange,
                                        UX.gradientOrange,
                                        UX.gradientOrange].map({ $0.cgColor })
        
        let gradientAnimation = CABasicAnimation(keyPath: "colors")
        gradientAnimation.duration = duration
        gradientAnimation.isRemovedOnCompletion = false
        gradientAnimation.fromValue = gradientLayer.colors
        gradientAnimation.toValue = gradientAnimationColours
        gradientAnimation.fillMode = .forwards
        gradientAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        CATransaction.setCompletionBlock({
            self.strokeLayer.strokeEnd = endOffset
            self.shapeLayer.strokeStart = endOffset
            self.gradientBallLayer.colors = gradientAnimationColours
            
            self.shapeLayer.removeAnimation(forKey: "backgroundAnimation")
            self.strokeLayer.removeAnimation(forKey: "strokeAnimation")
            self.strokeBallLayer.removeAnimation(forKey: "ballAnimation")
            self.gradientBallLayer.removeAnimation(forKey: "gradientAnimation")
        })
        
        shapeLayer.add(backgroundAnimation, forKey: "backgroundAnimation")
        strokeLayer.add(strokeAnimation, forKey: "strokeAnimation")
        strokeBallLayer.add(ballAnimation, forKey: "ballAnimation")
        gradientBallLayer.add(gradientAnimation, forKey: "gradientAnimation")
        
        CATransaction.commit()
    }
}
