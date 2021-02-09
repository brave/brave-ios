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

// MARK: PlaylistVideoPlayerViewControllerDelegate

protocol PlaylistVideoPlayerViewControllerDelegate: AnyObject {

    func playlistVideoPlayerViewControllerDisplayResourceError(_ controller: PlaylistVideoPlayerViewController)

    func playlistVideoPlayerViewControllerDidTapExit(_ controller: PlaylistVideoPlayerViewController)
}

// MARK: PlaylistVideoPlayerViewController

class PlaylistVideoPlayerViewController: UIViewController {
    
    // MARK: Internal
    
    let playerView = VideoView()
    var currentlyPlayingItemIndex = -1
    lazy var mediaInfo = PlaylistMediaInfo(playerView: playerView)
    weak var delegate: PlaylistVideoPlayerViewControllerDelegate?
    
    // MARK: Lifecycle
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTheme()
        setup()
        doLayout()
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        performOrientationChanges()
    }
    
    func changeVideoControls(isEnabled: Bool = true, isCurrentItem: Bool = false) {
        if isCurrentItem {
            playerView.setControlsEnabled(playerView.player.currentItem != nil)
        } else {
            playerView.setControlsEnabled(isEnabled)
        }
    }
    
    // MARK: Private
    
    private lazy var activityIndicator = UIActivityIndicatorView(style: .white).then {
        $0.isHidden = true
        $0.hidesWhenStopped = true
    }
    
    private let infoLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12.0, weight: .regular)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.appearanceTextColor = .white
        $0.numberOfLines = 0
        $0.text = Strings.PlayList.playListSectionTitle
    }
    
    private func setTheme() {
        navigationController?.do {
            $0.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).appearanceTextColor = .white
            
            $0.presentationController?.delegate = self
            $0.navigationBar.tintColor = .white
            $0.navigationBar.isTranslucent = false
            $0.navigationBar.barTintColor = BraveUX.popoverDarkBackground
            $0.navigationBar.appearanceBarTintColor = BraveUX.popoverDarkBackground
            $0.navigationBar.setBackgroundImage(UIImage(), for: .default)
            $0.navigationBar.shadowImage = UIImage()
        }
        
        view.backgroundColor = .clear
    }
    
    private func setup () {
        performOrientationChanges()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "playlist_exit"), style: .done, target: self, action: #selector(onExit(_:)))
        
        playerView.delegate = self
    }
    
    private func doLayout() {
        view.addSubview(playerView)
        playerView.addSubview(activityIndicator)
        
        playerView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.60 * view.bounds.width)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func performOrientationChanges() {
        if UIDevice.current.orientation.isLandscape {
            splitViewController?.preferredDisplayMode = .allVisible
            navigationItem.rightBarButtonItem = nil
        } else {
            splitViewController?.preferredDisplayMode = .primaryOverlay
            navigationItem.rightBarButtonItem =
                UIBarButtonItem(image: #imageLiteral(resourceName: "playlist_video"), style: .done, target: self, action: #selector(onDisplayModeChange(_:)))
        }
    }
    
    private func updateSplitViewDisplayMode(to displayMode: UISplitViewController.DisplayMode) {
        UIView.animate(withDuration: 0.2) {
            self.splitViewController?.preferredDisplayMode = displayMode
        }
    }
    
    // MARK: Actions
    
    @objc
    private func onExit(_ button: UIBarButtonItem) {
        delegate?.playlistVideoPlayerViewControllerDidTapExit(self)
    }
    
    @objc
    private func onDisplayModeChange(_ button: UIBarButtonItem) {
        updateSplitViewDisplayMode(
            to: splitViewController?.displayMode == .primaryOverlay ? .allVisible : .primaryOverlay)
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension PlaylistVideoPlayerViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}

// MARK: VideoViewDelegate

extension PlaylistVideoPlayerViewController: VideoViewDelegate {
    
    func onPreviousTrack() {
        if currentlyPlayingItemIndex <= 0 {
            return
        }
        
        let index = currentlyPlayingItemIndex - 1
        if index < PlaylistManager.shared.numberOfAssets() {
            let item = PlaylistManager.shared.itemAtIndex(index)
            mediaInfo.loadMediaItem(item, index: index) { [weak self] error in
                guard let self = self else { return }

                if case .none = error {
                    self.currentlyPlayingItemIndex = index
                } else {
                    self.delegate?.playlistVideoPlayerViewControllerDisplayResourceError(self)
                }
            }
        }
    }
    
    func onNextTrack() {
        if currentlyPlayingItemIndex >= PlaylistManager.shared.numberOfAssets() - 1 {
            return
        }
        
        let index = currentlyPlayingItemIndex + 1
        if index >= 0 {
            let item = PlaylistManager.shared.itemAtIndex(index)
            mediaInfo.loadMediaItem(item, index: index) { [weak self] error in
                guard let self = self else { return }
                
                if case .none = error {
                    self.currentlyPlayingItemIndex = index
                } else {
                    self.delegate?.playlistVideoPlayerViewControllerDisplayResourceError(self)
                }
            }
        }
    }
    
    func onPictureInPicture(enabled: Bool) {
        playerView.pictureInPictureController?.delegate = enabled ? self : nil
    }
    
    func onFullScreen() {
        playerView.player.pause()
        
        let playerController = AVPlayerViewController().then {
            $0.player = playerView.player
            $0.delegate = self
            $0.allowsPictureInPicturePlayback = true
        }
        
        if #available(iOS 14.2, *) {
            playerController.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        playerController.entersFullScreenWhenPlaybackBegins = true
        
        self.present(playerController, animated: true, completion: {
            playerController.player?.play()
        })
    }
}

// MARK: AVPlayerViewControllerDelegate

extension PlaylistVideoPlayerViewController: AVPlayerViewControllerDelegate, AVPictureInPictureControllerDelegate {

    // MARK: - AVPlayerViewControllerDelegate
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        (UIApplication.shared.delegate as? AppDelegate)?.playlistNavigationController = self.navigationController
        self.dismiss(animated: true, completion: nil)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, failedToStartPictureInPictureWithError error: Error) {
        
        let alert = UIAlertController(title: Strings.PlayList.sorryAlertTitle, message: Strings.PlayList.pictureInPictureErrorTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
           let navigationController = delegate.playlistNavigationController {
            delegate.browserViewController.present(controller: navigationController)
            delegate.playlistNavigationController = nil
        }
        
        completionHandler(true)
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        
        (UIApplication.shared.delegate as? AppDelegate)?.playlistNavigationController = self.navigationController
        self.dismiss(animated: true, completion: nil)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        
        let alert = UIAlertController(title: Strings.PlayList.sorryAlertTitle, message: Strings.PlayList.pictureInPictureErrorTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
           let navigationController = delegate.playlistNavigationController {
            delegate.browserViewController.present(controller: navigationController)
            delegate.playlistNavigationController = nil
        }
        
        completionHandler(true)
    }
}
