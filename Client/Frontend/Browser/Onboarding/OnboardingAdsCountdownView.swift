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
        
        enum State {
            case countdown
            case adConfirmation
        }
        
        var countdownText: String? {
            get {
                countdownView.countdownLayer.string as? String
            }
            
            set {
                countdownView.countdownLayer.string = newValue
            }
        }
        
        let finishedButton = CommonViews.primaryButton(text: Strings.OBFinishButton).then {
            $0.accessibilityIdentifier = "OnboardingAdsCountdownViewController.StartBrowsing"
            $0.backgroundColor = BraveUX.BraveOrange
        }
        
        let invalidButton = CommonViews.secondaryButton(text: Strings.OBDidntSeeAdButton).then {
            $0.accessibilityIdentifier = "OnboardingAdsCountdownViewController.DidntSeeAdd"
        }
        
        private let mainStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = UX.negativeSpacing
        }
        
        let imageView = AnimationView(name: "onboarding-ads").then {
            $0.contentMode = .scaleAspectFit
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
        
        private let titleLabel = CommonViews.primaryText(Strings.OBAdsTitle).then {
            $0.numberOfLines = 0
        }
        
        private let countdownView = AdsCountdownGradientView()
        
        private let buttonsStackView = UIStackView().then {
            $0.axis = .vertical
            $0.alignment = .center
            $0.distribution = .equalCentering
            $0.isHidden = true
        }
        
        func animate(from startOffset: CGFloat, to endOffset: CGFloat, duration: CFTimeInterval, completion: (() -> Void)? = nil) {
            countdownView.animate(from: startOffset, to: endOffset, duration: duration, completion: completion)
        }
        
        func setState(_ state: State) {
            switch state {
            case .countdown:
                titleLabel.isHidden = false
                buttonsStackView.isHidden = true
                countdownView.isHidden = false
                break
                
            case .adConfirmation:
                titleLabel.isHidden = true
                buttonsStackView.isHidden = false
                countdownView.isHidden = true
                break
            }
        }
        
        init(theme: Theme, themeColour: UIColor) {
            super.init(frame: .zero)
            
            descriptionView.backgroundColor = themeColour
            countdownView.setTheme(isDark: theme.isDark)
            
            mainStackView.tag = OnboardingViewAnimationID.details.rawValue
            descriptionStackView.tag = OnboardingViewAnimationID.detailsContent.rawValue
            imageView.tag = OnboardingViewAnimationID.background.rawValue
            
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
            
            mainStackView.addArrangedSubview(descriptionView)

            [UIView.spacer(.vertical, amount: 20), finishedButton, UIView.spacer(.vertical, amount: 0), invalidButton]
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
        
        static let backgroundGrayLight = UIColor(rgb: 0xCED4DA)
        static let backgroundGrayDark = UIColor(rgb: 0x212529)
        
        static let gradientPurpleLight = UIColor(rgb: 0x4F30AB)
        static let gradientPinkLight = UIColor(rgb: 0xFF1893)
        static let gradientOrangeLight = UIColor(rgb: 0xFA7250)
        
        static let gradientPurpleDark = UIColor(rgb: 0xA78AFF)
        static let gradientPinkDark = UIColor(rgb: 0xFF1893)
        static let gradientOrangeDark = UIColor(rgb: 0xFA7250)
    }
    
    fileprivate let countdownLayer = CenteredTextLayer().then {
        $0.font = UIFont.systemFont(ofSize: 54.0) as CTFont
        $0.alignmentMode = .center
    }
    
    private let gradientLayer = CAGradientLayer().then {
        $0.type = .conic
        $0.startPoint = CGPoint(x: 0.5, y: 0.5)
        $0.endPoint = CGPoint(x: 0.5, y: 0)
    }
    
    private let shapeLayer = CAShapeLayer().then {
        $0.lineWidth = UX.strokeThickness
        $0.fillColor = nil
        $0.shouldRasterize = true
        $0.strokeStart = 0.0
        $0.strokeEnd = 1.0
    }
    
    private let strokeLayer = CAShapeLayer().then {
        $0.lineWidth = UX.strokeThickness
        $0.fillColor = nil
        $0.strokeColor = UIColor.white.cgColor
        $0.shouldRasterize = true
        $0.strokeStart = 0.0
        $0.strokeEnd = 0.0
    }
    
    private let strokeBallLayer = CALayer().then {
        $0.shouldRasterize = true
    }
    
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
    
    func setTheme(isDark: Bool) {
        if isDark {
            gradientLayer.colors = [UX.gradientPurpleDark,
                                    UX.gradientPurpleDark,
                                    UX.gradientPinkDark,
                                    UX.gradientOrangeDark,
                                    UX.gradientOrangeDark,
                                    UX.gradientOrangeDark].map({ $0.cgColor })
            
            countdownLayer.foregroundColor = UX.gradientPurpleDark.cgColor
            shapeLayer.strokeColor = UX.backgroundGrayDark.cgColor
            strokeBallLayer.backgroundColor = UX.gradientOrangeDark.cgColor
        } else {
            gradientLayer.colors = [UX.gradientPurpleLight,
                                    UX.gradientPurpleLight,
                                    UX.gradientPinkLight,
                                    UX.gradientOrangeLight,
                                    UX.gradientOrangeLight,
                                    UX.gradientOrangeLight].map({ $0.cgColor })
            
            countdownLayer.foregroundColor = UX.gradientPurpleLight.cgColor
            shapeLayer.strokeColor = UX.backgroundGrayLight.cgColor
            strokeBallLayer.backgroundColor = UX.gradientOrangeLight.cgColor
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
    
    func animate(from startOffset: CGFloat, to endOffset: CGFloat, duration: CFTimeInterval, completion: (() -> Void)? = nil) {
        CATransaction.begin()
        
        countdownLayer.string = String(Int(duration))
        
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
