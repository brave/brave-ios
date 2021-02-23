// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import AVKit
import AVFoundation
import CoreData
import SnapKit
import BraveShared
import Shared

private let log = Logger.browserLogger

private protocol PlaylistPadControllerDetailDelegate: class {
    func setCurrentItemIndex(_ index: Int)
    func getCurrentItemIndex() -> Int
    func updateNowPlayingMediaInfo()
    func setControlsEnabled(_ enabled: Bool)
    func updatePlayerControlsState()
    func loadMediaItem(_ item: PlaylistInfo, index: Int, completion: @escaping (PlaylistMediaInfo.MediaPlaybackError) -> Void)
    func displayLoadingResourceError()
    func play()
    func stop()
}

class PlaylistPadViewController: UIViewController {
    private let splitController = UISplitViewController()
    private let listController = PlaylistPadListController()
    private let detailController = PlaylistPadDetailController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listController.detailControllerDelegate = detailController
        detailController.delegate = self
        
        splitController.do {
            $0.viewControllers = [SettingsNavigationController(rootViewController: listController).then {
                if #available(iOS 13.0, *) {
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithTransparentBackground()
                    appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                    appearance.backgroundColor = BraveUX.popoverDarkBackground
                    $0.navigationBar.standardAppearance = appearance
                    $0.navigationBar.scrollEdgeAppearance = appearance
                    $0.navigationBar.prefersLargeTitles = true
                } else {
                    $0.navigationBar.barTintColor = BraveUX.popoverDarkBackground
                    $0.navigationBar.tintColor = .white
                    $0.navigationBar.isTranslucent = false
                    $0.navigationBar.prefersLargeTitles = true
                }
            }, detailController]
            
            $0.preferredPrimaryColumnWidthFraction = 1.0 / 3.0
        }
        
        self.addChild(splitController)
        splitController.didMove(toParent: self)
        
        view.addSubview(splitController.view)
        splitController.view.snp.makeConstraints {
            $0.edges.equalTo(self.view)
        }
        
        updateLayoutForOrientationChange()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateLayoutForOrientationChange()
    }
    
    private func updateLayoutForOrientationChange() {
        if UIDevice.current.orientation.isLandscape {
            splitController.preferredDisplayMode = .secondaryOnly
        } else {
            splitController.preferredDisplayMode = .oneBesideSecondary
        }
    }
}

private class PlaylistPadListController: UIViewController {
    
    // MARK: Constants
     
     struct Constants {
        static let playListCellIdentifier = "playlistCellIdentifier"
        static let tableRowHeight: CGFloat = 120
        static let tableHeaderHeight: CGFloat = 11
     }

    // MARK: Properties
    
    weak var detailControllerDelegate: PlaylistPadControllerDetailDelegate?
    
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
    
    private let formatter = DateComponentsFormatter().then {
        $0.allowedUnits = [.day, .hour, .minute, .second]
        $0.unitsStyle = .abbreviated
        $0.maximumUnitCount = 1
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "playlist_exit"), style: .done, target: self, action: #selector(onExit(_:)))
        
        PlaylistManager.shared.delegate = self
        
        setTheme()
        setup()
        doLayout()
        
        fetchResults()
    }
    
    // MARK: Internal
    
    private func setTheme() {
        title = Strings.PlayList.playListSectionTitle

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
        tableView.do {
            $0.register(PlaylistCell.self, forCellReuseIdentifier: Constants.playListCellIdentifier)
            $0.dataSource = self
            $0.delegate = self
        }
    }
    
    private func doLayout() {
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func fetchResults() {
        detailControllerDelegate?.updatePlayerControlsState()
        updateTableBackgroundView()
        
        DispatchQueue.main.async {
            PlaylistManager.shared.reloadData()
            self.tableView.reloadData()
            
            if PlaylistManager.shared.numberOfAssets() > 0 {
                self.detailControllerDelegate?.setControlsEnabled(true)
                self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
            }
            
            self.updateTableBackgroundView()
        }
    }
    
    // MARK: - Actions
    
    @objc
    private func onExit(_ button: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension PlaylistPadListController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}

// MARK: UITableViewDataSource

extension PlaylistPadListController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PlaylistManager.shared.numberOfAssets()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableRowHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.playListCellIdentifier, for: indexPath) as? PlaylistCell else {
            return UITableViewCell()
        }
        
        let item = PlaylistManager.shared.itemAtIndex(indexPath.row)
        
        cell.do {
            $0.selectionStyle = .none
            $0.titleLabel.text = item.name
            $0.detailLabel.text = formatter.string(from: TimeInterval(item.duration)) ?? "0:00"
            $0.contentView.backgroundColor = .clear
            $0.backgroundColor = .clear
            $0.thumbnailImage = nil
        }
        
        let cacheState = PlaylistManager.shared.state(for: item.pageSrc)
        if cacheState == .inProgress {
            cell.detailLabel.text = Strings.PlayList.dowloadingLabelTitle
        } else if cacheState == .downloaded {
            cell.detailLabel.text = "\(formatter.string(from: TimeInterval(item.duration)) ?? "0:00") - \(Strings.PlayList.dowloadedLabelTitle)"
        }
        
        cell.loadThumbnail(item: item)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        
        return headerView
    }
}

extension PlaylistPadListController {
    func updateTableBackgroundView() {
        if PlaylistManager.shared.numberOfAssets() > 0 {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        } else {
            let messageLabel = UILabel(frame: view.bounds).then {
                $0.text = Strings.PlayList.noItemLabelTitle
                $0.textColor = .white
                $0.numberOfLines = 0
                $0.textAlignment = .center
                $0.font = .systemFont(ofSize: 18.0, weight: .medium)
                $0.sizeToFit()
            }
            
            tableView.backgroundView = messageLabel
            tableView.separatorStyle = .none
        }
    }
}

// MARK: UITableViewDelegate

extension PlaylistPadListController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.row < 0 || indexPath.row >= PlaylistManager.shared.numberOfAssets() {
            return nil
        }

        let currentItem = PlaylistManager.shared.itemAtIndex(indexPath.row)
        let cacheState = PlaylistManager.shared.state(for: currentItem.pageSrc)
        let downloadedItemTitle = cacheState == .invalid ? Strings.download : Strings.PlayList.clearActionButtonTitle
        
        let cacheAction = UIContextualAction(style: .normal, title: downloadedItemTitle, handler: { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            if cacheState == .inProgress {
                PlaylistManager.shared.cancelDownload(item: currentItem)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            } else if cacheState == .invalid {
                PlaylistManager.shared.download(item: currentItem)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                PlaylistManager.shared.deleteCache(item: currentItem)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            completionHandler(true)
        })
        
        let deleteAction = UIContextualAction(style: .normal, title: Strings.PlayList.removeActionButtonTitle, handler: { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            PlaylistManager.shared.delete(item: currentItem)

            if self.detailControllerDelegate?.getCurrentItemIndex() == indexPath.row {
                self.detailControllerDelegate?.setCurrentItemIndex(-1)
                self.detailControllerDelegate?.updateNowPlayingMediaInfo()
                
                self.activityIndicator.stopAnimating()
                self.detailControllerDelegate?.stop()
            }
            
            completionHandler(true)
        })

        cacheAction.image = cacheState == .invalid ? #imageLiteral(resourceName: "playlist_download") : #imageLiteral(resourceName: "playlist_delete_download")
        cacheAction.backgroundColor = #colorLiteral(red: 0.4509803922, green: 0.4784313725, blue: 0.8705882353, alpha: 1)
        
        deleteAction.image = #imageLiteral(resourceName: "playlist_delete_item")
        deleteAction.backgroundColor = #colorLiteral(red: 0.9176470588, green: 0.2274509804, blue: 0.05098039216, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [deleteAction, cacheAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < PlaylistManager.shared.numberOfAssets() {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            detailControllerDelegate?.setCurrentItemIndex(indexPath.row)

            let item = PlaylistManager.shared.itemAtIndex(indexPath.row)
            infoLabel.text = item.name
            detailControllerDelegate?.loadMediaItem(item, index: indexPath.row) { [weak self] error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                
                switch error {
                case .error(let err):
                    log.error(err)
                    self.detailControllerDelegate?.displayLoadingResourceError()
                    
                case .expired:
                    (tableView.cellForRow(at: indexPath) as? PlaylistCell)?.detailLabel.text = Strings.PlayList.expiredLabelTitle
                    
                    let alert = UIAlertController(title: Strings.PlayList.expiredLabelTitle, message: Strings.PlayList.expiredAlertTitle, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: { _ in
                        
                        if let url = URL(string: item.pageSrc) {
                            self.dismiss(animated: true, completion: nil)
                            (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.openURLInNewTab(url, isPrivileged: false)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                case .none:
                    (tableView.cellForRow(at: indexPath) as? PlaylistCell)?.loadThumbnail(item: item)
                }
            }
        }

        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        PlaylistManager.shared.reorderItems(from: sourceIndexPath, to: destinationIndexPath)
    }
}

extension PlaylistPadListController: PlaylistManagerDelegate {
    func onDownloadProgressUpdate(id: String, percentComplete: Double) {
        if let index = PlaylistManager.shared.index(of: id),
           let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PlaylistCell {
            
            let cacheState = PlaylistManager.shared.state(for: id)
            if cacheState == .inProgress {
                cell.detailLabel.text = "\(Strings.PlayList.dowloadingPercentageLabelTitle) \(percentComplete)%"
            } else if cacheState == .downloaded {
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = "\(formatter.string(from: TimeInterval(item.duration)) ?? "0:00") - \(Strings.PlayList.dowloadedLabelTitle)"
            } else {
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = formatter.string(from: TimeInterval(item.duration)) ?? "0:00"
            }
        }
    }
    
    func onDownloadStateChanged(id: String, state: PlaylistManager.DownloadState, displayName: String) {
        if let index = PlaylistManager.shared.index(of: id),
        let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PlaylistCell {
            
            if state == .inProgress {
                cell.detailLabel.text = Strings.PlayList.dowloadingLabelTitle
            } else if state == .downloaded {
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = "\(formatter.string(from: TimeInterval(item.duration)) ?? "0:00") - \(Strings.PlayList.dowloadedLabelTitle)"
            } else {
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = formatter.string(from: TimeInterval(item.duration)) ?? "0:00"
            }
        }
    }
    
    func controllerDidChange(_ anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                tableView.reloadRows(at: [indexPath!], with: .fade)
            case .move:
                tableView.deleteRows(at: [indexPath!], with: .fade)
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            default:
                break
        }
    }
    
    func controllerDidChangeContent() {
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent() {
        tableView.beginUpdates()
    }
}

private class PlaylistPadDetailController: UIViewController {
    
    weak var delegate: UIViewController?
    private let playerView = VideoView()
    private lazy var mediaInfo = PlaylistMediaInfo(playerView: playerView)
    private var currentlyPlayingItemIndex = -1
    private var playerController: AVPlayerViewController?
    
    deinit {
        playerView.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerView.delegate = self
        
        view.addSubview(playerView)
        playerView.snp.makeConstraints {
            $0.edges.equalTo(self.view)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        playerController = nil
    }
}

// MARK: VideoViewDelegate

extension PlaylistPadDetailController: VideoViewDelegate {
    func onPreviousTrack() {
        if currentlyPlayingItemIndex <= 0 {
            return
        }
        
        let index = currentlyPlayingItemIndex - 1
        if index < PlaylistManager.shared.numberOfAssets() {
            let item = PlaylistManager.shared.itemAtIndex(index)
            mediaInfo.loadMediaItem(item, index: index) { [weak self] error in
                if case .none = error {
                    self?.currentlyPlayingItemIndex = index
                } else {
                    self?.displayLoadingResourceError()
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
                if case .none = error {
                    self?.currentlyPlayingItemIndex = index
                } else {
                    self?.displayLoadingResourceError()
                }
            }
        }
    }
    
    func onPictureInPicture(enabled: Bool) {
        playerView.pictureInPictureController?.delegate = enabled ? self : nil
    }
    
    func onFullScreen() {
        let playerController = AVPlayerViewController().then {
            $0.player = playerView.player
            $0.delegate = self
            $0.allowsPictureInPicturePlayback = true
            $0.entersFullScreenWhenPlaybackBegins = true
        }
        
        if #available(iOS 14.2, *) {
            playerController.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        self.present(playerController, animated: true)
    }
}

// MARK: AVPlayerViewControllerDelegate

extension PlaylistPadDetailController: AVPlayerViewControllerDelegate, AVPictureInPictureControllerDelegate {

    // MARK: - AVPlayerViewControllerDelegate
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        playerView.detachLayer()
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        playerView.attachLayer()
    }
    
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        playerView.detachLayer()
        
        (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController = delegate
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        DispatchQueue.main.async {
            self.playerView.detachLayer()
            self.delegate?.dismiss(animated: true, completion: nil)
        }
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, failedToStartPictureInPictureWithError error: Error) {
        playerView.attachLayer()

        let alert = UIAlertController(title: Strings.PlayList.sorryAlertTitle, message: Strings.PlayList.pictureInPictureErrorTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
           let playlistPadController = delegate.playlistRestorationController {
            playerView.attachLayer()
            delegate.browserViewController.present(playlistPadController, animated: true) {
                self.playerView.player.play()
            }
            delegate.playlistRestorationController = nil
        }
        
        completionHandler(true)
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        
        (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController = delegate
        delegate?.dismiss(animated: true, completion: nil)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        
        let alert = UIAlertController(title: Strings.PlayList.sorryAlertTitle, message: Strings.PlayList.pictureInPictureErrorTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
           let playlistPadController = delegate.playlistRestorationController {
            delegate.browserViewController.present(controller: playlistPadController)
            delegate.playlistRestorationController = nil
        }
        
        completionHandler(true)
    }
}

extension PlaylistPadDetailController: PlaylistPadControllerDetailDelegate {
    
    func setCurrentItemIndex(_ index: Int) {
        currentlyPlayingItemIndex = index
    }
    
    func getCurrentItemIndex() -> Int {
        return currentlyPlayingItemIndex
    }
    
    func updateNowPlayingMediaInfo() {
        mediaInfo.updateNowPlayingMediaInfo()
    }
    
    func setControlsEnabled(_ enabled: Bool) {
        playerView.setControlsEnabled(enabled)
    }
    
    func updatePlayerControlsState() {
        playerView.setControlsEnabled(playerView.player.currentItem != nil)
    }
    
    func loadMediaItem(_ item: PlaylistInfo, index: Int, completion: @escaping (PlaylistMediaInfo.MediaPlaybackError) -> Void) {
        mediaInfo.loadMediaItem(item, index: index, completion: completion)
    }
    
    func displayLoadingResourceError() {
        let alert = UIAlertController(
            title: Strings.PlayList.sorryAlertTitle, message: Strings.PlayList.loadResourcesErrorAlertDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func play() {
        playerView.play()
    }
    
    func stop() {
        playerView.stop()
    }
}
