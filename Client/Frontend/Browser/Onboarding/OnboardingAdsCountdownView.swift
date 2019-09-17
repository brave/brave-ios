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
        static let animationContentInset: CGFloat = 50.0
    }
    
    class View: UIView {
        
        var countdownText: String? {
            get {
                countdownView.countdownLayer.string as? String
            }
            
            set {
                countdownView.countdownLayer.string = newValue as NSString?
            }
        }
        
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
        
        let imageView = AnimationView(name: "onboarding-ads").then {
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
        
        private let countdownView = AdsCountdownGradientView()
        
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
        
        func animate(from startOffset: CGFloat, to endOffset: CGFloat, duration: CFTimeInterval, completion: (() -> Void)? = nil) {
            countdownView.animate(from: startOffset, to: endOffset, duration: duration, completion: completion)
        }
        
        init() {
            super.init(frame: .zero)
            
            mainStackView.tag = OnboardingViewAnimationID.details.rawValue
            descriptionStackView.tag = OnboardingViewAnimationID.detailsContent.rawValue
            imageView.tag = OnboardingViewAnimationID.background.rawValue
            
            let backgroundView = UIImageView().then {
                $0.backgroundColor = #colorLiteral(red: 0.1176470588, green: 0.1254901961, blue: 0.1607843137, alpha: 1)
            }
            
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            
            addSubview(imageView)
            addSubview(mainStackView)
            mainStackView.snp.makeConstraints {
                $0.leading.equalTo(self.safeArea.leading)
                $0.trailing.equalTo(self.safeArea.trailing)
                $0.bottom.equalTo(self.safeArea.bottom)
            }
            
            descriptionView.addSubview(descriptionStackView)
            descriptionStackView.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UX.descriptionContentInset)
            }
            
            [descriptionView].forEach(mainStackView.addArrangedSubview(_:))

            [finishedButton, invalidButton, UIView.spacer(.horizontal, amount: 0)]
                .forEach(buttonsStackView.addArrangedSubview(_:))
            
            [titleLabel, countdownView, buttonsStackView].forEach(descriptionStackView.addArrangedSubview(_:))
            
            countdownView.snp.makeConstraints {
                $0.width.equalTo(156.0)
                $0.height.equalTo(156.0)
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let size = imageView.intrinsicContentSize
            let scaleFactor = bounds.width / size.width
            let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
            
            imageView.frame = CGRect(x: 0.0, y: UX.animationContentInset, width: newSize.width, height: newSize.height)
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
    
    fileprivate let countdownLayer = CenteredTextLayer().then {
        $0.font = UIFont.systemFont(ofSize: 54.0) as CTFont
        $0.foregroundColor = UX.gradientPurple.cgColor
        $0.alignmentMode = .center
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
        layer.backgroundColor = UX.gradientOrange.cgColor
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
    
    private func createCountdownAnimation(duration: CFTimeInterval, startValue: Int, endValue: Int) -> CAKeyframeAnimation {
        
        let values = [Int](min(startValue, endValue)...max(startValue, endValue))
        let keyTimes = [Int](min(startValue, endValue)...max(startValue, endValue)+1)

        let animation = CAKeyframeAnimation(keyPath: "string")
        animation.calculationMode = .linear
        animation.duration = duration
        animation.values = (startValue <= endValue ? values : values.reversed()).compactMap({ String($0) })
        animation.keyTimes = keyTimes.map({ NSNumber(value: CFTimeInterval($0) / duration) })
        animation.repeatCount = 0
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.beginTime = .zero
        return animation
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
        layer.addSublayer(strokeBallLayer)
        
        //Layout countdownLayer
        countdownLayer.removeFromSuperlayer()
        countdownLayer.frame = bounds
        layer.addSublayer(countdownLayer)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
    
    func animate(from startOffset: CGFloat, to endOffset: CGFloat, duration: CFTimeInterval, completion: (() -> Void)? = nil) {
        CATransaction.begin()
        
        countdownLayer.string = String(Int(duration)) as NSString
        
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
        
        let countdownAnimation = createCountdownAnimation(duration: duration, startValue: Int(duration), endValue: 0)
        
        CATransaction.setCompletionBlock({
            self.strokeLayer.strokeEnd = endOffset
            self.shapeLayer.strokeStart = endOffset
            self.countdownLayer.string = String(Int(0))
            
            self.shapeLayer.removeAnimation(forKey: "backgroundAnimation")
            self.strokeLayer.removeAnimation(forKey: "strokeAnimation")
            self.strokeBallLayer.removeAnimation(forKey: "ballAnimation")
            self.countdownLayer.removeAnimation(forKey: "countdownAnimation")
            
            completion?()
        })
        
        shapeLayer.add(backgroundAnimation, forKey: "backgroundAnimation")
        strokeLayer.add(strokeAnimation, forKey: "strokeAnimation")
        strokeBallLayer.add(ballAnimation, forKey: "ballAnimation")
        countdownLayer.add(countdownAnimation, forKey: "countdownAnimation")
        
        CATransaction.commit()
    }
}

private class CenteredTextLayer: CATextLayer {
    override func draw(in context: CGContext) {
        let height = self.bounds.size.height
        let fontSize = self.fontSize
        let yDiff = (height - fontSize) / 2 - (fontSize / 10)

        context.saveGState()
        context.translateBy(x: 0, y: yDiff)
        super.draw(in: context)
        context.restoreGState()
    }
}
