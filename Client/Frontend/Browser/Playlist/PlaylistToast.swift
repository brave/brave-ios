// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveShared
import Shared
import SnapKit

class PlaylistToast: Toast {
    private struct DesignUX {
        static let maxToastWidth: CGFloat = 450.0
    }
    
    enum State {
        case itemAdded
        case itemExisting
        case itemPendingUserAction
    }
    
    private class HighlightableButton: UIButton {
        override var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? .white : DownloadToastUX.toastBackgroundColor
            }
        }
    }
    
    private let shadowLayer = CAShapeLayer().then {
        $0.fillColor = nil
        $0.shadowColor = UIColor.black.cgColor
        $0.shadowOffset = CGSize(width: 2.0, height: 2.0)
        $0.shadowOpacity = 0.15
        $0.shadowRadius = ButtonToastUX.toastButtonBorderRadius
    }
    
    var item: PlaylistInfo

    init(item: PlaylistInfo, state: State, completion: ((_ buttonPressed: Bool) -> Void)?) {
        self.item = item
        super.init(frame: .zero)

        self.completionHandler = completion
        self.clipsToBounds = true

        self.addSubview(createView(item, state))

        self.toastView.snp.makeConstraints { make in
            make.left.right.height.equalTo(self)
            self.animationConstraint = make.top.equalTo(self).offset(ButtonToastUX.toastHeight).constraint
        }

        self.snp.makeConstraints { make in
            make.height.equalTo(ButtonToastUX.toastHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: ButtonToastUX.toastButtonBorderRadius).cgPath
        shadowLayer.shadowPath = shadowLayer.path
        layer.insertSublayer(shadowLayer, at: 0)
    }

    func createView(_ item: PlaylistInfo, _ state: State) -> UIView {
        if state == .itemAdded || state == .itemExisting {
            let horizontalStackView = UIStackView().then {
                $0.alignment = .center
                $0.spacing = ButtonToastUX.toastPadding
            }

            let labelStackView = UIStackView().then {
                $0.axis = .vertical
                $0.alignment = .leading
            }

            let label = UILabel().then {
                $0.textAlignment = .left
                $0.appearanceTextColor = UIColor.Photon.white100
                $0.font = ButtonToastUX.toastLabelFont
                $0.lineBreakMode = .byWordWrapping
                $0.numberOfLines = 0
                
                if state == .itemAdded {
                    $0.text = Strings.PlayList.toastAddedToPlaylistTitle
                } else {
                    $0.text = Strings.PlayList.toastExitingItemPlaylistTitle
                }
            }
            
            let button = HighlightableButton().then {
                $0.layer.cornerRadius = ButtonToastUX.toastButtonBorderRadius
                $0.layer.borderWidth = ButtonToastUX.toastButtonBorderWidth
                $0.layer.borderColor = UIColor.Photon.white100.cgColor
                $0.setTitle(Strings.PlayList.toastAddToPlaylistOpenButton, for: [])
                $0.setTitleColor(toastView.backgroundColor, for: .highlighted)
                $0.titleLabel?.font = SimpleToastUX.toastFont
                $0.titleLabel?.numberOfLines = 1
                $0.titleLabel?.lineBreakMode = .byClipping
                $0.titleLabel?.adjustsFontSizeToFitWidth = true
                $0.titleLabel?.minimumScaleFactor = 0.1
                
                $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
            }

            button.snp.makeConstraints { (make) in
                if let titleLabel = button.titleLabel {
                    make.width.equalTo(titleLabel.intrinsicContentSize.width + 2 * ButtonToastUX.toastButtonPadding)
                }
            }

            labelStackView.addArrangedSubview(label)
            horizontalStackView.addArrangedSubview(labelStackView)
            horizontalStackView.addArrangedSubview(button)

            toastView.addSubview(horizontalStackView)

            horizontalStackView.snp.makeConstraints { make in
                make.centerX.equalTo(toastView)
                make.centerY.equalTo(toastView)
                make.width.equalTo(toastView.snp.width).offset(-2 * ButtonToastUX.toastPadding)
            }

            return toastView
        }
        
        let horizontalStackView = UIStackView().then {
            $0.alignment = .center
            $0.spacing = ButtonToastUX.toastPadding
        }
        
        let button = HighlightableButton().then {
            $0.layer.cornerRadius = ButtonToastUX.toastButtonBorderRadius
            $0.layer.masksToBounds = true
            $0.backgroundColor = DownloadToastUX.toastBackgroundColor
            $0.setTitleColor(toastView.backgroundColor, for: .highlighted)
            $0.tintColor = UIColor.Photon.white100
            $0.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            $0.titleLabel?.numberOfLines = 1
            $0.titleLabel?.lineBreakMode = .byClipping
            $0.titleLabel?.adjustsFontSizeToFitWidth = true
            $0.titleLabel?.minimumScaleFactor = 0.1
            $0.contentHorizontalAlignment = .left
            $0.contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 20.0)
            $0.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: -10.0)
            
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
        }
        
        horizontalStackView.addArrangedSubview(button)
        toastView.addSubview(horizontalStackView)

        horizontalStackView.snp.makeConstraints { make in
            make.centerX.equalTo(toastView)
            make.centerY.equalTo(toastView)
            make.width.equalTo(toastView.snp.width).offset(-2 * ButtonToastUX.toastPadding)
        }
        
        if state == .itemPendingUserAction {
            button.setImage(#imageLiteral(resourceName: "quick_action_new_tab").template, for: [])
            button.setTitle(Strings.PlayList.toastAddToPlaylistTitle, for: [])
            toastView.backgroundColor = .clear
        } else {
            assertionFailure("Should Never get here. Others case are handled at the start of this function.")
        }

        return toastView
    }
    
    @objc func buttonPressed(_ gestureRecognizer: UIGestureRecognizer) {
        completionHandler?(true)
        dismiss(true)
    }

    @objc override func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        dismiss(false)
    }
    
    override func showToast(viewController: UIViewController? = nil, delay: DispatchTimeInterval, duration: DispatchTimeInterval?, makeConstraints: @escaping (SnapKit.ConstraintMaker) -> Swift.Void) {
        
        super.showToast(viewController: viewController, delay: delay, duration: duration) { make in
            guard let viewController = viewController as? BrowserViewController else {
                assertionFailure("Playlist Toast should only be presented on BrowserViewController")
                return
            }
            
            make.centerX.equalTo(viewController.view.snp.centerX)
            make.bottom.equalTo(viewController.webViewContainer.safeArea.bottom)
            make.left.equalTo(viewController.view.safeArea.left).priority(.high)
            make.right.equalTo(viewController.view.safeArea.right).priority(.high)
            make.width.lessThanOrEqualTo(DesignUX.maxToastWidth)
        }
    }
}
