/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

/// Presents a sheet with a child view controller of choice.
/// On iPhones it presents as a bottom drawer style.
/// On iPads it presents as a popup at center of the screen.
class BottomSheetViewController: UIViewController {
    
    private struct UX {
        static let HandleWidth: CGFloat = 35
        static let HandleHeight: CGFloat = 5
        static let HandleMargin: CGFloat = 20
    }
    
    /// For landscape orientation the content view isn't full width.
    /// A fixed constant is used instead.
    private let maxHorizontalWidth = 400
    private let animationDuration: TimeInterval = 0.25
    
    //let childViewController: UIViewController
    
    // MARK: - Views
    
    let mainStackView = UIStackView().then {
        $0.axis = .vertical
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.spacing = 16
    }

    let contentView = UIView().then {
        $0.layer.cornerRadius = 12
    }
    
    private let backgroundOverlayView = UIView().then {
        $0.backgroundColor = .black
        $0.alpha = 0
    }
    private let handleView = UIView().then {
        $0.backgroundColor = .black
        $0.alpha = 0.25
        $0.layer.cornerRadius = UX.HandleHeight / 2
    }
    
    private let closeButton = UIButton().then {
        $0.addTarget(self, action: #selector(closeView), for: .touchUpInside)
        $0.setImage(#imageLiteral(resourceName: "close_popup").template, for: .normal)
        $0.appearanceTintColor = .lightGray
    }
    
    // MARK: - Constraint properties
    
    /// The top constraint is kept so the content view can be dragged.
    private var contentViewTopConstraint: Constraint?

    /// Controls height of the content view.
    private var yPosition: CGFloat = 0 {
        didSet {
            let maxY = view.frame.maxY
            
            func update() {
                // Update dark blur, the more of content view go away the less dark it is.
                backgroundOverlayView.alpha = (maxY - yPosition) / maxY
                // Update the position of content view.
                // At the moment only pulling below initial content view height is supported.
                contentViewTopConstraint?.update(offset: yPosition)
                let newFrame = contentView.frame
                //print("bxx new: \(yPosition)")
                
                contentView.frame = CGRect(x: newFrame.minX, y: yPosition, width: newFrame.width, height: newFrame.height)
                view.layoutIfNeeded()
            }   
            
            
            if oldValue == yPosition { return }
            
            // All vertical position manipulation on iPads happens programatically,
            // no need to check for Y position limits.
            if showAsPopup {
                update()
                return
            }
            
            let initialY = initialDrawerYPosition
            
            // Only move the view if dragged below initial level.
            if yPosition <= initialY {
                yPosition = initialY
            } else if yPosition > maxY { // Dragged all way down, remove the view.
                yPosition = maxY
            }
            
            update()
        }
    }
    
    private var childViewHeight: CGFloat {
        contentView.frame.height
    }
    
    private var initialDrawerYPosition: CGFloat {
        let h = (view.frame.height / 2) - (childViewHeight / 2)
        
        let height = view.frame.maxY - contentView.frame.height
        
        return showAsPopup ? h : height
    }
    
    private var showAsPopup: Bool {
        traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular
    }
    
    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
//        let height = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
//        preferredContentSize = CGSize(width: view.frame.width, height: height)

        view.addSubview(backgroundOverlayView)
        view.addSubview(contentView)
        
        contentView.backgroundColor = .white

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didRecognizePanGesture))
        contentView.addGestureRecognizer(panGestureRecognizer)

        contentView.addSubview(handleView)
        
        contentView.addSubview(closeButton)
        
        makeConstraints()
        yPosition = view.frame.maxY
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateDrawerViewConstraints()
    }
    
    // MARK: - Constraints setup
    
    private func makeConstraints() {
        backgroundOverlayView.snp.makeConstraints { make in
            let bottomInset = parent?.view.safeAreaInsets.bottom ?? 0
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(bottomInset)
        }
        
//        view.snp.remakeConstraints {
//            $0.top.equalTo(contentView).offset(UX.HandleMargin)
//            $0.width.equalTo(contentView)
//            $0.centerX.equalTo(contentView)
//        }
        
        handleView.snp.remakeConstraints {
            $0.width.equalTo(UX.HandleWidth)
            $0.height.equalTo(UX.HandleHeight)

            $0.centerX.equalTo(contentView)
            $0.top.equalTo(contentView).offset((UX.HandleMargin - UX.HandleHeight) / 2)
        }
        
        closeButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.right.equalToSuperview().inset(7)
            $0.size.equalTo(26)
        }
        
        updateDrawerViewConstraints()
    }
    
    private func updateDrawerViewConstraints() {
        let allCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                          .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        let onlyTopCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.layer.maskedCorners = showAsPopup ? allCorners : onlyTopCorners
        
        handleView.isHidden = showAsPopup
        
        yPosition = initialDrawerYPosition
        
        contentView.snp.remakeConstraints {
            if showAsPopup {
                $0.centerX.centerY.equalToSuperview()
                $0.width.equalTo(maxHorizontalWidth)
            } else if UIApplication.shared.statusBarOrientation.isLandscape {
                $0.bottom.equalToSuperview()
                $0.centerX.equalToSuperview()
                $0.width.equalTo(maxHorizontalWidth)
            } else {
                $0.leading.trailing.bottom.equalToSuperview()
            }
        }
    }
    
    // MARK: - Animations
    
    @objc fileprivate func didRecognizePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        // The view shouldn't be draggable on iPads
        if showAsPopup { return }

        let translation = gestureRecognizer.translation(in: contentView)
        yPosition += translation.y
        gestureRecognizer.setTranslation(CGPoint.zero, in: contentView)

        if gestureRecognizer.state != .ended { return }

        let velocity = gestureRecognizer.velocity(in: contentView).y
        let landingYPosition = yPosition + velocity / 10
        let nextYPosition: CGFloat
        
        let bottomHalfOfChildView = view.frame.height - (childViewHeight / 2)
        
        if landingYPosition > bottomHalfOfChildView {
            nextYPosition = view.frame.maxY
        } else {
            nextYPosition = 0
        }

        UIView.animate(withDuration: animationDuration, animations: {
            self.yPosition = nextYPosition
            
        }) { _ in
            if nextYPosition > 0 {
                self.view.removeFromSuperview()
                self.removeFromParent()
            }
        }
    }

    private func show() {
        UIView.animate(withDuration: animationDuration) {
            self.yPosition = self.initialDrawerYPosition
        }
    }
    
    @objc func closeView() {
        close()
    }

    private func close() {
        UIView.animate(withDuration: animationDuration, animations: {
            self.yPosition = self.view.frame.maxY
        }) { _ in
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
}

