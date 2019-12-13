/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import pop

class BinanceWidgetViewController: WidgetViewController {
    
    private let serviceManager = BinanceWidgetServiceManager()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        serviceManager.delegate = self
        
        gradientFill.colors = [
            UIColor(rgb: 0x212529).cgColor,
            UIColor(rgb: 0x000000).cgColor
        ]
        
        serviceManager.start()
//        let view = BinanceWidgetDisconnectStateView()
//        view.delegate = self
//        showView(view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showView(_ next: WidgetStateView?) {
        stateViewContainer.subviews.forEach {
            if let previous = $0 as? WidgetStateView {
                previous.willHide()
                previous.removeFromSuperview()
                previous.didHide()
            }
        }
        
        guard let next = next else { return }
        
        next.willShow()
        stateViewContainer.addSubview(next)
        next.snp.makeConstraints {
            $0.edges.equalTo(stateViewContainer)
        }
        next.didShow()
    }
}

extension BinanceWidgetViewController: BinanceWidgetServiceDelegate {
    func didChangeState(widget: BinanceWidgetServiceManager, state: BinanceWidgetState) {
        var stateView: WidgetStateView?
        
        switch state {
        case .connected:
            let view = BinanceWidgetAccountStateView()
            view.delegate = self
            stateView = view
        case .disconnected:
            let view = BinanceWidgetInitialStateView()
            view.delegate = self
            stateView = view
        case .invalid:
            let view = BinanceWidgetInvalidStateView()
            view.delegate = self
            stateView = view
        case .loading:
            let view = BinanceWidgetLoadingStateView()
            stateView = view
        }
        
        showView(stateView)
    }
}

extension BinanceWidgetViewController: BinanceWidgetInitialStateViewDelegate {
    func tapConnect(view: WidgetStateView) {
        let view = BinanceWidgetConnectStateView()
        view.delegate = self
        showView(view)
    }
    
    func tapHide(view: WidgetStateView) {
        delegate?.shouldHideWidget(widget: self)
    }
}

extension BinanceWidgetViewController: BinanceWidgetConnectStateViewDelegate {
    func tapGenerate(view: WidgetStateView) {
        // Remove this
        let view = BinanceWidgetAccountStateView()
        view.delegate = self
        showView(view)
    }
}

extension BinanceWidgetViewController: BinanceWidgetAccountStateViewDelegate {
    func tapRefresh(view: WidgetStateView) {
        
    }
    
    func tapDisconnect(view: WidgetStateView) {
        let view = BinanceWidgetDisconnectStateView()
        view.delegate = self
        showView(view)
    }
    
    func tapDeposit(view: WidgetStateView) {
        
    }
    
    func tapTrade(view: WidgetStateView) {
        
    }
}

extension BinanceWidgetViewController: BinanceWidgetInvalidStateViewDelegate {
    func tapConfigure(view: WidgetStateView) {
        let view = BinanceWidgetConnectStateView()
        view.delegate = self
        showView(view)
    }
}

extension BinanceWidgetViewController: BinanceWidgetDisconnectStateViewDelegate {
    func tapConfirm(view: WidgetStateView) {
        let view = BinanceWidgetInitialStateView()
        view.delegate = self
        showView(view)
    }
    
    func tapCancel(view: WidgetStateView) {
        let view = BinanceWidgetAccountStateView()
        view.delegate = self
        showView(view)
    }
}
