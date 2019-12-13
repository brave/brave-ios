/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import pop
import SnapKit

protocol BinanceWidgetConnectStateViewDelegate {
    func tapGenerate(view: WidgetStateView)
}

class BinanceWidgetConnectStateView: WidgetStateView {
    var delegate: BinanceWidgetConnectStateViewDelegate?
    
    private let logoView = UIImageView(image: UIImage(named: "binance-logo"))
    private let descriptionLabel = UILabel()
    private let apiKeyInput = UITextField()
    private let privateKeyInput = UITextField()
    private let generateKeyButton = RoundInterfaceButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(logoView)
        
        descriptionLabel.text = "Complete setup by generating a secure API  Key. Help"
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.numberOfLines = 0
        addSubview(descriptionLabel)
        
        let apiLeftView = UIImageView(image: UIImage(named: "key-icon"))
        apiLeftView.contentMode = .center
        apiKeyInput.leftView = apiLeftView
        apiKeyInput.leftViewMode = .always
        apiKeyInput.backgroundColor = UIColor(rgb: 0xD8D8D8)
        apiKeyInput.placeholder = "Binance API Key"
        apiKeyInput.textColor = .black
        apiKeyInput.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        apiKeyInput.isSecureTextEntry = true
        addSubview(apiKeyInput)
        
        let privateLeftView = UIImageView(image: UIImage(named: "key-lock-icon"))
        privateLeftView.contentMode = .center
        privateKeyInput.leftView = privateLeftView
        privateKeyInput.leftViewMode = .always
        privateKeyInput.backgroundColor = UIColor(rgb: 0xD8D8D8)
        privateKeyInput.placeholder = "Secret Key"
        privateKeyInput.textColor = .black
        privateKeyInput.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        privateKeyInput.isSecureTextEntry = true
        addSubview(privateKeyInput)
        
        generateKeyButton.setTitle("Generate new key", for: .normal)
        generateKeyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        generateKeyButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        generateKeyButton.setTitleColor(UIColor(rgb: 0xBABABA), for: .normal)
        generateKeyButton.backgroundColor = UIColor(rgb: 0x2C2C2C)
        generateKeyButton.addTarget(self, action: #selector(tapGenerate), for: .touchUpInside)
        addSubview(generateKeyButton)
        
        logoView.snp.makeConstraints {
            $0.top.equalTo(self)
            $0.left.equalTo(self).inset(10)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(logoView.snp.bottom).offset(18)
            $0.left.equalTo(self).inset(10)
            $0.right.equalTo(self)
        }
        
        apiLeftView.snp.makeConstraints {
            $0.size.equalTo(30)
        }
        
        apiKeyInput.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(10)
            $0.left.equalTo(self).inset(10)
            $0.right.equalTo(self).inset(10)
            $0.height.equalTo(30)
        }
        
        privateLeftView.snp.makeConstraints {
            $0.size.equalTo(30)
        }
        
        privateKeyInput.snp.makeConstraints {
            $0.top.equalTo(apiKeyInput.snp.bottom).offset(8)
            $0.left.equalTo(self).inset(10)
            $0.right.equalTo(self).inset(10)
            $0.height.equalTo(30)
        }
        
        generateKeyButton.snp.makeConstraints {
            $0.top.equalTo(privateKeyInput.snp.bottom).offset(8)
            $0.left.equalTo(self).inset(10)
            $0.height.equalTo(24)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapGenerate() {
        delegate?.tapGenerate(view: self)
    }
}
