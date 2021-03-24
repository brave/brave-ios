// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveShared
import Shared
import AVKit
import AVFoundation
import SDWebImage
import CoreData

private let log = Logger.browserLogger

// MARK: PlaylistDetailsViewController

class PlaylistDetailsViewController: UIViewController {
    
    // MARK: Lifecycle
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSplitViewController()
    }
    
    // MARK: Internal
    
    let playlistSplitViewController = UISplitViewController()
    let videoListViewController = PlaylistVideoListViewController()
    let videoPlayerViewController = PlaylistVideoPlayerViewController()

    // MARK: Private
    
    private func setUpSplitViewController() {
        let videoListNavigationViewController = SettingsNavigationController(rootViewController: videoListViewController)
        let videoPlayerNavigationViewController = SettingsNavigationController(rootViewController: videoPlayerViewController)

        playlistSplitViewController.do {
            $0.viewControllers = [videoListNavigationViewController, videoPlayerNavigationViewController]
            $0.modalPresentationStyle = .fullScreen
            $0.preferredDisplayMode = .oneBesideSecondary
            $0.primaryEdge = .trailing
        }
        
        addChild(playlistSplitViewController)
        view.addSubview(playlistSplitViewController.view)
            
        playlistSplitViewController.didMove(toParent: self)
        playlistSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        playlistSplitViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
