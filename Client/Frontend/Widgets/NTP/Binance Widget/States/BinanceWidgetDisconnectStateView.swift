/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import pop
import SnapKit

protocol BinanceWidgetDisconnectStateViewDelegate {
    func tapConfirm(view: WidgetStateView)
    func tapCancel(view: WidgetStateView)
}

class BinanceWidgetDisconnectStateView: WidgetStateView {
    var delegate: BinanceWidgetDisconnectStateViewDelegate?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let disconnectButton = RoundInterfaceButton()
    private let cancelButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(containerView)
        
        titleLabel.text = "Are you sure you want to disconnect?"
        titleLabel.textColor = UIColor(rgb: 0xD0D0D0)
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        messageLabel.text = "Disconnecting will erease your widget settings. You will need to generate a new api key to reconnect."
        messageLabel.textColor = UIColor(rgb: 0xD5D5D5)
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        containerView.addSubview(messageLabel)
        
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        disconnectButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        disconnectButton.setTitleColor(UIColor.white, for: .normal)
        disconnectButton.backgroundColor = UIColor(rgb: 0xAA1313)
        disconnectButton.addTarget(self, action: #selector(tapConfirm), for: .touchUpInside)
        containerView.addSubview(disconnectButton)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        cancelButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        cancelButton.setTitleColor(UIColor(rgb: 0xBABABA), for: .normal)
        cancelButton.backgroundColor = .clear
        cancelButton.addTarget(self, action: #selector(tapCancel), for: .touchUpInside)
        containerView.addSubview(cancelButton)
        
        containerView.snp.makeConstraints {
            $0.center.equalTo(self)
            $0.left.right.equalTo(self)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(0)
            $0.left.right.equalTo(self).inset(20)
        }
        
        messageLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.left.right.equalTo(self).inset(20)
        }
        
        disconnectButton.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(20)
            $0.width.greaterThanOrEqualTo(130)
            $0.centerX.equalTo(self)
            $0.height.equalTo(24)
        }
        
        cancelButton.snp.makeConstraints {
            $0.top.equalTo(disconnectButton.snp.bottom).offset(12)
            $0.centerX.equalTo(self)
            $0.height.equalTo(24)
            $0.bottom.equalTo(0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapConfirm() {
        delegate?.tapConfirm(view: self)
    }
    
    @objc func tapCancel() {
        delegate?.tapCancel(view: self)
    }
}
