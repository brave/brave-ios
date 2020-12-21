// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import SnapKit
import BraveShared

// MARK: - OpenSearchEngineAddButton

class OpenSearchEngineAddButton: UIView {

    // MARK: State
    
    enum State {
        case loading
        case enabled
        case disabled
    }

    // MARK: Properties
    
    var state: State {
        didSet {
            switch state {
            case .disabled:
                searchButton.isHidden = hidesWhenDisabled ? true : false
                loadingIndicator.stopAnimating()
                searchButton.tintColor = UIColor.Photon.grey50
                searchButton.isUserInteractionEnabled = false
            case .enabled:
                searchButton.isHidden = false
                loadingIndicator.stopAnimating()
                searchButton.tintColor = .systemBlue
                searchButton.isUserInteractionEnabled = true
            case .loading:
                loadingIndicator.isHidden = false
                loadingIndicator.startAnimating()
                searchButton.isHidden = true
            }
        }
    }
    
    private let searchButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "AddSearch").template, for: [])
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.setTitleColor(BraveUX.braveOrange, for: .normal)
    }
    
    private let loadingIndicator = UIActivityIndicatorView(style: .white).then {
        $0.hidesWhenStopped = true
        $0.color = UIColor.Photon.grey50
    }
    
    private var hidesWhenDisabled: Bool = false
    
    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        self.state = .disabled
        super.init(frame: frame)
    }

    convenience init(title: String? = nil, hidesWhenDisabled: Bool = false) {
        self.init(frame: CGRect(x: 0, y: 0, width: 44.0, height: 44.0))
        

        self.hidesWhenDisabled = hidesWhenDisabled
        
        setTheme(with: title)
        doLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Internal
    
    private func setTheme(with title: String?) {
        if let title = title {
            searchButton.setImage(nil, for: .normal)
            searchButton.setTitle(title, for: .normal)
        }
    }
    
    private func doLayout() {
        addSubview(searchButton)
        addSubview(loadingIndicator)
        
        searchButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        searchButton.addTarget(target, action: action, for: controlEvents)
    }
}
