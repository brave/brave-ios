// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit

enum PlaylistToastState {
    case itemAdded
    case itemUpdated
    case itemPendingUserAction
}

class PlaylistToast: Toast {
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

    init(item: PlaylistInfo, state: PlaylistToastState, completion: ((_ buttonPressed: Bool) -> Void)?) {
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

    func createView(_ item: PlaylistInfo, _ state: PlaylistToastState) -> UIView {
        let horizontalStackView = UIStackView().then {
            $0.axis = .horizontal
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

        button.snp.makeConstraints { make in
            make.width.equalTo(button.titleLabel!.intrinsicContentSize.width + 2 * ButtonToastUX.toastButtonPadding)
        }
        
        horizontalStackView.addArrangedSubview(button)
        toastView.addSubview(horizontalStackView)

        horizontalStackView.snp.makeConstraints { make in
            make.centerX.equalTo(toastView)
            make.centerY.equalTo(toastView)
            make.width.equalTo(toastView.snp.width).offset(-2 * ButtonToastUX.toastPadding)
        }
        
        switch state {
        case .itemPendingUserAction:
            button.setImage(#imageLiteral(resourceName: "quick_action_new_tab").template, for: [])
            button.setTitle("Add to Playlist", for: [])
            toastView.backgroundColor = .clear
        case .itemAdded:
            button.do {
                $0.setTitle("Added to Playlist", for: [])
                $0.contentEdgeInsets = .zero
                $0.titleEdgeInsets = .zero
                $0.isUserInteractionEnabled = false
            }
            toastView.backgroundColor = DownloadToastUX.toastBackgroundColor
        case .itemUpdated:
            button.do {
                $0.setTitle("Updated Playlist", for: [])
                $0.contentEdgeInsets = .zero
                $0.titleEdgeInsets = .zero
                $0.isUserInteractionEnabled = false
            }
            toastView.backgroundColor = DownloadToastUX.toastBackgroundColor
        }

        return toastView
    }
    
    @objc func buttonPressed(_ gestureRecognizer: UIGestureRecognizer) {
        completionHandler?(true)
        dismiss(true)
    }

    @objc override func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        // Intentional NOOP to override superclass behavior for dismissing the toast.
    }
}
