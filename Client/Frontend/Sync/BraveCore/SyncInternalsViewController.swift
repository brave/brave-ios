// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveCore

class SyncInternalsViewController: UIViewController {
    private let syncInternalsURL = "chrome://sync-internals"
    private let syncView: BraveSyncInternalsView
    
    init(syncAPI: BraveSyncAPI) {
        syncView = syncAPI.createSyncInternalsView()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Sync Internals"
        view.addSubview(syncView)
        syncView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        syncView.loadURL(syncInternalsURL)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction(handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }), menu: nil)
    }
}
