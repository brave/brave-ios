/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import pop
import SnapKit

protocol BinanceWidgetInvalidStateViewDelegate {
    func tapConfigure(view: WidgetStateView)
}

class BinanceWidgetInvalidStateView: WidgetStateView {
    var delegate: BinanceWidgetInvalidStateViewDelegate?
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let configureButton = RoundInterfaceButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(containerView)
        
        titleLabel.text = "Account Disconnected"
        titleLabel.textColor = UIColor(rgb: 0xD0D0D0)
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        messageLabel.text = "Your API Key is invalid. A new Binance API key must be configured."
        messageLabel.textColor = UIColor(rgb: 0xD5D5D5)
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        containerView.addSubview(messageLabel)
        
        configureButton.setTitle("Configure", for: .normal)
        configureButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        configureButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        configureButton.setTitleColor(UIColor(rgb: 0xBABABA), for: .normal)
        configureButton.backgroundColor = UIColor(rgb: 0x2C2C2C)
        configureButton.addTarget(self, action: #selector(tapConfigure), for: .touchUpInside)
        containerView.addSubview(configureButton)
        
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
        
        configureButton.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(20)
            $0.width.greaterThanOrEqualTo(130)
            $0.centerX.equalTo(self)
            $0.height.equalTo(24)
            $0.bottom.equalTo(0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapConfigure() {
        delegate?.tapConfigure(view: self)
    }
}
