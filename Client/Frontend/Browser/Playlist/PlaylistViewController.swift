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

// MARK: - DisplayMode

private enum DisplayMode {
    case iPhoneLayout
    case iPadLayout
}

// MARK: PlaylistViewController

class PlaylistViewController: UIViewController {
    
    // MARK: Properties

    private let splitController = UISplitViewController()
    private let listController = ListController()
    private let detailController = DetailController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitController.do {
            $0.viewControllers = [SettingsNavigationController(rootViewController: listController),
                                  SettingsNavigationController(rootViewController: detailController)]
            $0.delegate = self
            $0.primaryEdge = PlayListSide(rawValue: Preferences.Playlist.listViewSide.value) == .left ? .leading : .trailing
            $0.presentsWithGesture = false
            $0.maximumPrimaryColumnWidth = 400
            $0.minimumPrimaryColumnWidth = 400
        }
        
        addChild(splitController)
        view.addSubview(splitController.view)
        
        splitController.do {
            $0.didMove(toParent: self)
            $0.view.translatesAutoresizingMaskIntoConstraints = false
            $0.view.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        
        updateLayoutForOrientationChange()
        
        // This has to be manually called because when launching a split controller in landscape, it does NOT call `viewDidLoad` on the primary/list controller!
        listController.loadViewIfNeeded()
        detailController.setVideoPlayer(listController.playerView)
        
        if UIDevice.isIpad {
            listController.updateLayoutForMode(.iPadLayout)
            detailController.updateLayoutForMode(.iPadLayout)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateLayoutForOrientationChange()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func updateLayoutForOrientationChange() {
        if listController.playerView.isFullscreen {
            splitController.preferredDisplayMode = .secondaryOnly
        } else {
            if UIDevice.current.orientation.isLandscape {
                splitController.preferredDisplayMode = .secondaryOnly
            } else {
                splitController.preferredDisplayMode = .primaryOverlay
            }
        }
    }
    
    fileprivate func onFullscreen() {
        detailController.onFullScreen()
    }
    
    fileprivate func onExitFullscreen() {
        detailController.onExitFullScreen()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension PlaylistViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}

// MARK: - UISplitViewControllerDelegate

extension PlaylistViewController: UISplitViewControllerDelegate {
    func splitViewControllerSupportedInterfaceOrientations(_ splitViewController: UISplitViewController) -> UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        // On iPhone, always display the iPhone layout (collapsed) no matter what.
        // On iPad, we need to update both the list controller's layout (collapsed) and the detail controller's layout (collapsed).
        listController.updateLayoutForMode(.iPhoneLayout)
        detailController.setVideoPlayer(nil)
        detailController.updateLayoutForMode(.iPhoneLayout)
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        // On iPhone, always display the iPad layout (expanded) when not in compact mode.
        // On iPad, we need to update both the list controller's layout (expanded) and the detail controller's layout (expanded).
        listController.updateLayoutForMode(.iPadLayout)
        detailController.setVideoPlayer(listController.playerView)
        detailController.updateLayoutForMode(.iPadLayout)
        return detailController.navigationController
    }
}

// MARK: - ListController

private class ListController: UIViewController {
    // MARK: Constants
     
     struct Constants {
        static let playListCellIdentifier = "playlistCellIdentifier"
        static let tableRowHeight: CGFloat = 80
        static let tableHeaderHeight: CGFloat = 11
     }

    // MARK: Properties
    
    public let playerView = VideoView()
    private lazy var mediaInfo = PlaylistMediaInfo(playerView: playerView)
    private var currentlyPlayingItemIndex = -1
    private var autoPlayEnabled: Bool = true
    private var playerController: AVPlayerViewController?
    
    private lazy var activityIndicator = UIActivityIndicatorView(style: .white).then {
        $0.isHidden = true
        $0.hidesWhenStopped = true
    }
    
    private var tableView = UITableView(frame: .zero, style: .grouped).then {
        $0.backgroundView = UIView()
        $0.backgroundColor = BraveUX.popoverDarkBackground
        $0.appearanceBackgroundColor = BraveUX.popoverDarkBackground
        $0.separatorColor = .clear
        $0.appearanceSeparatorColor = .clear
        $0.allowsSelectionDuringEditing = true
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
    
    deinit {
        playerView.stop()
        playerView.pictureInPictureController?.delegate = nil
        playerView.pictureInPictureController?.stopPictureInPicture()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PlaylistManager.shared.delegate = self
    
        setTheme()
        setup()
        doLayout()

        fetchResults()
    }
    
    // MARK: Internal
    
    private func setTheme() {
        title = Strings.PlayList.playListSectionTitle

        view.backgroundColor = BraveUX.popoverDarkBackground
        navigationController?.do {
            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.backgroundColor = BraveUX.popoverDarkBackground
                
                $0.navigationBar.standardAppearance = appearance
                $0.navigationBar.barTintColor = BraveUX.popoverDarkBackground
                $0.navigationBar.tintColor = .white
            } else {
                $0.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
                UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).appearanceTextColor = .white
                $0.navigationBar.backgroundColor = .clear
                $0.navigationBar.barTintColor = BraveUX.popoverDarkBackground
                $0.navigationBar.tintColor = .white
                $0.navigationBar.isTranslucent = false
                $0.navigationBar.setBackgroundImage(UIImage(), for: .default)
                $0.navigationBar.shadowImage = UIImage()
            }
        }
    }
    
    private func setup () {
        tableView.do {
            $0.register(PlaylistCell.self, forCellReuseIdentifier: Constants.playListCellIdentifier)
            $0.dataSource = self
            $0.delegate = self
            $0.dragDelegate = self
            $0.dropDelegate = self
            $0.dragInteractionEnabled = true
        }
        
        playerView.delegate = self
    }
    
    private func doLayout() {
        view.addSubview(tableView)
        view.addSubview(playerView)
        playerView.addSubview(activityIndicator)
        
        if UIDevice.isPhone {
            updateLayoutForMode(.iPhoneLayout)
        } else {
            updateLayoutForMode(.iPadLayout)
        }
    }
    
    private func fetchResults() {
        playerView.setControlsEnabled(playerView.player.currentItem != nil)
        updateTableBackgroundView()
        
        DispatchQueue.main.async {
            PlaylistManager.shared.reloadData()
            self.tableView.reloadData()
            
            self.autoPlayEnabled = Preferences.Playlist.firstLoadAutoPlay.value
            
            if PlaylistManager.shared.numberOfAssets() > 0 {
                self.playerView.setControlsEnabled(true)
                
                if let lastPlayedItemUrl = Preferences.Playlist.lastPlayedItemUrl.value, let index = PlaylistManager.shared.index(of: lastPlayedItemUrl) {
                    self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: IndexPath(row: index, section: 0))
                } else {
                    self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
                }
                
                self.autoPlayEnabled = true
            }
            
            self.updateTableBackgroundView()
        }
    }
    
    // MARK: Actions
    
    @objc
    private func onExit(_ button: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public func updateLayoutForMode(_ mode: DisplayMode) {
        navigationItem.rightBarButtonItem = nil
        
        if mode == .iPhoneLayout {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onExit(_:)))
            
            // If the player view is in fullscreen, we should NOT change the tableView layout on rotation.
            view.addSubview(playerView)
            if !playerView.isFullscreen {
                if UIDevice.current.orientation.isLandscape && UIDevice.isPhone {
                    playerView.setFullscreenButtonHidden(true)
                    playerView.snp.remakeConstraints {
                        $0.edges.equalTo(view.safeArea.edges)
                    }
                    
                    activityIndicator.snp.remakeConstraints {
                        $0.center.equalToSuperview()
                    }
                } else {
                    playerView.setFullscreenButtonHidden(false)
                    let videoPlayerHeight = (1.0 / 3.0) * (UIScreen.main.bounds.width > UIScreen.main.bounds.height ? UIScreen.main.bounds.width : UIScreen.main.bounds.height)

                    tableView.do {
                        $0.contentInset = UIEdgeInsets(top: videoPlayerHeight, left: 0.0, bottom: view.safeAreaInsets.bottom, right: 0.0)
                        $0.scrollIndicatorInsets = $0.contentInset
                        $0.contentOffset = CGPoint(x: 0.0, y: -videoPlayerHeight)
                        $0.isHidden = false
                    }
                    
                    playerView.snp.remakeConstraints {
                        $0.top.equalTo(view.safeArea.top)
                        $0.leading.trailing.equalToSuperview()
                        $0.height.equalTo(videoPlayerHeight)
                    }
                    
                    activityIndicator.snp.remakeConstraints {
                        $0.center.equalToSuperview()
                    }
                    
                    tableView.snp.remakeConstraints {
                        $0.edges.equalToSuperview()
                    }
                    
                    // On iPhone-8, 14.4, I need to scroll the tableView after setting its contentOffset and contentInset
                    // Otherwise the layout is broken when exiting fullscreen in portrait mode.
                    if PlaylistManager.shared.numberOfAssets() > 0 {
                        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    }
                }
            } else {
                playerView.snp.remakeConstraints {
                    $0.edges.equalToSuperview()
                }
                
                activityIndicator.snp.remakeConstraints {
                    $0.center.equalToSuperview()
                }
            }
        } else {
            playerView.setFullscreenButtonHidden(UIDevice.isPhone)
            
            tableView.do {
                $0.contentInset = .zero
                $0.scrollIndicatorInsets = $0.contentInset
                $0.contentOffset = .zero
            }
            
            tableView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if splitViewController?.isCollapsed == true {
            updateLayoutForMode(.iPhoneLayout)
            
            if !playerView.isFullscreen {
                navigationController?.setNavigationBarHidden(UIDevice.current.orientation.isLandscape, animated: true)
            }
        }
    }
}

// MARK: UITableViewDataSource

extension ListController: UITableViewDataSource {
    private func getRelativeDateFormat(date: Date) -> String {
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.dateTimeStyle = .numeric
            return formatter.localizedString(fromTimeInterval: date.timeIntervalSinceNow)
        } else {
            fatalError("We're dropping iOS 12..")
        }
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
            $0.detailLabel.text = ""
            $0.contentView.backgroundColor = .clear
            $0.backgroundColor = .clear
            $0.thumbnailView.image = nil
            $0.thumbnailView.backgroundColor = .black
        }
        
        let cacheState = PlaylistManager.shared.state(for: item.pageSrc)
        switch cacheState {
        case .inProgress:
            cell.detailLabel.text = Strings.PlayList.dowloadingLabelTitle
        case .downloaded:
            if let itemSize = PlaylistManager.shared.sizeOfDownloadedItem(for: item.pageSrc) {
                cell.detailLabel.text = "\(getRelativeDateFormat(date: item.dateAdded)) - \(itemSize)"
            } else {
                cell.detailLabel.text = "\(getRelativeDateFormat(date: item.dateAdded)) - \(Strings.PlayList.dowloadedLabelTitle)"
            }
        case .invalid:
            cell.detailLabel.text = getRelativeDateFormat(date: item.dateAdded)
        }
        
        // Fixes a duration bug where sometimes the duration is NOT fetched!
        // So when we fetch the thumbnail, the duration will be updated (if possible)
        loadThumbnail(item: item, cell: cell) { newTrackDuration in
            guard let newTrackDuration = newTrackDuration else { return }
            
            if newTrackDuration > 0.0 && item.duration <= 0.0 {
                let newItem = PlaylistInfo(name: item.name,
                                           src: item.src,
                                           pageSrc: item.pageSrc,
                                           pageTitle: item.pageTitle,
                                           mimeType: item.mimeType,
                                           duration: Float(newTrackDuration),
                                           detected: item.detected,
                                           dateAdded: item.dateAdded)
                Playlist.shared.updateItem(mediaSrc: item.src, item: newItem)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        
        return headerView
    }
    
    // MARK: - Thumbnail
    
    private func loadThumbnail(item: PlaylistInfo, cell: PlaylistCell, onDurationUpdated: ((TimeInterval?) -> Void)? = nil) {
        guard let url = URL(string: item.src) else { return }
        
        // Loading from Cache failed, attempt to fetch HLS thumbnail
        cell.thumbnailGenerator = HLSThumbnailGenerator(url: url, time: 3, completion: { [weak self] image, trackDuration, error in
            guard let self = self else { return }
            
            log.error(error)
            
            if let trackDuration = trackDuration {
                onDurationUpdated?(trackDuration)
            }
            
            if let image = image {
                cell.thumbnailView.image = image
                cell.thumbnailView.backgroundColor = .black
                cell.thumbnailGenerator = nil
                SDImageCache.shared.store(image, forKey: url.absoluteString, completion: nil)
            } else {
                // We can fall back to AVAssetImageGenerator or FavIcon
                self.loadThumbnailFallbackImage(item: item, cell: cell)
            }
        })
    }
    
    // Fall back to AVAssetImageGenerator
    // If that fails, fallback to FavIconFetcher
    private func loadThumbnailFallbackImage(item: PlaylistInfo, cell: PlaylistCell) {
        guard let url = URL(string: item.src) else { return }

        let imageCache = SDImageCache.shared
        let imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: url))
        imageGenerator.appliesPreferredTrackTransform = false

        let time = CMTimeMake(value: 3, timescale: 1)
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
            if result == .succeeded, let cgImage = cgImage {
                let image = UIImage(cgImage: cgImage)
                imageCache.store(image, forKey: url.absoluteString, completion: nil)
                
                DispatchQueue.main.async {
                    cell.thumbnailView.image = image
                    cell.thumbnailView.backgroundColor = .black
                }
            } else {
                guard let url = URL(string: item.pageSrc) else { return }
                
                DispatchQueue.main.async {
                    cell.thumbnailView.cancelFaviconLoad()
                    cell.thumbnailView.clearMonogramFavicon()
                    cell.thumbnailView.contentMode = .scaleAspectFit
                    cell.thumbnailView.image = FaviconFetcher.defaultFaviconImage
                    cell.thumbnailView.loadFavicon(for: url) {
                        cell.thumbnailView.contentMode = .scaleAspectFit
                    }
                }
            }
        }
    }
}

// MARK: UITableViewDelegate

extension ListController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.row < 0 || indexPath.row >= PlaylistManager.shared.numberOfAssets() {
            return nil
        }

        let currentItem = PlaylistManager.shared.itemAtIndex(indexPath.row)
        let cacheState = PlaylistManager.shared.state(for: currentItem.pageSrc)
        let downloadedItemTitle = cacheState == .invalid ? Strings.download : Strings.PlayList.clearActionButtonTitle
        
        let cacheAction = UIContextualAction(style: .normal, title: downloadedItemTitle, handler: { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            switch cacheState {
                case .inProgress:
                    PlaylistManager.shared.cancelDownload(item: currentItem)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                case .invalid:
                    PlaylistManager.shared.download(item: currentItem)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                case .downloaded:
                    let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
                    let alert = UIAlertController(
                        title: Strings.PlayList.removePlaylistDownloadedVideoAlertTitle, message: Strings.PlayList.removePlaylistDownloadedVideoAlertMessage, preferredStyle: style)
                    
                    alert.addAction(UIAlertAction(title: Strings.PlayList.removePlaylistDownloadedVideoClearButton, style: .default, handler: { _ in
                        PlaylistManager.shared.deleteCache(item: currentItem)
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }))
                    
                    alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
            }
            
            completionHandler(true)
        })
        
        let deleteAction = UIContextualAction(style: .normal, title: Strings.PlayList.removeActionButtonTitle, handler: { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
            let alert = UIAlertController(
                title: Strings.PlayList.removePlaylistVideoAlertTitle, message: Strings.PlayList.removePlaylistVideoAlertMessage, preferredStyle: style)
            
            alert.addAction(UIAlertAction(title: Strings.delete, style: .default, handler: { _ in
                PlaylistManager.shared.delete(item: currentItem)

                if self.currentlyPlayingItemIndex == indexPath.row {
                    self.currentlyPlayingItemIndex = -1
                    self.mediaInfo.nowPlayingInfo = nil
                    self.mediaInfo.updateNowPlayingMediaArtwork(image: nil)
                    
                    self.activityIndicator.stopAnimating()
                    self.playerView.stop()
                }
            }))
            
            alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            completionHandler(true)
        })

        cacheAction.image = cacheState == .invalid ? #imageLiteral(resourceName: "playlist_download") : #imageLiteral(resourceName: "playlist_delete_download")
        cacheAction.backgroundColor = #colorLiteral(red: 0.4509803922, green: 0.4784313725, blue: 0.8705882353, alpha: 1)
        
        deleteAction.image = #imageLiteral(resourceName: "playlist_delete_item")
        deleteAction.backgroundColor = #colorLiteral(red: 0.9176470588, green: 0.2274509804, blue: 0.05098039216, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [deleteAction, cacheAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            return
        }
        
        if indexPath.row < PlaylistManager.shared.numberOfAssets() {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            currentlyPlayingItemIndex = indexPath.row
            
            let selectedCell = tableView.cellForRow(at: indexPath) as? PlaylistCell

            let item = PlaylistManager.shared.itemAtIndex(indexPath.row)
            playerView.setVideoInfo(videoDomain: item.pageSrc, videoTitle: item.pageTitle)
            mediaInfo.updateNowPlayingMediaArtwork(image: selectedCell?.thumbnailView.image)
            
            mediaInfo.loadMediaItem(item, index: indexPath.row, autoPlayEnabled: autoPlayEnabled) { [weak self] error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                
                switch error {
                case .error(let err):
                    log.error(err)
                    self.displayLoadingResourceError()
                    
                case .expired:
                    selectedCell?.detailLabel.text = Strings.PlayList.expiredLabelTitle
                    
                    let alert = UIAlertController(title: Strings.PlayList.expiredAlertTitle, message: Strings.PlayList.expiredAlertDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: { _ in
                        
                        if let url = URL(string: item.pageSrc) {
                            self.dismiss(animated: true, completion: nil)
                            (UIApplication.shared.delegate as? AppDelegate)?.browserViewController.openURLInNewTab(url, isPrivileged: false)
                        }
                    }))
                    alert.addAction(UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                case .none:
                    log.debug("Playing Live Video: \(self.playerView.player.currentItem?.duration.isIndefinite ?? false)")
                    
                    if let selectedCell = selectedCell {
                        self.loadThumbnail(item: item, cell: selectedCell)
                    }
                    Preferences.Playlist.lastPlayedItemUrl.value = item.pageSrc
                }
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

// MARK: - Reordering of cells

extension ListController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        PlaylistManager.shared.reorderItems(from: sourceIndexPath, to: destinationIndexPath)
        PlaylistManager.shared.reloadData()
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = PlaylistManager.shared.itemAtIndex(indexPath.row)
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = item
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        
        var dropProposal = UITableViewDropProposal(operation: .cancel)
        guard session.items.count == 1 else { return dropProposal }
        
        if tableView.hasActiveDrag {
            dropProposal = UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return dropProposal
    }
        
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let sourceIndexPath = coordinator.items.first?.sourceIndexPath else { return }
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        if coordinator.proposal.operation == .move {
            guard let item = coordinator.items.first else { return }
            _ = coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell else { return nil }
        
        let preview = UIDragPreviewParameters()
        preview.visiblePath = UIBezierPath(roundedRect: cell.contentView.frame, cornerRadius: 12.0)
        preview.backgroundColor = self.slightlyLighterColour(colour: BraveUX.popoverDarkBackground)
        return preview
    }

    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell else { return nil }
        
        let preview = UIDragPreviewParameters()
        preview.visiblePath = UIBezierPath(roundedRect: cell.contentView.frame, cornerRadius: 12.0)
        preview.backgroundColor = self.slightlyLighterColour(colour: BraveUX.popoverDarkBackground)
        return preview
    }
    
    func tableView(_ tableView: UITableView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }
    
    private func slightlyLighterColour(colour: UIColor) -> UIColor {
        let desaturation: CGFloat = 0.5
        var h: CGFloat = 0, s: CGFloat = 0
        var b: CGFloat = 0, a: CGFloat = 0

        guard colour.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {return colour}

        return UIColor(hue: h,
                       saturation: max(s - desaturation, 0.0),
                       brightness: b,
                       alpha: a)
    }
}

extension ListController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !tableView.isEditing
    }
}

// MARK: VideoViewDelegate

extension ListController: VideoViewDelegate {
    func onPreviousTrack() {
        if currentlyPlayingItemIndex <= 0 {
            return
        }
        
        let index = currentlyPlayingItemIndex - 1
        if index < PlaylistManager.shared.numberOfAssets() {
            let item = PlaylistManager.shared.itemAtIndex(index)
            playerView.setVideoInfo(videoDomain: item.pageSrc, videoTitle: item.pageTitle)
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
        let isAtEnd = currentlyPlayingItemIndex >= PlaylistManager.shared.numberOfAssets() - 1
        var index = currentlyPlayingItemIndex
        
        switch playerView.repeatState {
        case .none:
            if isAtEnd {
                return
            }
            index += 1
        case .repeatOne:
            playerView.seek(to: 0.0)
            playerView.play()
            return
        case .repeatAll:
            index = isAtEnd ? 0 : index + 1
        }
        
        if index >= 0 {
            let item = PlaylistManager.shared.itemAtIndex(index)
            playerView.setVideoInfo(videoDomain: item.pageSrc, videoTitle: item.pageTitle)
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
        if !UIDevice.isIpad || splitViewController?.isCollapsed == true {
            navigationController?.setNavigationBarHidden(true, animated: true)
            tableView.isHidden = true
            playerView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            (splitViewController?.parent as? PlaylistViewController)?.onFullscreen()
        }
    }
    
    func onExitFullScreen() {
        if UIDevice.isIpad && splitViewController?.isCollapsed == false {
            (splitViewController?.parent as? PlaylistViewController)?.onExitFullscreen()
        } else if UIDevice.current.orientation.isPortrait {
            navigationController?.setNavigationBarHidden(false, animated: true)
            tableView.isHidden = false
            updateLayoutForMode(.iPhoneLayout)
        } else {
            playerView.setFullscreenButtonHidden(true)
            updateLayoutForMode(.iPhoneLayout)
        }
    }
}

// MARK: AVPlayerViewControllerDelegate && AVPictureInPictureControllerDelegate

extension ListController: AVPlayerViewControllerDelegate, AVPictureInPictureControllerDelegate {

    // MARK: - AVPlayerViewControllerDelegate
    
    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
        return true
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        playerView.detachLayer()
        playerController = playerViewController
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        playerView.attachLayer()
        playerController = nil
    }
    
    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        playerView.detachLayer()
        
        (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController = splitViewController?.parent
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        DispatchQueue.main.async {
            self.playerView.detachLayer()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            playerView.attachLayer()
            delegate.playlistRestorationController = nil
            playerController = nil
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
           let restorationController = delegate.playlistRestorationController {
            restorationController.modalPresentationStyle = .fullScreen
            playerView.attachLayer()
            if view.window == nil {
                delegate.browserViewController.present(restorationController, animated: true) {
                    self.playerView.player.play()
                    delegate.playlistRestorationController = nil
                }
            } else {
                self.playerView.player.play()
                delegate.playlistRestorationController = nil
            }
        }
        
        playerController = nil
        completionHandler(true)
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        
        (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController = splitViewController?.parent
        
        if UIDevice.isIpad {
            splitViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if UIDevice.isPhone {
            DispatchQueue.main.async {
                // self.playerView.detachLayer()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            if UIDevice.isIpad {
                playerView.attachLayer()
            }
            delegate.playlistRestorationController = nil
        }
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        
        let alert = UIAlertController(title: Strings.PlayList.sorryAlertTitle, message: Strings.PlayList.pictureInPictureErrorTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
           let restorationController = delegate.playlistRestorationController {
            restorationController.modalPresentationStyle = .fullScreen
            if view.window == nil {
                delegate.browserViewController.present(restorationController, animated: true) {
                    delegate.playlistRestorationController = nil
                }
            } else {
                delegate.playlistRestorationController = nil
            }
        }
        
        completionHandler(true)
    }
}

extension ListController: PlaylistManagerDelegate {
    func onDownloadProgressUpdate(id: String, percentComplete: Double) {
        if let index = PlaylistManager.shared.index(of: id),
           let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PlaylistCell {
            
            let cacheState = PlaylistManager.shared.state(for: id)
            switch cacheState {
            case .inProgress:
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = "\(getRelativeDateFormat(date: item.dateAdded)) - \(Strings.PlayList.dowloadingPercentageLabelTitle) \(Int(percentComplete))%"
            case .downloaded:
                let item = PlaylistManager.shared.itemAtIndex(index)
                if let itemSize = PlaylistManager.shared.sizeOfDownloadedItem(for: item.pageSrc) {
                    cell.detailLabel.text = "\(getRelativeDateFormat(date: item.dateAdded)) - \(itemSize)"
                } else {
                    cell.detailLabel.text = "\(getRelativeDateFormat(date: item.dateAdded)) - \(Strings.PlayList.dowloadedLabelTitle)"
                }
            case .invalid:
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = getRelativeDateFormat(date: item.dateAdded)
            }
        }
    }
    
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String, error: Error?) {
        if let index = PlaylistManager.shared.index(of: id),
        let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PlaylistCell {
            
            if let error = error {
                log.error("Error downloading playlist item: \(error)")
                
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = getRelativeDateFormat(date: item.dateAdded)
                
                let alert = UIAlertController(title: Strings.PlayList.playlistDownloadErrorTitle, message: Strings.PlayList.playlistDownloadErrorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                switch state {
                case .inProgress:
                    let item = PlaylistManager.shared.itemAtIndex(index)
                    cell.detailLabel.text = "\(getRelativeDateFormat(date: item.dateAdded)) - \(Strings.PlayList.dowloadingPercentageLabelTitle)"
                case .downloaded:
                    let item = PlaylistManager.shared.itemAtIndex(index)
                    if let itemSize = PlaylistManager.shared.sizeOfDownloadedItem(for: item.pageSrc) {
                        cell.detailLabel.text = "\(getRelativeDateFormat(date: item.dateAdded)) - \(itemSize)"
                    } else {
                        cell.detailLabel.text = "\(getRelativeDateFormat(date: item.dateAdded)) - \(Strings.PlayList.dowloadedLabelTitle)"
                    }
                case .invalid:
                    let item = PlaylistManager.shared.itemAtIndex(index)
                    cell.detailLabel.text = getRelativeDateFormat(date: item.dateAdded)
                }
            }
        }
    }
    
    func controllerDidChange(_ anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if tableView.hasActiveDrag || tableView.hasActiveDrop { return }
        
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
        if tableView.hasActiveDrag || tableView.hasActiveDrop { return }
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent() {
        if tableView.hasActiveDrag || tableView.hasActiveDrop { return }
        tableView.beginUpdates()
    }
}

extension ListController {
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

private class DetailController: UIViewController, UIGestureRecognizerDelegate {
    
    private weak var playerView: VideoView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        layoutBarButtons()
        addGestureRecognizers()
    }
    
    // MARK: Private
    
    private func setup() {
        view.backgroundColor = .black
        
        title = Strings.PlayList.playListMediaPlayerTitle
        
        navigationController?.do {
            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.backgroundColor = BraveUX.popoverDarkBackground
                
                $0.navigationBar.standardAppearance = appearance
                $0.navigationBar.barTintColor = BraveUX.popoverDarkBackground
                $0.navigationBar.tintColor = .white
            } else {
                $0.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
                $0.navigationBar.backgroundColor = .clear
                $0.navigationBar.barTintColor = BraveUX.popoverDarkBackground
                $0.navigationBar.tintColor = .white
            }
        }
    }
    
    private func layoutBarButtons() {
        let exitBarButton =  UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onExit(_:)))
        let sideListBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "playlist_split_navigation"), style: .done, target: self, action: #selector(onDisplayModeChange))
        
        navigationItem.rightBarButtonItem =
            PlayListSide(rawValue: Preferences.Playlist.listViewSide.value) == .left ? exitBarButton : sideListBarButton
        navigationItem.leftBarButtonItem =
            PlayListSide(rawValue: Preferences.Playlist.listViewSide.value) == .left ? sideListBarButton : exitBarButton
    }
    
    private func addGestureRecognizers() {
        let slideToRevealGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        slideToRevealGesture.direction = PlayListSide(rawValue: Preferences.Playlist.listViewSide.value) == .left ? .right : .left
        
        view.addGestureRecognizer(slideToRevealGesture)
    }
    
    private func updateSplitViewDisplayMode(to displayMode: UISplitViewController.DisplayMode) {
        UIView.animate(withDuration: 0.2) {
            self.splitViewController?.preferredDisplayMode = displayMode
        }
    }
    
    // MARK: Actions
    
    func onFullScreen() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        splitViewController?.preferredDisplayMode = .secondaryOnly
    }
    
    func onExitFullScreen() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        splitViewController?.preferredDisplayMode = .primaryOverlay
    }
        
    @objc
    private func onExit(_ button: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    func handleGesture(gesture: UISwipeGestureRecognizer) {
        guard gesture.direction == .right,
              let playerView = playerView,
              !playerView.checkInsideTrackBar(point: gesture.location(in: view)) else {
            return
        }
        
       onDisplayModeChange()
    }
    
    @objc
    private func onDisplayModeChange() {
        updateSplitViewDisplayMode(
            to: splitViewController?.displayMode == .primaryOverlay ? .secondaryOnly : .primaryOverlay)
    }
    
    public func setVideoPlayer(_ videoPlayer: VideoView?) {
        if playerView?.superview == view {
            playerView?.removeFromSuperview()
        }
        
        playerView = videoPlayer
    }
    
    public func updateLayoutForMode(_ mode: DisplayMode) {
        guard let playerView = playerView else { return }
        
        if mode == .iPadLayout {
            view.addSubview(playerView)
            playerView.snp.makeConstraints {
                $0.bottom.left.right.equalTo(view)
                $0.top.equalTo(view.safeAreaLayoutGuide)
            }
        } else {
            if playerView.superview == view {
                playerView.removeFromSuperview()
            }
        }
    }
}
