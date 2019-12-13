/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import pop
import SnapKit

protocol BinanceWidgetInitialStateViewDelegate {
    func tapConnect(view: WidgetStateView)
    func tapHide(view: WidgetStateView)
}

class BinanceWidgetInitialStateView: WidgetStateView {
    var delegate: BinanceWidgetInitialStateViewDelegate?
    
    private let logoView = UIImageView(image: UIImage(named: "binance-logo"))
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let connectButton = RoundInterfaceButton()
    private let hideButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(logoView)
        
        titleLabel.text = "Purchase and trade with Binance"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
        
        descriptionLabel.text = "Enable Binance connection to view Binance account balance and trade crypto."
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.numberOfLines = 0
        addSubview(descriptionLabel)
        
        connectButton.setTitle("Enable Binance Connect", for: .normal)
        connectButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        connectButton.setTitleColor(UIColor(rgb: 0x1C2023), for: .normal)
        connectButton.backgroundColor = UIColor(rgb: 0xF0B90B)
        connectButton.addTarget(self, action: #selector(tapConnect), for: .touchUpInside)
        addSubview(connectButton)
        
        hideButton.setTitle("No thank you", for: .normal)
        hideButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        hideButton.setTitleColor(UIColor.white.withAlphaComponent(0.65), for: .normal)
        hideButton.backgroundColor = .clear
        hideButton.addTarget(self, action: #selector(tapHide), for: .touchUpInside)
        addSubview(hideButton)
        
        logoView.snp.makeConstraints {
            $0.top.equalTo(self)
            $0.left.equalTo(self).inset(10)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(logoView.snp.bottom).offset(15)
            $0.left.equalTo(self).inset(10)
            $0.right.equalTo(self)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(1)
            $0.left.equalTo(self).inset(10)
            $0.right.equalTo(self)
        }
        
        connectButton.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            $0.height.equalTo(40)
            $0.left.right.equalTo(self)
        }
        
        hideButton.snp.makeConstraints {
            $0.top.equalTo(connectButton.snp.bottom).offset(4)
            $0.height.equalTo(40)
            $0.left.right.equalTo(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapConnect() {
        delegate?.tapConnect(view: self)
    }
    
    @objc func tapHide() {
        delegate?.tapHide(view: self)
    }
}
