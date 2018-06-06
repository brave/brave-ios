/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import pop
import SnapKit

/// A popover which presents a `UIViewController` from a point of origin
///
/// - note: You must use `present(from:on:)` from an instantiated `PopoverController` to present a popover. Presenting
/// another way will result in undefined behavior
class PopoverController: UIViewController {
    
    /// Defines the behavior of the arrow direction and how the popover presents itself
    enum ArrowDirectionBehavior {
        /// Determines the direction of the popover based on the origin of the popover
        ///
        /// If the y origin of the popover is more than halfway to the bottom of the presenting view controller, it will
        /// attempt to present with the arrow pointing down, The same is true but opposite logic for if the y origin is less
        /// than half the height
        case automatic
        /// Forces a specific arrow direction regardless of the origin and content height
        case forcedDirection(ArrowDirection)
    }
    
    /// Defines the behavior of how the popover sizes itself to fit the content
    enum ContentSizeBehavior {
        /// The popover content view's size will be tied to the content controller view's size
        case autoLayout
        /// The popover will size itself based on `UIViewController.preferredContentSize`
        case preferredContentSize
        /// The popover content view will be fixed to a given size
        case fixedSize(CGSize)
    }
    
    /// Outer margins around the presented popover to the edge of the screen (or safe area)
    var outerMargins = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    /// The distance from the popover arrow to the origin view
    var arrowDistance: CGFloat = -5.0
    
    /// The arrow direction behavior for this popover
    var arrowDirectionBehavior: ArrowDirectionBehavior = .automatic
    
    let contentSizeBehavior: ContentSizeBehavior
    
    private var containerViewHeightConstraint: NSLayoutConstraint?
    private var containerViewWidthConstraint: NSLayoutConstraint?
    
    /// Create a popover displaying a content controller
    init(contentController: UIViewController & PopoverContentComponent, contentSizeBehavior: ContentSizeBehavior = .autoLayout) {
        self.contentController = contentController
        self.contentSizeBehavior = contentSizeBehavior
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overFullScreen
        self.transitioningDelegate = self
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundOverlayView.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        backgroundOverlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedBackgroundOverlay(_:))))
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pannedPopover(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backgroundOverlayView)
        view.addSubview(containerView)
        
        backgroundOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        addChildViewController(contentController)
        contentController.didMove(toParentViewController: self)
        containerView.contentView.addSubview(contentController.view)
        
        contentController.view.snp.makeConstraints { make in
            make.edges.equalTo(self.containerView.contentView)
        }
        
        switch contentSizeBehavior {
        case .autoLayout:
            break
        case .preferredContentSize:
            containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: contentController.preferredContentSize.height)
            containerViewHeightConstraint?.priority = .defaultHigh
            containerViewHeightConstraint?.isActive = true
            
            containerViewWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: contentController.preferredContentSize.width)
            containerViewWidthConstraint?.priority = .defaultHigh
            containerViewWidthConstraint?.isActive = true
        case .fixedSize(let size):
            containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: size.height)
            containerViewHeightConstraint?.priority = .defaultHigh
            containerViewHeightConstraint?.isActive = true
            
            containerViewWidthConstraint = containerView.widthAnchor.constraint(equalToConstant: size.width)
            containerViewWidthConstraint?.priority = .defaultHigh
            containerViewWidthConstraint?.isActive = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - UI
    
    private(set) var contentController: UIViewController & PopoverContentComponent
    
    private let containerView = ContainerView()
    
    private let backgroundOverlayView = UIView()
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        if case .preferredContentSize = contentSizeBehavior {
            self.containerViewHeightConstraint?.springAnimate(property: kPOPLayoutConstraintConstant, key: "constant") { animation, _ in
                animation.toValue = container.preferredContentSize.height
            }
            self.containerViewWidthConstraint?.springAnimate(property: kPOPLayoutConstraintConstant, key: "constant") { animation, _ in
                animation.toValue = container.preferredContentSize.width
            }
        }
    }
    
    // MARK: - Presentation
    
    /// Context around the popover presenation
    private struct PresentationContext {
        /// Which view the popover is originating from
        var originView: UIView
        /// The origin's view center in the presenting view controller's coordinate system
        var convertedOriginViewCenter: CGPoint
        /// The initial size of the popover during presentation
        var presentedSize: CGSize
    }
    
    private var presentationContext: PresentationContext?
    
    /// Generate the anchor point delta based on the center of the origin view and the size of the container
    private func anchorPointDelta(from context: PresentationContext, popoverRect rect: CGRect) -> CGPoint {
        var deltaY = rect.height / 2.0
        if containerView.arrowDirection == .up {
            deltaY *= -1
        }
        
        return CGPoint(
            x: context.convertedOriginViewCenter.x - rect.midX,
            y: deltaY
        )
    }
    
    /// Presents the popover from a specific view's region
    ///
    /// - parameter view: The view to have the popover present from (scaling from the location of this view)
    /// - parameter viewController: The view controller to present this popover on
    func present(from view: UIView, on viewController: UIViewController) {
        let convertedOriginViewCenter = viewController.view.convert(view.center, from: view.superview)
        
        switch arrowDirectionBehavior {
        case .automatic:
            if convertedOriginViewCenter.y >= viewController.view.bounds.height / 2.0 {
                containerView.arrowDirection = .down
            } else {
                containerView.arrowDirection = .up
            }
        case .forcedDirection(let direction):
            containerView.arrowDirection = direction
        }
        
        let constrainedWidth = viewController.view.bounds.width - outerMargins.left - outerMargins.right
        let contentSize: CGSize
        
        switch contentSizeBehavior {
        case .autoLayout:
            contentSize = contentController.view.systemLayoutSizeFitting(CGSize(width: constrainedWidth, height: viewController.view.bounds.height - outerMargins.top - outerMargins.bottom))
        case .preferredContentSize:
            contentSize = contentController.preferredContentSize
        case .fixedSize(let size):
            contentSize = size
        }
        
        presentationContext = PresentationContext(
            originView: view,
            convertedOriginViewCenter: convertedOriginViewCenter,
            presentedSize: contentSize
        )
        
        viewController.present(self, animated: true)
    }
}

// MARK: - Actions
extension PopoverController {
    
    @objc private func tappedBackgroundOverlay(_ tap: UITapGestureRecognizer) {
        if tap.state == .ended {
            if contentController.popoverShouldDismiss(self) {
                dismiss(animated: true)
                // Not sure if we want this after dismissal completes or right away. Could always create a
                // `popoverWillDismiss` to put before and `did` after
                contentController.popoverDidDismiss(self)
            }
        }
    }
    
    @objc private func pannedPopover(_ pan: UIPanGestureRecognizer) {
        func _computedOffsetBasedOnRubberBandingResistance(distance x: CGFloat, constant c: CGFloat = 0.55, dimension d: CGFloat) -> CGFloat {
            /*
             f(x, d, c) = (x * d * c) / (d + c * x)
             
             where,
             x – distance from the edge
             c – constant (UIScrollView uses 0.55)
             d – dimension, either width or height
             */
            return (x * d * c) / (d + c * x)
        }
        
        guard let context = presentationContext else { return }
        
        var scale: CGFloat
        let rotationPercent: CGFloat
        
        switch containerView.arrowDirection {
        case .up:
            scale = 1.0 - (-pan.translation(in: pan.view).y / containerView.bounds.height)
            rotationPercent = -pan.translation(in: pan.view).x / containerView.bounds.width
        case .down:
            scale = 1.0 - pan.translation(in: pan.view).y / containerView.bounds.height
            rotationPercent = pan.translation(in: pan.view).x / containerView.bounds.width
        }
        
        scale = max(0.0, scale)
        if scale > 1 {
            scale = 1.0 + _computedOffsetBasedOnRubberBandingResistance(
                distance: scale - 1.0,
                constant: 0.15,
                dimension: containerView.bounds.height
            )
        }
        
        let rotation = _computedOffsetBasedOnRubberBandingResistance(
            distance: rotationPercent * (CGFloat.pi / 2.0),
            constant: 0.4,
            dimension: containerView.bounds.width
        )
        
        containerView.transform = .identity // Reset to get unaltered frame
        let translationDelta = anchorPointDelta(from: context, popoverRect: containerView.frame)
        
        containerView.transform = CGAffineTransform(translationX: translationDelta.x, y: translationDelta.y)
            .scaledBy(x: scale, y: scale)
            .rotated(by: rotation)
            .translatedBy(x: -translationDelta.x, y: -translationDelta.y)
        
        if pan.state == .ended {
            let passedVelocityThreshold: Bool
            let velocityThreshold: CGFloat = 100.0
            
            switch containerView.arrowDirection {
            case .up:
                passedVelocityThreshold = pan.velocity(in: pan.view).y < -velocityThreshold
            case .down:
                passedVelocityThreshold = pan.velocity(in: pan.view).y > velocityThreshold
            }
            
            if contentController.popoverShouldDismiss(self) && (passedVelocityThreshold || scale < 0.5) {
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
extension PopoverController: BasicAnimationControllerDelegate {
    
    func animatePresentation(context: UIViewControllerContextTransitioning) {
        guard let viewController = context.viewController(forKey: .from), let popoverContext = presentationContext else {
            context.completeTransition(false)
            return
        }
        
        context.containerView.addSubview(view)
        
        switch containerView.arrowDirection {
        case .down:
            containerView.bottomAnchor.constraint(equalTo: popoverContext.originView.topAnchor, constant: -arrowDistance).isActive = true
        case .up:
            containerView.topAnchor.constraint(equalTo: popoverContext.originView.bottomAnchor, constant: arrowDistance).isActive = true
        }
        
        contentController.view.frame = CGRect(origin: .zero, size: popoverContext.presentedSize)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                containerView.leftAnchor.constraint(greaterThanOrEqualTo: viewController.view.leftAnchor, constant: outerMargins.left),
                containerView.rightAnchor.constraint(lessThanOrEqualTo: viewController.view.rightAnchor, constant: -outerMargins.right)
            ])
        } else {
            // iPhone variant will always be full-width
            NSLayoutConstraint.activate([
                containerView.leftAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leftAnchor, constant: outerMargins.left),
                containerView.rightAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.rightAnchor, constant: -outerMargins.right)
            ])
        }
        
        let centerX = containerView.centerXAnchor.constraint(equalTo: popoverContext.originView.centerXAnchor)
        centerX.priority = .defaultHigh
        centerX.isActive = true
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(greaterThanOrEqualTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: outerMargins.top),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -outerMargins.bottom)
        ])
        
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
        let translationDelta = anchorPointDelta(from: popoverContext, popoverRect: containerView.frame)
        
        containerView.arrowOrigin = CGPoint(x: containerView.bounds.midX + translationDelta.x, y: 0.0)
        
        containerView.transform = CGAffineTransform(translationX: translationDelta.x, y: translationDelta.y)
            .scaledBy(x: 0.001, y: 0.001)
            .translatedBy(x: -translationDelta.x, y: -translationDelta.y)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.containerView.transform = .identity
        })
        context.completeTransition(true)
    }
    
    func animateDismissal(context: UIViewControllerContextTransitioning) {
        guard let popoverContext = presentationContext else {
            context.completeTransition(false)
            return
        }
        
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
        containerView.transform = .identity // Reset to get unaltered frame
        let translationDelta = anchorPointDelta(from: popoverContext, popoverRect: containerView.frame)
        containerView.transform = oldTransform // Make sure to animate transform from a possibly altered transform
        
        UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.containerView.transform = CGAffineTransform(translationX: translationDelta.x, y: translationDelta.y)
                .scaledBy(x: 0.001, y: 0.001)
                .translatedBy(x: -translationDelta.x, y: -translationDelta.y)
        }) { finished in
            context.completeTransition(finished)
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension PopoverController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BasicAnimationController(delegate: self, direction: .presenting)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BasicAnimationController(delegate: self, direction: .dismissing)
    }
}

extension PopoverController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return contentController.isPanToDismissEnabled
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        
        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
            let topInset = scrollView.adjustedContentInset.top
            let leftInset = scrollView.adjustedContentInset.left
            
            let velocity = pan.velocity(in: pan.view)
            if abs(velocity.y) > abs(velocity.x) {
                if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height && velocity.y < 0 ||
                    scrollView.contentOffset.y <= -topInset && velocity.y > 0 {
                    otherGestureRecognizer.cancel()
                    return true
                }
            } else {
                if let tableView = scrollView as? UITableView, let ds = tableView.dataSource, velocity.x < 0, ds.responds(to: #selector(UITableViewDataSource.tableView(_:commit:forRowAt:))) {
                    // Fix table view cell actions
                    pan.cancel()
                    return false
                }
                if scrollView.contentOffset.x >= scrollView.contentSize.width - scrollView.frame.size.width && velocity.x < 0 ||
                    scrollView.contentOffset.x <= -leftInset && velocity.x > 0 {
                    otherGestureRecognizer.cancel()
                    return true
                }
            }
        }
        return false
    }
}
