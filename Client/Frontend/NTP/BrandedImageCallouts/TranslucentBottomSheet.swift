// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

class TranslucentBottomSheet: UIViewController {
    private let animationDuration: TimeInterval = 0.25
    
    var closeHandler: (() -> Void)?
    var learnMoreHandler: (() -> Void)?
    
    private let closeButton = UIButton().then {
        // todo: update icon
        $0.addTarget(self, action: #selector(closeView), for: .touchUpInside)
        $0.setImage(#imageLiteral(resourceName: "close_translucent_popup").template, for: .normal)
        $0.appearanceTintColor = .white
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        let overlayView = UIView().then {
            $0.backgroundColor = .black
            $0.alpha = 0.85
        }
        view.addSubview(overlayView)
        
        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubview(closeButton)
        view.alpha = CGFloat.leastNormalMagnitude
        
        view.bounds = CGRect(size: preferredContentSize)
        
        makeConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 1
        }
    }
    
    private func makeConstraints() {
        closeButton.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(10)
            $0.right.equalToSuperview().inset(7)
            
            $0.size.equalTo(26)
        }
    }
    
    @objc func closeView() {
        close()
    }

    func close() {
        UIView.animate(withDuration: animationDuration, animations: {
            self.view.alpha = CGFloat.leastNormalMagnitude
        }) { _ in
            self.closeHandler?()
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
}
