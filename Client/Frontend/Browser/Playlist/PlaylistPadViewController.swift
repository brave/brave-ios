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
    func updateNowPlayingMediaInfo(_ info: PlaylistInfo?)
    func updateNowPlayingMediaArtwork(image: UIImage?)
    func setControlsEnabled(_ enabled: Bool)
    func updatePlayerControlsState()
    func loadMediaItem(_ item: PlaylistInfo, index: Int, completion: @escaping (PlaylistMediaInfo.MediaPlaybackError) -> Void)
    func changeNavigationTitle(_ navigationTitle: String)
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
            $0.viewControllers = [SettingsNavigationController(rootViewController: listController),
                                  SettingsNavigationController(rootViewController: detailController)]
        }
        
        addChild(splitController)
        view.addSubview(splitController.view)
        
        splitController.do {
            $0.didMove(toParent: self)
            $0.view.translatesAutoresizingMaskIntoConstraints = false
            $0.view.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            $0.primaryEdge = PlayListSide(rawValue: Preferences.Playlist.listViewSide.value) == .left ? .leading : .trailing
            $0.presentsWithGesture = false
            $0.preferredPrimaryColumnWidthFraction = 1.0 / 3.0
        }
        
        updateLayoutForOrientationChange()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateLayoutForOrientationChange()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func updateLayoutForOrientationChange() {
        if UIDevice.current.orientation.isLandscape {
            splitController.preferredDisplayMode = .secondaryOnly
        } else {
            splitController.preferredDisplayMode = .primaryOverlay
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
        
        view.backgroundColor = .clear
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
        
        //Fixes a duration bug where sometimes the duration is NOT fetched!
        //So when we fetch the thumbnail, the duration will be updated (if possible)
        cell.loadThumbnail(item: item) { [weak self] newTrackDuration in
            guard let newTrackDuration = newTrackDuration else { return }
            
            if newTrackDuration > 0.0 && item.duration <= 0.0 {
                cell.detailLabel.text = self?.formatter.string(from: newTrackDuration) ?? "0:00"
                
                let newItem = PlaylistInfo(name: item.name,
                                           src: item.src,
                                           pageSrc: item.pageSrc,
                                           pageTitle: item.pageTitle,
                                           mimeType: item.mimeType,
                                           duration: Float(newTrackDuration),
                                           detected: item.detected)
                Playlist.shared.updateItem(mediaSrc: item.src, item: newItem, completion: {})
            }
        }
        
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
        
        let cacheAction = UIContextualAction(style: .normal, title: nil, handler: { [weak self] (action, view, completionHandler) in
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
        
        let deleteAction = UIContextualAction(style: .normal, title: nil, handler: { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
            let alert = UIAlertController(
                title: Strings.PlayList.removePlaylistVideoAlertTitle, message: Strings.PlayList.removePlaylistVideoAlertMessage, preferredStyle: style)
            
            alert.addAction(UIAlertAction(title: Strings.delete, style: .default, handler: { _ in
                PlaylistManager.shared.delete(item: currentItem)

                if self.detailControllerDelegate?.getCurrentItemIndex() == indexPath.row {
                    self.detailControllerDelegate?.setCurrentItemIndex(-1)
                    self.detailControllerDelegate?.updateNowPlayingMediaInfo(nil)
                    self.detailControllerDelegate?.updateNowPlayingMediaArtwork(image: nil)
                    
                    self.activityIndicator.stopAnimating()
                    self.detailControllerDelegate?.stop()
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
            detailControllerDelegate?.setCurrentItemIndex(indexPath.row)
            
            let selectedCell = tableView.cellForRow(at: indexPath) as? PlaylistCell

            let item = PlaylistManager.shared.itemAtIndex(indexPath.row)
            infoLabel.text = item.name
            
            detailControllerDelegate?.updateNowPlayingMediaArtwork(image: selectedCell?.thumbnailImage)
            detailControllerDelegate?.changeNavigationTitle(item.name)
            
            detailControllerDelegate?.loadMediaItem(item, index: indexPath.row) { [weak self] error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                
                switch error {
                case .error(let err):
                    log.error(err)
                    self.detailControllerDelegate?.displayLoadingResourceError()
                    
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
                    selectedCell?.loadThumbnail(item: item)
                }
            }
        }
    }
}

// MARK: - Reordering of cells

extension PlaylistPadListController: UITableViewDragDelegate, UITableViewDropDelegate {
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

extension PlaylistPadListController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !tableView.isEditing
    }
}

extension PlaylistPadListController: PlaylistManagerDelegate {
    func onDownloadProgressUpdate(id: String, percentComplete: Double) {
        if let index = PlaylistManager.shared.index(of: id),
           let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? PlaylistCell {
            
            let cacheState = PlaylistManager.shared.state(for: id)
            if cacheState == .inProgress {
                cell.detailLabel.text = "\(Strings.PlayList.dowloadingPercentageLabelTitle) \(Int(percentComplete))%"
            } else if cacheState == .downloaded {
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = "\(formatter.string(from: TimeInterval(item.duration)) ?? "0:00") - \(Strings.PlayList.dowloadedLabelTitle)"
            } else {
                let item = PlaylistManager.shared.itemAtIndex(index)
                cell.detailLabel.text = formatter.string(from: TimeInterval(item.duration)) ?? "0:00"
            }
        }
    }
    
    func onDownloadStateChanged(id: String, state: PlaylistDownloadManager.DownloadState, displayName: String) {
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

// MARK: - PlaylistPadDetailController

private class PlaylistPadDetailController: UIViewController, UIGestureRecognizerDelegate {
    
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

        setup()
        layoutBarButtons()
        addGestureRecognizers()
    }
    
    // MARK: Private
    
    private func setup() {
        view.backgroundColor = .black
        
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
        
        playerView.delegate = self

        view.addSubview(playerView)
        playerView.snp.makeConstraints {
            $0.bottom.left.right.equalTo(view)
            $0.top.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func layoutBarButtons() {
        let exitBarButton =  UIBarButtonItem(image: #imageLiteral(resourceName: "playlist_exit"), style: .done, target: self, action: #selector(onExit(_:)))
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
        
    @objc
    private func onExit(_ button: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func handleGesture(gesture: UISwipeGestureRecognizer) {
        guard gesture.direction == .right,
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
            title = item.name
            
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
            title = item.name
            
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
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func onExitFullScreen() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: AVPlayerViewControllerDelegate

extension PlaylistPadDetailController: AVPlayerViewControllerDelegate, AVPictureInPictureControllerDelegate {

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
        
        (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController = delegate
    }
    
    func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        DispatchQueue.main.async {
            self.playerView.detachLayer()
            self.delegate?.dismiss(animated: true, completion: nil)
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
           let playlistPadController = delegate.playlistRestorationController {
            playerView.attachLayer()
            delegate.browserViewController.present(playlistPadController, animated: true) {
                self.playerView.player.play()
            }
            delegate.playlistRestorationController = nil
        }
        
        playerController = nil
        completionHandler(true)
    }
    
    // MARK: - AVPictureInPictureControllerDelegate
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        
        (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController = delegate
        delegate?.dismiss(animated: true, completion: nil)
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            playerView.attachLayer()
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
    
    func updateNowPlayingMediaInfo(_ info: PlaylistInfo?) {
        mediaInfo.nowPlayingInfo = info
    }
    
    func updateNowPlayingMediaArtwork(image: UIImage?) {
        mediaInfo.updateNowPlayingMediaArtwork(image: image)
    }
    
    func setControlsEnabled(_ enabled: Bool) {
        playerView.setControlsEnabled(enabled)
    }
    
    func updatePlayerControlsState() {
        playerView.setControlsEnabled(playerView.player.currentItem != nil)
    }
    
    func loadMediaItem(_ item: PlaylistInfo, index: Int, completion: @escaping (PlaylistMediaInfo.MediaPlaybackError) -> Void) {
        playerView.setVideoInfo(videoDomain: item.pageSrc, videoTitle: item.pageTitle)
        mediaInfo.loadMediaItem(item, index: index, completion: completion)
    }
    
    func changeNavigationTitle(_ navigationTitle: String) {
        title = navigationTitle
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
