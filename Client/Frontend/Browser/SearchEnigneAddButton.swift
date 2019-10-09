// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import SnapKit
import BraveShared

class SearchEnigneAddButton: UIView {
    
    enum Alignment {
        case center
        case left
        case right
    }
    
    enum State {
        case loading
        case enabled
        case disabled
    }
    
    var loaderAlignment: Alignment = .center
    
    var state: State {
        didSet {
            switch state {
            case .disabled:
                self.searchButton.isHidden = hidesWhenDisabled ? true : false
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
    private let searchButton: UIButton!
    private let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .white)
    private var hidesWhenDisabled: Bool = false
    override init(frame: CGRect) {
        self.state = .disabled
        self.searchButton = UIButton()
        searchButton.setImage(#imageLiteral(resourceName: "AddSearch").template, for: [])
        searchButton.accessibilityIdentifier = "BrowserViewController.customSearchEngineButton.searchButton"
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = UIColor.Photon.Grey50
        super.init(frame: frame)
        addSubview(searchButton)
        addSubview(loadingIndicator)
    }
    
    convenience init(title: String?, hidesWhenDisabled: Bool) {
        self.init(frame: CGRect(x: 0, y: 0, width: 44.0, height: 44.0))
        if let title = title {
            searchButton.setImage(nil, for: .normal)
            searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            searchButton.setTitle(title, for: .normal)
            searchButton.setTitleColor(BraveUX.BraveOrange, for: .normal)
        }
        self.hidesWhenDisabled = hidesWhenDisabled
        setConstraints()
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setConstraints() {
        searchButton.snp.remakeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        loadingIndicator.snp.remakeConstraints { make in
            switch loaderAlignment {
            case .center:
                make.center.equalToSuperview()
            case .left:
                make.right.equalToSuperview()
            case .right:
                make.left.equalToSuperview()
            }
        }
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        searchButton.addTarget(target, action: action, for: controlEvents)
    }
}
