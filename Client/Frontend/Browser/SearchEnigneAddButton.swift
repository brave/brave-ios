// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import SnapKit

class SearchEnigneAddButton: UIView {
    
    enum State {
        case loading
        case enabled
        case disabled
    }
    
    var state: State {
        didSet {
            switch state {
            case .disabled:
                self.searchButton.isHidden = false
                self.loadingIndicator.stopAnimating()
                self.searchButton.tintColor = UIColor.Photon.Grey50
                self.searchButton.isUserInteractionEnabled = false
            case .enabled:
                self.searchButton.isHidden = false
                self.loadingIndicator.stopAnimating()
                self.searchButton.tintColor = UIConstants.SystemBlueColor
                self.searchButton.isUserInteractionEnabled = true
            case .loading:
                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()
                self.searchButton.isHidden = true
            }
        }
    }
    let searchButton: UIButton!
    let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    
    override init(frame: CGRect) {
        self.state = .disabled
        self.searchButton = UIButton()
        searchButton.setImage(#imageLiteral(resourceName: "AddSearch").template, for: [])
        searchButton.accessibilityIdentifier = "BrowserViewController.customSearchEngineButton.searchButton"
        super.init(frame: frame)
        self.addSubview(searchButton)
        self.addSubview(loadingIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        //Setup view contraints here
        [self.searchButton!, self.loadingIndicator].forEach({
            $0.snp.makeConstraints { make in
                make.leading.equalTo(self.snp.leading)
                make.trailing.equalTo(self.snp.trailing)
                make.top.equalTo(self.snp.top)
                make.bottom.equalTo(self.snp.bottom)
            }
        })
        self.state = .disabled
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        searchButton.addTarget(target, action: action, for: controlEvents)
    }

}
