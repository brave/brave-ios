// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import pop
import Shared
import BraveUI
import SnapKit

class PopupViewController: UIViewController {
    
    private static let preferredpopupWidth = 320.0
    
    /// Outer margins around the presented popover to the edge of the screen (or safe area)
    public var outerMargins = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    /// Whether or not to automatically dismiss the popup when the device orientation changes
    var dismissesOnOrientationChanged = true
    
    /// Allows the presenter to know when the popup was dismissed by some gestural action.
    public var popupDidDismiss: ((_ popupController: PopupViewController) -> Void)?
    
    init(contentController: UIViewController & PopupContentComponent) {
        self.contentController = contentController
        
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
        self.transitioningDelegate = self
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundOverlayView.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(tappedBackgroundOverlay(_:)))
        backgroundOverlayView.isAccessibilityElement = true
        backgroundOverlayView.accessibilityLabel = contentController.closeActionAccessibilityLabel
        backgroundOverlayView.accessibilityElements = [backgroundTap]
        backgroundOverlayView.addGestureRecognizer(backgroundTap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pannedpopup(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        
        view.addSubview(backgroundOverlayView)
        view.addSubview(containerView)
        
        backgroundOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        addChild(contentController)
        containerView.addSubview(contentController.view)
        contentController.didMove(toParent: self)
        
        contentController.view.snp.makeConstraints {
            $0.edges.equalTo(self.containerView.snp.edges)
        }
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - UI
    
    private(set) var contentController: UIViewController & PopupContentComponent
    
    private let containerView = ContainerView()
    private let backgroundOverlayView = UIView()
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if dismissesOnOrientationChanged {
            dismiss(animated: true)
        }
    }
}

// MARK: - Actions
extension PopupViewController {
    
    @objc
    private func tappedBackgroundOverlay(_ tap: UITapGestureRecognizer) {
        if tap.state == .ended {
            if contentController.popupShouldDismiss(self) {
                dismiss(animated: true)
                // Not sure if we want this after dismissal completes or right away. Could always create a
                // `popupWillDismiss` to put before and `did` after
                popupDidDismiss?(self)
            }
        }
    }
    
    @objc
    private func pannedpopup(_ pan: UIPanGestureRecognizer) {
        func _computedOffsetBasedOnRubberBandingResistance(distance x: CGFloat, constant c: CGFloat = 0.55, dimension d: CGFloat) -> CGFloat {
            return (x * d * c) / (d + c * x)
        }

        var scale = 1.0 - (-pan.translation(in: pan.view).y / containerView.bounds.height)

        scale = max(0.0, scale)
        if scale > 1 {
            scale = 1.0 + _computedOffsetBasedOnRubberBandingResistance(
                distance: scale - 1.0,
                constant: 0.15,
                dimension: containerView.bounds.height
            )
        }
        
        containerView.transform = .identity // Reset to get unaltered frame
        containerView.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        
        if pan.state == .ended {
            let passedVelocityThreshold: Bool
            let velocityThreshold: CGFloat = 100.0
            
            passedVelocityThreshold = pan.velocity(in: pan.view).y < -velocityThreshold
            
            if contentController.popupShouldDismiss(self) && (passedVelocityThreshold || scale < 0.5) {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                    self.containerView.transform = .identity
                })
            }
        }
        
        if pan.state == .cancelled {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                self.containerView.transform = .identity
            })
        }
    }
}

// MARK: - BasicAnimationControllerDelegate
extension PopupViewController: BasicAnimationControllerDelegate {
    
    public func animatePresentation(context: UIViewControllerContextTransitioning) {
        guard let fromController = context.viewController(forKey: .from) else {
            context.completeTransition(!context.transitionWasCancelled)
            return
        }
        
        guard let toController = context.viewController(forKey: .to) else {
            context.completeTransition(!context.transitionWasCancelled)
            return
        }
        
        context.containerView.addSubview(view)
        
        let constrainedWidth = fromController.view.bounds.width - outerMargins.left - outerMargins.right
        let constrainedHeight = fromController.view.bounds.height - outerMargins.top - outerMargins.bottom
        let size = contentController.view.systemLayoutSizeFitting(CGSize(width: constrainedWidth, height: constrainedHeight))
        contentController.view.frame = CGRect(origin: .zero, size: size)
        
        containerView.snp.makeConstraints {
            $0.top.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.top).offset(outerMargins.top)
            $0.bottom.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-outerMargins.bottom)
            $0.left.greaterThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.left).offset(outerMargins.left)
            $0.right.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.right).offset(-outerMargins.right)
            $0.center.equalTo(toController.view.snp.center)
        }
        
        backgroundOverlayView.alpha = 0.0
        backgroundOverlayView.basicAnimate(property: kPOPViewAlpha, key: "alpha") { animation, _ in
            animation.toValue = 1.0
            animation.duration = 0.3
        }
        
        containerView.alpha = 0.0
        containerView.springAnimate(property: kPOPViewAlpha, key: "alpha") { animation, inProgress in
            animation.toValue = 1.0
            animation.springSpeed = 16.0
            animation.springBounciness = 6.0
            animation.clampMode = POPAnimationClampFlags.end.rawValue
        }
        
        view.layoutIfNeeded()
        
        let translationDelta = CGPoint(
            x: view.frame.center.x - containerView.frame.midX,
            y: -containerView.frame.height / 2.0
        )
        containerView.transform = CGAffineTransform(translationX: translationDelta.x, y: translationDelta.y)
            .scaledBy(x: 0.001, y: 0.001)
            .translatedBy(x: -translationDelta.x, y: -translationDelta.y)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.containerView.transform = .identity
        }, completion: { finished in
            context.completeTransition(finished && !context.transitionWasCancelled)
        })
    }
    
    public func animateDismissal(context: UIViewControllerContextTransitioning) {
        backgroundOverlayView.basicAnimate(property: kPOPViewAlpha, key: "alpha") { animation, _ in
            animation.toValue = 0.0
            animation.duration = 0.15
        }

        containerView.springAnimate(property: kPOPViewAlpha, key: "alpha") { animation, inProgress in
            animation.toValue = 0.0
            animation.springSpeed = 16.0
            animation.springBounciness = 6.0
            animation.clampMode = POPAnimationClampFlags.end.rawValue
        }

        let oldTransform = containerView.transform
        let rotationAngle = atan2(oldTransform.b, oldTransform.a)

        containerView.transform = .identity // Reset to get unaltered frame
        let translationDelta = CGPoint(
            x: view.frame.center.x - containerView.frame.midX,
            y: -containerView.frame.height / 2.0
        )
        containerView.transform = oldTransform // Make sure to animate transform from a possibly altered transform

        UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.containerView.transform = CGAffineTransform(translationX: translationDelta.x, y: translationDelta.y)
                .scaledBy(x: 0.001, y: 0.001)
                .rotated(by: rotationAngle)
                .translatedBy(x: -translationDelta.x, y: -translationDelta.y)
        }, completion: { finished in
            self.view.removeFromSuperview()
            context.completeTransition(finished && !context.transitionWasCancelled)
        })
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension PopupViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BasicAnimationController(delegate: self, direction: .presenting)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BasicAnimationController(delegate: self, direction: .dismissing)
    }
}

extension PopupViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return contentController.isPanToDismissEnabled
    }
}

extension PopupViewController {
    private struct popupUX {
        static let backgroundColor: UIColor = .braveBackground
        static let arrowSize = CGSize(width: 14.0, height: 8.0)
        static let cornerRadius: CGFloat = 10.0
        static let shadowOffset = CGSize(width: 0, height: 2.0)
        static let shadowRadius: CGFloat = 3.0
        static let shadowColor: UIColor = .black
        static let shadowOpacity: Float = 0.3
    }
    
    /// The internal view loaded by popupController. Applies default styling as well as sets up the arrow
    private class ContainerView: UIView {
        /// Color of menu
        var color: UIColor? {
            didSet {
                contentView.backgroundColor = color
                shadowView.backgroundColor = color
            }
        }
        
        /// The view where you will place the content controller's view
        let contentView = UIView().then {
            $0.backgroundColor = popupUX.backgroundColor
        }
        
        private let popupMaskView = UIView().then {
            $0.layer.cornerRadius = popupUX.cornerRadius
            $0.layer.cornerCurve = .continuous
            $0.backgroundColor = .black
        }
        
        /// The actual white background view with the arrow. We have two separate views to ensure content placed within
        /// the popup are clipped at the corners
        private let shadowView = UIView().then {
            $0.backgroundColor = popupUX.backgroundColor
            $0.layer.cornerRadius = popupUX.cornerRadius
            $0.layer.cornerCurve = .continuous
            $0.layer.shadowColor = popupUX.shadowColor.cgColor
            $0.layer.shadowOffset = popupUX.shadowOffset
            $0.layer.shadowRadius = popupUX.shadowRadius
            $0.layer.shadowOpacity = popupUX.shadowOpacity
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = .clear
            
            addSubview(shadowView)
            addSubview(contentView)
            
            contentView.mask = popupMaskView
            
            contentView.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }
            
            setNeedsUpdateConstraints()
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            popupMaskView.frame = contentView.bounds
            shadowView.frame = popupMaskView.frame
        }
    }
}

/// Defines behavior of a component which will be used with a `PopupViewController`
protocol PopupContentComponent {
    /// Whether or not the pan to dismiss gesture is enabled. Optional, true by defualt
    var isPanToDismissEnabled: Bool { get }
    /// Allows the component to decide whether or not the popup should dismiss based on some gestural action (tapping
    /// the background around the popup or dismissing via pan). Optional, true by defualt
    func popupShouldDismiss(_ popupController: PopupViewController) -> Bool

    /// Description for closing the popup view for accessibility users
    var closeActionAccessibilityLabel: String { get }
}

extension PopupContentComponent {
    var isPanToDismissEnabled: Bool {
        return true
    }
    
    func popupShouldDismiss(_ popoverController: PopupViewController) -> Bool {
        return true
    }

    var closeActionAccessibilityLabel: String {
        return Strings.Popover.closeContextMenu
    }
}
