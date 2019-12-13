/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import pop
import SnapKit

protocol BinanceWidgetAccountStateViewDelegate {
    func tapRefresh(view: WidgetStateView)
    func tapDisconnect(view: WidgetStateView)
    func tapDeposit(view: WidgetStateView)
    func tapTrade(view: WidgetStateView)
}

class BinanceWidgetAccountStateView: WidgetStateView {
    var delegate: BinanceWidgetAccountStateViewDelegate?
    
    private let logoView = UIImageView(image: UIImage(named: "binance-logo"))
    private let refreshButton = UIButton()
    private let disconnectButton = UIButton()
    private let descriptionLabel = UILabel()
    private let visibilityButton = UIButton()
    private let balanceLabel = UILabel()
    private let btcLabel = UILabel()
    private let valueLabel = UILabel()
    private let depositButton = UIButton()
    private let tradeButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(logoView)
        
        refreshButton.setImage(UIImage(named: "refresh"), for: .normal)
        refreshButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        refreshButton.backgroundColor = .clear
        refreshButton.addTarget(self, action: #selector(tapRefresh), for: .touchUpInside)
        addSubview(refreshButton)
        
        disconnectButton.setImage(UIImage(named: "disconnect"), for: .normal)
        disconnectButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        disconnectButton.backgroundColor = .clear
        disconnectButton.addTarget(self, action: #selector(tapDisconnect), for: .touchUpInside)
        addSubview(disconnectButton)
        
        descriptionLabel.text = "Equity Value(BTC)"
        descriptionLabel.textColor = UIColor(rgb: 0xC9C9C9)
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.numberOfLines = 0
        addSubview(descriptionLabel)
        
        visibilityButton.setImage(UIImage(named: "shown"), for: .normal)
        visibilityButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        visibilityButton.backgroundColor = .clear
        visibilityButton.addTarget(self, action: #selector(tapVisibility), for: .touchUpInside)
        addSubview(visibilityButton)
        
        balanceLabel.text = "1.04401555"
        balanceLabel.textColor = UIColor.white
        balanceLabel.font = UIFont.systemFont(ofSize: 32, weight: .regular)
        balanceLabel.numberOfLines = 1
        addSubview(balanceLabel)
        
        btcLabel.text = "BTC"
        btcLabel.textColor = UIColor.white
        btcLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        btcLabel.numberOfLines = 1
        addSubview(btcLabel)
        
        valueLabel.text = "≈ $8,480.48"
        valueLabel.textColor = UIColor(rgb: 0xBABABA)
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        valueLabel.numberOfLines = 1
        addSubview(valueLabel)
        
        depositButton.setImage(UIImage(named: "deposit"), for: .normal)
        depositButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: -15, bottom: 10, right: 0)
        depositButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        depositButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 15)
        depositButton.setTitle("Deposit", for: .normal)
        depositButton.setTitleColor(UIColor(rgb: 0xF0B90B), for: .normal)
        depositButton.addTarget(self, action: #selector(tapDeposit), for: .touchUpInside)
        depositButton.layer.borderWidth = 1
        depositButton.layer.borderColor = UIColor(rgb: 0xF0B90B).cgColor
        addSubview(depositButton)
        
        tradeButton.setImage(UIImage(named: "trade"), for: .normal)
        tradeButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: -15, bottom: 10, right: 0)
        tradeButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tradeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 15)
        tradeButton.setTitle("Trade", for: .normal)
        tradeButton.setTitleColor(UIColor(rgb: 0xF0B90B), for: .normal)
        tradeButton.addTarget(self, action: #selector(tapTrade), for: .touchUpInside)
        tradeButton.layer.borderWidth = 1
        tradeButton.layer.borderColor = UIColor(rgb: 0xF0B90B).cgColor
        addSubview(tradeButton)
        
        logoView.snp.makeConstraints {
            $0.top.equalTo(self)
            $0.left.equalTo(self).inset(10)
        }
        
        refreshButton.snp.makeConstraints {
            $0.centerY.equalTo(logoView)
            $0.right.equalTo(disconnectButton.snp.left)
        }
        
        disconnectButton.snp.makeConstraints {
            $0.centerY.equalTo(logoView)
            $0.right.equalTo(self)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(logoView.snp.bottom).offset(30)
            $0.left.equalTo(self).inset(10)
        }
        
        visibilityButton.snp.makeConstraints {
            $0.centerY.equalTo(descriptionLabel)
            $0.left.equalTo(descriptionLabel.snp.right).offset(5)
        }
        
        balanceLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(10)
            $0.left.equalTo(self).inset(10)
        }
        
        btcLabel.snp.makeConstraints {
            $0.centerY.equalTo(balanceLabel)
            $0.left.equalTo(balanceLabel.snp.right).offset(5)
        }
        
        valueLabel.snp.makeConstraints {
            $0.left.equalTo(self).inset(10)
            $0.top.equalTo(balanceLabel.snp.bottom).offset(5)
        }
        
        depositButton.snp.makeConstraints {
            $0.top.equalTo(valueLabel.snp.bottom).offset(20)
            $0.left.equalTo(self).inset(10)
            $0.height.equalTo(30)
        }
        
        tradeButton.snp.makeConstraints {
            $0.top.equalTo(depositButton.snp.top)
            $0.left.equalTo(depositButton.snp.right).offset(8)
            $0.height.equalTo(30)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapVisibility() {
        // Show/hide account balance
    }
    
    @objc func tapRefresh() {
        delegate?.tapRefresh(view: self)
    }
    
    @objc func tapDisconnect() {
        delegate?.tapDisconnect(view: self)
    }
    
    @objc func tapDeposit() {
        delegate?.tapDeposit(view: self)
    }
    
    @objc func tapTrade() {
        delegate?.tapTrade(view: self)
    }
}
