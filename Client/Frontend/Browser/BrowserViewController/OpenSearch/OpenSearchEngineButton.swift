// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveUI
import SnapKit
import BraveShared

class OpenSearchEngineButton: Button {

    // MARK: Action
    
    enum Action {
        case loading
        case enabled
        case disabled
    }

    // MARK: Properties
    
    var action: Action {
        didSet {
            switch action {
            case .disabled:
                searchButton.isHidden = hidesWhenDisabled ? true : false
                isLoading = false
                searchButton.appearanceTintColor = UIColor.Photon.grey50
                searchButton.appearanceTextColor = UIColor.Photon.grey50
                searchButton.isUserInteractionEnabled = false
            case .enabled:
                searchButton.isHidden = false
                isLoading = false
                searchButton.appearanceTintColor = BraveUX.braveOrange
                searchButton.appearanceTextColor = BraveUX.braveOrange
                searchButton.isUserInteractionEnabled = true
            case .loading:
                isLoading = true
                searchButton.isHidden = true
            }
        }
    }
    
    private let searchButton = UIButton().then {
        $0.setImage(#imageLiteral(resourceName: "AddSearch").template, for: [])
        $0.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
    private var hidesWhenDisabled: Bool = false
    
    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        self.action = .disabled
        super.init(frame: frame)
    }

    convenience init(title: String? = nil, hidesWhenDisabled: Bool) {
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
        
        loaderView = LoaderView(size: .small).then {
            $0.tintColor = UIColor.Photon.grey50
        }
    }
    
    private func doLayout() {
        addSubview(searchButton)
        
        searchButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

