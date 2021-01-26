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

private let log = Logger.browserLogger

// MARK: PlaylistViewController

class PlaylistViewController: UIViewController {
    
    // MARK: Constants
     
     struct Constants {
        static let playListCellIdentifier = "playlistCellIdentifier"
        static let tableRowDimension: CGFloat = 70
     }

    // MARK: Properties
    
    private let playerView = VideoView()
    
    private let playlistFRC = Playlist.shared.fetchResultsController()
    
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
    
    private var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.backgroundView = UIView()
        $0.backgroundColor = BraveUX.popoverDarkBackground
        $0.appearanceBackgroundColor = BraveUX.popoverDarkBackground
        $0.separatorColor = .clear
        $0.appearanceSeparatorColor = .clear
    }

    private lazy var mediaInfo = PlaylistMediaInfo(playerView: playerView)
    
    private var currentItem = -1
    
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

        fetchResults()
    }
    
    // MARK: Internal
    
    private func setTheme() {
        title = Strings.PlayList.mediaPlayerSectionTitle

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
        
        view.backgroundColor = BraveUX.popoverDarkBackground
        
        tableView.do {
            //tableView.contentInsetAdjustmentBehavior = .never
            $0.contentInset = UIEdgeInsets(top: 0.60 * view.bounds.width, left: 0.0, bottom: 0.0, right: 0.0)
            $0.contentOffset = CGPoint(x: 0.0, y: -0.60 * view.bounds.width)
        }
    }
    
    private func setup () {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "playlist_exit"), style: .done, target: self, action: #selector(onExit(_:)))
              
        tableView.do {
            $0.register(PlaylistCell.self, forCellReuseIdentifier: Constants.playListCellIdentifier)
            $0.dataSource = self
            $0.delegate = self
        }
        
        playerView.delegate = self
    }
    
    private func doLayout() {
        view.addSubview(tableView)
        view.addSubview(playerView)
        playerView.addSubview(activityIndicator)
        
        playerView.snp.makeConstraints {
            $0.top.equalTo(view.safeArea.top)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.60 * view.bounds.width)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeArea.edges)
        }
    }
    
    private func fetchResults() {
        DispatchQueue.main.async {
            try? self.playlistFRC.performFetch()
            self.tableView.reloadData()
        }
    }
    
    // MARK: Actions
    
    @objc
    private func onExit(_ button: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension PlaylistViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}

// MARK: UITableViewDataSource

extension PlaylistViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistFRC.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableRowDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableRowDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.playListCellIdentifier, for: indexPath) as? PlaylistCell else {
            return UITableViewCell()
        }
        
        let item = playlistFRC.object(at: indexPath)
        guard let mediaSrc = item.mediaSrc else {
            return UITableViewCell()
        }
        
        cell.do {
            $0.selectionStyle = .none
            $0.indicatorIcon.image = #imageLiteral(resourceName: "playlist_currentitem_indicator").template
            $0.indicatorIcon.alpha = 0.0
            $0.titleLabel.text = item.name
            $0.detailLabel.text = String(format: "%.2fm", item.duration / 60.0)
            $0.contentView.backgroundColor = .clear
            $0.backgroundColor = .clear
            $0.thumbnailImage = #imageLiteral(resourceName: "menu-NoImageMode")
        }
        
        if let url = URL(string: mediaSrc) {
            AVAsset(url: url).generateThumbnail { image in
                if let thumbnailImage = image {
                    cell.thumbnailImage = thumbnailImage
                }
            }
        }
        
        if indexPath.row == currentItem {
            cell.indicatorIcon.image = #imageLiteral(resourceName: "playlist_currentitem_indicator")
            cell.indicatorIcon.alpha = 1.0
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return PlaylistFilterView()/*.then {
            if let playlistItems = self.playlistFRC.fetchedObjects {
                if currentItem != -1 && currentItem < playlistItems.count {
                    $0.titleLabel.text = playlistItems[currentItem].name
                    $0.detailLabel.text = URL(string: playlistItems[currentItem].pageSrc!)?.baseDomain
                    $0.addButton.isHidden = true
                }
                $0.addButton.addTarget(self, action: #selector(onAddItem(_:)), for: .touchUpInside)
            }
        }*/
    }
}

// MARK: UITableViewDelegate

extension PlaylistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let playlistItems = playlistFRC.fetchedObjects,
              !playlistItems.isEmpty else {
            return nil
        }
        
        let currentItem = PlaylistInfo(item: playlistItems[indexPath.row])
        let itemURL = URL(string: currentItem.src)
        let cache = Playlist.shared.getCache(item: currentItem)
        let downloadedItemTitle = cache.isEmpty ? Strings.download : Strings.PlayList.clearActionButtonTitle
        
        let cacheAction = UIContextualAction(style: .normal, title: downloadedItemTitle, handler: { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            if cache.isEmpty, let itemURL = itemURL {
                URLSession(configuration: .ephemeral).dataTask(with: itemURL) { [weak self] data, response, error in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        if let error = error {
                            let alert = UIAlertController(
                                title: Strings.PlayList.noticeAlertTitle, message: Strings.PlayList.downloadErrorAlertDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
                            
                            self.present(alert, animated: true, completion: nil)
                            
                            log.error(error)
                            completionHandler(false)
                            
                            return
                        }
                        
                        self.currentItem = -1
                        self.mediaInfo.updateNowPlayingMediaInfo()
                        //Playlist.shared.currentlyPlayingInfo.value = nil
                        
                        //currentItem.mimeType = response?.mimeType
                        Playlist.shared.updateCache(item: currentItem, cachedData: data ?? Data())
                        completionHandler(true)
                        
                        self.tableView.reloadData()
                    }
                }.resume()
            } else {
                Playlist.shared.updateCache(item: currentItem, cachedData: Data())
                completionHandler(true)
                
                self.tableView.reloadData()
            }
        })
        
        let deleteAction = UIContextualAction(style: .normal, title: Strings.PlayList.removeActionButtonTitle, handler: { [weak self] (action, view, completionHandler) in
            guard let self = self,
                  let playlistItems = self.playlistFRC.fetchedObjects,
                  !playlistItems.isEmpty else { return }
            
            let item = PlaylistInfo(item: playlistItems[indexPath.row])
            Playlist.shared.removeItem(item: item)
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)

            if self.currentItem == indexPath.row {
                self.currentItem = -1
                self.mediaInfo.updateNowPlayingMediaInfo()
                //Playlist.shared.currentlyPlayingInfo.value = nil
                
                self.activityIndicator.stopAnimating()
                self.playerView.stop()
            }
            
            completionHandler(true)
            self.tableView.reloadData()
        })

        cacheAction.image = cache.isEmpty ? #imageLiteral(resourceName: "menu-downloads") : #imageLiteral(resourceName: "nowPlayingCheckmark")
        cacheAction.backgroundColor = .white
        deleteAction.backgroundColor = #colorLiteral(red: 0.812063769, green: 0.04556301224, blue: 0, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [deleteAction, cacheAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let playlistItems = playlistFRC.fetchedObjects,
              !playlistItems.isEmpty else { return }
        
        if indexPath.row < playlistItems.count {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            currentItem = indexPath.row

            let item = PlaylistInfo(item: playlistItems[indexPath.row])
            infoLabel.text = item.name
            mediaInfo.loadMediaItem(item) { [weak self] error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()

                if let error = error {
                    log.error(error)
                    self.displayLoadingResourceError()
                }
            }
        }

        tableView.reloadData()
    }
    
    private func displayLoadingResourceError() {
        let alert = UIAlertController(
            title: Strings.PlayList.sorryAlertTitle, message: Strings.PlayList.loadResourcesErrorAlertDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: VideoViewDelegate

extension PlaylistViewController: VideoViewDelegate {
    func onPreviousTrack() {
        guard let currentItem = mediaInfo.nowPlayingInfo,
              let playlistItems = playlistFRC.fetchedObjects,
              let index = playlistItems.firstIndex(where: { $0.mediaSrc == currentItem.src }) else {
            return
        }
        
        if index > 0 && index < playlistItems.count - 1 {
            mediaInfo.loadMediaItem(PlaylistInfo(item: playlistItems[index - 1])) { [weak self] error in
                if error != nil {
                    self?.displayLoadingResourceError()
                } else {
                    self?.currentItem = index - 1
                }
            }
        }
    }
    
    func onNextTrack() {
        guard let currentItem = mediaInfo.nowPlayingInfo,
              let playlistItems = playlistFRC.fetchedObjects,
              let index = playlistItems.firstIndex(where: { $0.mediaSrc == currentItem.src }) else {
            return
        }
        
        if index >= 0 && index < playlistItems.count - 1 {
            mediaInfo.loadMediaItem(PlaylistInfo(item: playlistItems[index + 1])) { [weak self] error in
                if error != nil {
                    self?.displayLoadingResourceError()
                } else {
                    self?.currentItem = index + 1
                }
            }
        }
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
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
            print("SUPPORTED")
        } else {
            print("NOT SUPPORTED")
        }
    }
}

// MARK: AVPlayerViewControllerDelegate

extension PlaylistViewController: AVPlayerViewControllerDelegate {
    //TODO: When entering PIP, dismiss the current playlist controller.
    //TODO: When exiting PIP, destroy the video player and its media info. Clear control centre, etc.
}
