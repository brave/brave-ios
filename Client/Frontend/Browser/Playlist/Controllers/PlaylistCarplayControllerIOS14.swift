// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Combine
import CarPlay
import MediaPlayer
import Data
import BraveShared
import Shared

private let log = Logger.browserLogger

@available(iOS 14, *)
class PlaylistCarplayControllerIOS14: NSObject {
    private let player: MediaPlayer
    private let mediaStreamer: PlaylistMediaStreamer
    private let interfaceController: CPInterfaceController
    private var playerStateObservers = Set<AnyCancellable>()
    private var assetStateObservers = Set<AnyCancellable>()
    private var assetLoadingStateObservers = Set<AnyCancellable>()
    private var playlistObservers = Set<AnyCancellable>()
    private var playlistItemIds = [String]()
    private weak var browser: BrowserViewController?
    
    init(browser: BrowserViewController?, player: MediaPlayer, interfaceController: CPInterfaceController) {
        self.browser = browser
        self.player = player
        self.interfaceController = interfaceController
        self.mediaStreamer = PlaylistMediaStreamer(playerView: browser?.view ?? UIView())
        super.init()
        
        interfaceController.delegate = self
        
        observePlayerStates()
        observePlaylistStates()
        PlaylistManager.shared.reloadData()
        
        playlistItemIds = PlaylistManager.shared.allItems.map { $0.pageSrc }
        self.reloadData()
        
        DispatchQueue.main.async {
            // Workaround to see carplay NowPlaying on the simulator
            #if targetEnvironment(simulator)
            UIApplication.shared.endReceivingRemoteControlEvents()
            UIApplication.shared.beginReceivingRemoteControlEvents()
            #endif
        }
    }
    
    func observePlayerStates() {
//        CPNowPlayingTemplate.shared.updateNowPlayingButtons
        
        player.publisher(for: .play).sink { event in
            MPNowPlayingInfoCenter.default().playbackState = .playing
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = event.mediaPlayer.rate
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }.store(in: &playerStateObservers)
        
        player.publisher(for: .pause).sink { _ in
            MPNowPlayingInfoCenter.default().playbackState = .paused
        }.store(in: &playerStateObservers)
        
        player.publisher(for: .stop).sink { _ in
            MPNowPlayingInfoCenter.default().playbackState = .stopped
        }.store(in: &playerStateObservers)
        
        player.publisher(for: .changePlaybackRate).sink { event in
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = event.mediaPlayer.rate
        }.store(in: &playerStateObservers)
        
        player.publisher(for: .previousTrack).sink { [weak self] _ in
            self?.onPreviousTrack(isUserInitiated: true)
        }.store(in: &playerStateObservers)
        
        player.publisher(for: .nextTrack).sink { [weak self] _ in
            self?.onNextTrack(isUserInitiated: true)
        }.store(in: &playerStateObservers)
        
        player.publisher(for: .finishedPlaying).sink { [weak self] event in
            event.mediaPlayer.pause()
            event.mediaPlayer.seek(to: .zero)
            
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
            nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackProgress] = 0.0
            nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            self?.onNextTrack(isUserInitiated: false)
        }.store(in: &playerStateObservers)
    }
    
    func observePlaylistStates() {
        let reloadData = { [weak self] in
            guard let self = self else { return }
            
            self.playlistItemIds = PlaylistManager.shared.allItems.map { $0.pageSrc }
            self.reloadData()
        }
        
        PlaylistManager.shared.contentWillChange
        .receive(on: RunLoop.main)
        .sink { _ in
            reloadData()
        }.store(in: &playlistObservers)
        
        PlaylistManager.shared.contentDidChange
        .receive(on: RunLoop.main)
        .sink { _ in
            reloadData()
        }.store(in: &playlistObservers)
        
        PlaylistManager.shared.objectDidChange
        .receive(on: RunLoop.main)
        .sink { _ in
            reloadData()
        }.store(in: &playlistObservers)
        
        PlaylistManager.shared.downloadStateChanged
        .receive(on: RunLoop.main)
        .sink { _ in
            reloadData()
        }.store(in: &playlistObservers)
    }
    
    private func reloadData() {
        playlistItemIds = PlaylistManager.shared.allItems.map { $0.pageSrc }
        
        // PLAYLIST TEMPLATE
        let playlistTemplate = generatePlaylistListTemplate()
        
        // SETTINGS TEMPLATE
        let settingsTemplate = generateSettingsTemplate()
        
        // ALL TEMPLATES
        let tabTemplates: [CPTemplate] = [
            playlistTemplate,
            settingsTemplate
        ]
        
        self.interfaceController.delegate = self
        self.interfaceController.setRootTemplate(CPTabBarTemplate(templates: tabTemplates),
                                                 animated: true,
                                                 completion: { success, error in
            if !success, let error = error {
                // Can also use CPAlertTemplate, but it doesn't have a "Message" parameter.
                let alert = CPActionSheetTemplate(title: Strings.PlayList.sorryAlertTitle,
                                                  message: error.localizedDescription,
                                                  actions: [
                    CPAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: { _ in
                        // Handler cannot be nil.. so..
                    })
                ])
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.interfaceController.presentTemplate(alert, animated: true, completion: nil)
                }
            }
         })
    }
    
    private func generatePlaylistListTemplate() -> CPTemplate {
        // Fetch all Playlist Items
        let listItems = playlistItemIds.compactMap { itemId -> CPListItem? in
            guard let itemIndex = PlaylistManager.shared.index(of: itemId),
                  let item = PlaylistManager.shared.itemAtIndex(itemIndex) else {
                return nil
            }
            
            let listItem = CPListItem(text: item.name, detailText: item.pageSrc)
            listItem.handler = { [unowned self, weak listItem] _, completion in
                self.initiatePlaybackOfItem(itemId: itemId) { error in
                    guard let listItem = listItem else {
                        completion()
                        return
                    }
                    
                    if let error = error {
                        log.error(error)
                        listItem.isPlaying = false
                    } else {
                        listItem.isPlaying = true
                    }
                    
                    let userInfo = listItem.userInfo as? [String: Any]
                    PlaylistMediaStreamer.setNowPlayingMediaArtwork(image: userInfo?["icon"] as? UIImage)
                    
                    completion()
                }
            }
            
            // Update the current playing status
            listItem.isPlaying = PlaylistCarplayManager.shared.currentlyPlayingItemIndex == itemIndex || PlaylistCarplayManager.shared.currentPlaylistItem?.src == item.src
            
            listItem.setImage(FaviconFetcher.defaultFaviconImage)
            var userInfo = [String: Any]()
            userInfo.merge(with: [
                "id": itemId,
                "thumbnailRenderer": self.loadThumbnail(for: item) { [weak listItem]
                    image in
                    guard let listItem = listItem else { return }
                    
                    // Store the thumbnail that was fetched
                    userInfo["icon"] = image
                    listItem.userInfo = userInfo
                    
                    if let image = image {
                        listItem.setImage(image.scale(toSize: CPListItem.maximumImageSize))
                    }
                    
                    if listItem.isPlaying {
                        PlaylistMediaStreamer.setNowPlayingMediaArtwork(image: image)
                    }
                    
                    // After completion, remove the renderer from the user info
                    // so that it can dealloc nicely and save us some memory.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        userInfo["thumbnailRenderer"] = nil
                        listItem.userInfo = userInfo
                    }
                } as Any
            ])
            listItem.userInfo = userInfo
            return listItem
        }
        
        // Template
        let playlistTemplate = CPListTemplate(
            title: "Playlist",
            sections: [CPListSection(items: listItems)]
        ).then {
            $0.tabImage = UIImage(systemName: "list.star")
        }
        return playlistTemplate
    }
    
    private func generateSettingsTemplate() -> CPTemplate {
        // Playback Options
        let restartPlaybackOption = CPListItem(text: "Restart Playback",
                                   detailText: "Decide whether or not selecting an already playing item will restart playback, or continue playing where last left off").then {
            $0.handler = { [unowned self] listItem, completion in
                let enableGridView = Preferences.Playlist.enableCarPlayRestartPlayback.value
                let title = enableGridView ? "Enabled. Tap to disable playback restarting." : "Disabled. Tap to enable playback restarting"
                let icon = enableGridView ? #imageLiteral(resourceName: "checkbox_on") : #imageLiteral(resourceName: "loginUnselected")
                let button = CPGridButton(titleVariants: [title], image: icon) { [unowned self] button in
                    Preferences.Playlist.enableCarPlayRestartPlayback.value = !enableGridView
                    self.interfaceController.popTemplate(animated: true, completion: nil)
                }
                
                self.interfaceController.pushTemplate(
                    CPGridTemplate(title: "Playback Options", gridButtons: [button]),
                    animated: true,
                    completion: nil
                )
                
                completion()
            }
        }
        
        // Sections
        let playbackSection = CPListSection(items: [restartPlaybackOption],
                                            header: "Playback Options",
                                            sectionIndexTitle: "Playback Options")
        
        // Template
        let settingsTemplate = CPListTemplate(title: "Settings",
                                              sections: [playbackSection]).then {
            $0.tabImage = UIImage(systemName: "gear")
        }
        return settingsTemplate
    }
}

@available(iOS 14, *)
extension PlaylistCarplayControllerIOS14: CPInterfaceControllerDelegate {
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        log.debug("Template \(aTemplate.classForCoder) will appear.")
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        log.debug("Template \(aTemplate.classForCoder) did appear.")
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        log.debug("Template \(aTemplate.classForCoder) will disappear.")
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        log.debug("Template \(aTemplate.classForCoder) did disappear.")
    }
}

@available(iOS 14, *)
extension PlaylistCarplayControllerIOS14 {
    
    func loadThumbnail(for mediaItem: PlaylistInfo, completion: @escaping (UIImage?) -> Void) -> PlaylistThumbnailRenderer? {
        guard let assetUrl = URL(string: mediaItem.src),
              let favIconUrl = URL(string: mediaItem.pageSrc) else {
            completion(nil)
            return nil
        }
        
        let thumbnailRenderer = PlaylistThumbnailRenderer()
        thumbnailRenderer.loadThumbnail(assetUrl: assetUrl,
                                        favIconUrl: favIconUrl,
                                        completion: { image in
                                            completion(image)
                                        })
        return thumbnailRenderer
    }
    
    func initiatePlaybackOfItem(itemId: String, completionHandler: @escaping (Error?) -> Void) {
        guard let index = PlaylistManager.shared.index(of: itemId),
              let item = PlaylistManager.shared.itemAtIndex(index) else {
            displayLoadingResourceError()
            completionHandler("Invalid Item")
            return
        }
        
        if !Preferences.Playlist.enableCarPlayRestartPlayback.value {
            // Item is already playing.
            // Show now-playing screen and don't restart playback.
            if PlaylistCarplayManager.shared.currentPlaylistItem?.pageSrc == itemId {
                completionHandler(nil)
                return
            }
        }
        
        self.playItem(item: item) { [weak self] error in
            PlaylistCarplayManager.shared.currentPlaylistItem = nil
            guard let self = self else {
                completionHandler(nil)
                return
            }
            
            switch error {
            case .other(let error):
                log.error(error)
                self.displayLoadingResourceError()
                completionHandler(error)
            case .expired:
                self.displayExpiredResourceError(item: item)
                completionHandler("Item Expired")
            case .none:
                PlaylistCarplayManager.shared.currentlyPlayingItemIndex = index
                PlaylistCarplayManager.shared.currentPlaylistItem = item
                completionHandler(nil)
            case .cancelled:
                log.debug("User Cancelled Playlist playback")
                completionHandler("User Cancelled")
            }
            
            // Workaround to see carplay NowPlaying on the simulator
            #if targetEnvironment(simulator)
            DispatchQueue.main.async {
                UIApplication.shared.endReceivingRemoteControlEvents()
                UIApplication.shared.beginReceivingRemoteControlEvents()
            }
            #endif
        }
    }
}

@available(iOS 14, *)
extension PlaylistCarplayControllerIOS14 {
    func onPreviousTrack(isUserInitiated: Bool) {
        if PlaylistCarplayManager.shared.currentlyPlayingItemIndex <= 0 {
            return
        }
        
        let index = PlaylistCarplayManager.shared.currentlyPlayingItemIndex - 1
        if index < PlaylistManager.shared.numberOfAssets,
           let item = PlaylistManager.shared.itemAtIndex(index) {
            PlaylistCarplayManager.shared.currentlyPlayingItemIndex = index
            playItem(item: item) { [weak self] error in
                PlaylistCarplayManager.shared.currentPlaylistItem = nil
                guard let self = self else { return }
                
                switch error {
                case .other(let err):
                    log.error(err)
                    self.displayLoadingResourceError()
                case .expired:
                    self.displayExpiredResourceError(item: item)
                case .none:
                    PlaylistCarplayManager.shared.currentlyPlayingItemIndex = index
                    PlaylistCarplayManager.shared.currentPlaylistItem = item
                    self.updateLastPlayedItem(item: item)
                case .cancelled:
                    log.debug("User Cancelled Playlist Playback")
                }
            }
        }
    }
    
    func onNextTrack(isUserInitiated: Bool) {
        let assetCount = PlaylistManager.shared.numberOfAssets
        let isAtEnd = PlaylistCarplayManager.shared.currentlyPlayingItemIndex >= assetCount - 1
        var index = PlaylistCarplayManager.shared.currentlyPlayingItemIndex

        switch player.repeatState {
        case .none:
            if isAtEnd {
                player.pictureInPictureController?.delegate = nil
                player.pictureInPictureController?.stopPictureInPicture()
                player.pause()

                PlaylistCarplayManager.shared.playlistController = nil
                return
            }
            index += 1
        case .repeatOne:
            player.seek(to: 0.0)
            player.play()
            return
        case .repeatAll:
            index = isAtEnd ? 0 : index + 1
        }

        if index >= 0,
           let item = PlaylistManager.shared.itemAtIndex(index) {
            self.playItem(item: item) { [weak self] error in
                PlaylistCarplayManager.shared.currentPlaylistItem = nil
                guard let self = self else { return }

                switch error {
                case .other(let err):
                    log.error(err)
                    self.displayLoadingResourceError()
                case .expired:
                    if isUserInitiated || self.player.repeatState == .repeatOne || assetCount <= 1 {
                        self.displayExpiredResourceError(item: item)
                    } else {
                        DispatchQueue.main.async {
                            PlaylistCarplayManager.shared.currentlyPlayingItemIndex = index
                            self.onNextTrack(isUserInitiated: isUserInitiated)
                        }
                    }
                case .none:
                    PlaylistCarplayManager.shared.currentlyPlayingItemIndex = index
                    PlaylistCarplayManager.shared.currentPlaylistItem = item
                    self.updateLastPlayedItem(item: item)
                case .cancelled:
                    log.debug("User Cancelled Playlist Playback")
                }
            }
        }
    }
    
    private func play() {
        player.play()
    }
    
    private func pause() {
        player.pause()
    }
    
    private func stop() {
        player.stop()
    }
    
    private func seekBackwards() {
        player.seekBackwards()
    }
    
    private func seekForwards() {
        player.seekForwards()
    }
    
    private func seek(to time: TimeInterval) {
        player.seek(to: time)
    }
    
    func seek(relativeOffset: Float) {
        if let currentItem = player.currentItem {
            let seekTime = CMTimeMakeWithSeconds(Float64(CGFloat(relativeOffset) * CGFloat(currentItem.asset.duration.value) / CGFloat(currentItem.asset.duration.timescale)), preferredTimescale: currentItem.currentTime().timescale)
            seek(to: seekTime.seconds)
        }
    }
    
    func load(url: URL, autoPlayEnabled: Bool) -> AnyPublisher<Void, Error> {
        load(asset: AVURLAsset(url: url), autoPlayEnabled: autoPlayEnabled)
    }
    
    func load(asset: AVURLAsset, autoPlayEnabled: Bool) -> AnyPublisher<Void, Error> {
        assetLoadingStateObservers.removeAll()
        player.stop()
        
        return Future { [weak self] resolver in
            guard let self = self else {
                resolver(.failure("User Cancelled Playback"))
                return
            }
            
            self.player.load(asset: asset)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { status in
                switch status {
                case .failure(let error):
                    resolver(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] isNewItem in
                guard let self = self else {
                    resolver(.failure("User Cancelled Playback"))
                    return
                }
                
                guard self.player.currentItem != nil else {
                    resolver(.failure("Couldn't load playlist item"))
                    return
                }
                
                // We are playing the same item again..
                if !isNewItem {
                    self.pause()
                    self.seek(relativeOffset: 0.0) // Restart playback
                    self.play()
                    resolver(.success(Void()))
                    return
                }
                
                // Track-bar
                if autoPlayEnabled {
                    self.play() // Play the new item
                    resolver(.success(Void()))
                }
            }).store(in: &self.assetLoadingStateObservers)
        }.eraseToAnyPublisher()
    }
    
    func playItem(item: PlaylistInfo, completion: ((PlaylistMediaStreamer.PlaybackError) -> Void)?) {
        assetLoadingStateObservers.removeAll()
        assetStateObservers.removeAll()

        // If the item is cached, load it from the cache and play it.
        let cacheState = PlaylistManager.shared.state(for: item.pageSrc)
        if cacheState != .invalid {
            if let index = PlaylistManager.shared.index(of: item.pageSrc),
               let asset = PlaylistManager.shared.assetAtIndex(index) {
                load(asset: asset, autoPlayEnabled: true)
                .handleEvents(receiveCancel: {
                    PlaylistMediaStreamer.clearNowPlayingInfo()
                    completion?(.cancelled)
                })
                .sink(receiveCompletion: { status in
                    switch status {
                    case .failure(let error):
                        PlaylistMediaStreamer.clearNowPlayingInfo()
                        completion?(.other(error))
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] _ in
                    guard let self = self else {
                        PlaylistMediaStreamer.clearNowPlayingInfo()
                        completion?(.cancelled)
                        return
                    }
                    
                    PlaylistMediaStreamer.setNowPlayingInfo(item, withPlayer: self.player)
                    completion?(.none)
                }).store(in: &assetLoadingStateObservers)
            } else {
                completion?(.expired)
            }
            return
        }
        
        // The item is not cached so we should attempt to stream it
        streamItem(item: item, completion: completion)
    }
    
    func streamItem(item: PlaylistInfo, completion: ((PlaylistMediaStreamer.PlaybackError) -> Void)?) {
        assetStateObservers.removeAll()
        
        mediaStreamer.loadMediaStreamingAsset(item)
        .handleEvents(receiveCancel: {
            PlaylistMediaStreamer.clearNowPlayingInfo()
            completion?(.cancelled)
        })
        .sink(receiveCompletion: { status in
            switch status {
            case .failure(let error):
                PlaylistMediaStreamer.clearNowPlayingInfo()
                completion?(error)
            case .finished:
                break
            }
        }, receiveValue: { [weak self] _ in
            guard let self = self else {
                PlaylistMediaStreamer.clearNowPlayingInfo()
                completion?(.cancelled)
                return
            }
            
            // Item can be streamed, so let's retrieve its URL from our DB
            guard let index = PlaylistManager.shared.index(of: item.pageSrc),
                  let item = PlaylistManager.shared.itemAtIndex(index) else {
                PlaylistMediaStreamer.clearNowPlayingInfo()
                completion?(.expired)
                return
            }
            
            // Attempt to play the stream
            if let url = URL(string: item.src) {
                self.load(url: url, autoPlayEnabled: true)
                .handleEvents(receiveCancel: {
                    PlaylistMediaStreamer.clearNowPlayingInfo()
                    completion?(.cancelled)
                })
                .sink(receiveCompletion: { status in
                    switch status {
                    case .failure(let error):
                        PlaylistMediaStreamer.clearNowPlayingInfo()
                        completion?(.other(error))
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] _ in
                    guard let self = self else {
                        PlaylistMediaStreamer.clearNowPlayingInfo()
                        completion?(.cancelled)
                        return
                    }
                    
                    PlaylistMediaStreamer.setNowPlayingInfo(item, withPlayer: self.player)
                    completion?(.none)
                }).store(in: &self.assetLoadingStateObservers)
                log.debug("Playing Live Video: \(self.player.isLiveMedia)")
            } else {
                PlaylistMediaStreamer.clearNowPlayingInfo()
                completion?(.expired)
            }
        }).store(in: &assetStateObservers)
    }
    
    func updateLastPlayedItem(item: PlaylistInfo) {
        Preferences.Playlist.lastPlayedItemUrl.value = item.pageSrc
        
        if let playTime = player.currentItem?.currentTime(),
           Preferences.Playlist.playbackLeftOff.value {
            Preferences.Playlist.lastPlayedItemTime.value = playTime.seconds
        } else {
            Preferences.Playlist.lastPlayedItemTime.value = 0.0
        }
    }
    
    func displayExpiredResourceError(item: PlaylistInfo?) {
        // CarPlay cannot "open" URLs so we display an alert with an okay button only.
        // Maybe in the future, check if the phone is open, if it is, display the alert there.
        // and the user can "open" the item in the webView/browser.
        let alert = CPActionSheetTemplate(title: Strings.PlayList.expiredAlertTitle,
                                          message: Strings.PlayList.expiredAlertDescription,
                                          actions: [
            CPAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: { _ in
                // Handler cannot be nil.. so..
            })
        ])
        
        interfaceController.presentTemplate(alert, animated: true, completion: nil)
    }
    
    func displayLoadingResourceError() {
        // Can also use CPAlertTemplate, but it doesn't have a "Message" parameter.
        let alert = CPActionSheetTemplate(title: Strings.PlayList.sorryAlertTitle,
                                          message: Strings.PlayList.loadResourcesErrorAlertDescription,
                                          actions: [
            CPAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: { _ in
                // Handler cannot be nil.. so..
            })
        ])
        
        interfaceController.presentTemplate(alert, animated: true, completion: nil)
    }
}
