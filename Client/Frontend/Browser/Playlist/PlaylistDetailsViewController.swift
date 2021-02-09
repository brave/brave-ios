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
        
        view.backgroundColor = BraveUX.popoverDarkBackground
    }
    
    // MARK: Internal
    
    private let playlistSplitViewController = UISplitViewController()
    private let videoListViewController = PlaylistVideoListViewController()
    private let videoPlayerViewController = PlaylistVideoPlayerViewController()
    
    // MARK: Private
    
    private func setUpSplitViewController() {
        videoListViewController.delegate = self
        videoListViewController.videoPlayer = videoPlayerViewController
        
        videoPlayerViewController.delegate = self
        
        let videoListNavigationViewController = SettingsNavigationController(rootViewController: videoListViewController)
        let videoPlayerNavigationViewController = SettingsNavigationController(rootViewController: videoPlayerViewController)

        playlistSplitViewController.do {
            $0.viewControllers = [videoListNavigationViewController, videoPlayerNavigationViewController]
            $0.modalPresentationStyle = .fullScreen
            $0.preferredDisplayMode = .oneBesideSecondary
            $0.primaryEdge = .trailing
            $0.view.backgroundColor = .clear
        }
        
        addChild(playlistSplitViewController)
        view.addSubview(playlistSplitViewController.view)
            
        playlistSplitViewController.do {
            $0.didMove(toParent: self)
            $0.view.translatesAutoresizingMaskIntoConstraints = false
            $0.view.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }
    
    private func displayLoadingResourceError() {
        let alert = UIAlertController(
            title: Strings.PlayList.sorryAlertTitle, message: Strings.PlayList.loadResourcesErrorAlertDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: PlaylistVideoPlayerViewControllerDelegate

extension PlaylistDetailsViewController: PlaylistVideoPlayerViewControllerDelegate {
    
    func playlistVideoPlayerViewControllerDisplayResourceError(_ controller: PlaylistVideoPlayerViewController) {
        displayLoadingResourceError()
    }
    
    func playlistVideoPlayerViewControllerDidTapExit(_ controller: PlaylistVideoPlayerViewController) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: PlayListVideoListViewControllerDelegate

extension PlaylistDetailsViewController: PlaylistVideoListViewControllerDelegate {

    func playlistVideoListViewControllerDisplayResourceError(_ controller: PlaylistVideoListViewController) {
        displayLoadingResourceError()
    }
    
    func playlistVideoListViewControllerDisplayExpiredError(_ controller: PlaylistVideoListViewController, item: PlaylistInfo) {
        
        let alert = UIAlertController(title: Strings.PlayList.expiredLabelTitle, message: Strings.PlayList.expiredAlertTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: { _ in
            
            if let url = URL(string: item.pageSrc) {
                self.dismiss(animated: true, completion: nil)
                (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.openURLInNewTab(url, isPrivileged: false)
            }
        }))
        alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
