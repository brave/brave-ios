// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import MediaPlayer
import AVKit
import AVFoundation
import WebKit

class CarplayMediaManager: NSObject {
    private var contentManager: MPPlayableContentManager
    private var playlistItems = [PlaylistInfo]()
    private var cacheLoader = PlaylistCacheLoader()
    private var webLoader = PlaylistWebLoader(handler: { _ in })
    private var currentStation: PlaylistInfo?
    public let playerView = VideoView()
    
    public static let shared = CarplayMediaManager()
    
    private override init() {
        contentManager = MPPlayableContentManager.shared()
        playlistItems = []

        super.init()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print(error)
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
            self?.playerView.pause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
            self?.playerView.play()
            return .success
        }
        
        MPRemoteCommandCenter.shared().stopCommand.addTarget { _ in
            return .success
        }
        
        MPRemoteCommandCenter.shared().changeRepeatModeCommand.addTarget { _ in
            return .success
        }
        
        MPRemoteCommandCenter.shared().changeShuffleModeCommand.addTarget { _ in
            return .success
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { _ in
            return .success
        }
        
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { _ in
            return .success
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPNowPlayingInfoPropertyMediaType: "Audio",
            MPMediaItemPropertyTitle: "None",
            MPMediaItemPropertyArtist: "Play"
        ]

        playerView.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
        contentManager.delegate = self
        contentManager.dataSource = self
        self.updateItems()
        
        DispatchQueue.main.async {
            self.contentManager.beginUpdates()
            self.contentManager.endUpdates()
            
            self.contentManager.reloadData()
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPNowPlayingInfoPropertyMediaType: "Audio",
                MPMediaItemPropertyTitle: "None",
                MPMediaItemPropertyArtist: "Play"
            ]
        }
    }
    
    public func updateItems() {
        playlistItems = Playlist.shared.getItems()
        contentManager.reloadData()
    }
    
    private var completion: ((Error?) -> Void)?
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            //completion?(player.status == .readyToPlay ? "Error attempting to play media" : nil)
            completion?(nil)
            completion = nil
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
            
            if let station = self.currentStation {
                contentManager.nowPlayingIdentifiers = [station.name]
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                    MPNowPlayingInfoPropertyMediaType: "Audio",
                    MPMediaItemPropertyTitle: station.name,
                    MPMediaItemPropertyArtist: station.pageSrc
                ]
            }
        }
    }
}

extension CarplayMediaManager: MPPlayableContentDelegate {
    
    private func displayLoadingResourceError() {
        let alert = UIAlertController(title: "Sorry", message: "There was a problem loading the resource!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        //self.present(alert, animated: true, completion: nil)
    }
    
    func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        
        DispatchQueue.main.async {
            self.currentStation = nil
            
            if indexPath.count == 2 {
                let station = self.playlistItems[indexPath[1]]
                self.currentStation = station
                
                let item = self.playlistItems[indexPath.row]
                let cache = Playlist.shared.getCache(item: item)
                if cache.isEmpty {
                    if let url = URL(string: item.src) {
                        self.playerView.load(url: url, resourceDelegate: nil)
                    } else {
                        self.webLoader = PlaylistWebLoader(handler: { [weak self] item in
                            guard let self = self else { return }
                            if let item = item, let url = URL(string: item.src) {
                                self.playerView.load(url: url, resourceDelegate: nil)
                            } else {
                                self.displayLoadingResourceError()
                            }
                        })
                        
                        if let url = URL(string: item.pageSrc) {
                            self.webLoader.load(url: url)
                        } else {
                            self.displayLoadingResourceError()
                        }
                    }
                } else {
                    self.cacheLoader = PlaylistCacheLoader(cacheData: cache)
                    let url = URL(string: "brave-media-ios://local-media-resource?time=\(Date().timeIntervalSince1970)")!
                    self.playerView.load(url: url, resourceDelegate: self.cacheLoader)
                }
            } else {
                completionHandler(nil)
            }
            
            //Workaround to see carplay NowPlaying on the simulator
            #if targetEnvironment(simulator)
            UIApplication.shared.endReceivingRemoteControlEvents()
            UIApplication.shared.beginReceivingRemoteControlEvents()
            #endif
        }
    }
    
    func beginLoadingChildItems(at indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        
        //used for pagination..
        DispatchQueue.main.async {
//            if indexPath.count == 2 {
//                let station = self.playableItems[indexPath[1]]
//                self.player.replaceCurrentItem(with: AVPlayerItem(url: URL(string: station.src)!))
//            }
            completionHandler(nil)
        }
    }
}

extension CarplayMediaManager: MPPlayableContentDataSource {
    
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        if indexPath.indices.count == 0 {
            return 1  //1 Tab.
        }
        return playlistItems.count
    }
    
    func childItemsDisplayPlaybackProgress(at indexPath: IndexPath) -> Bool {
        return true
    }
    
    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        if indexPath.count == 1 {
            // Tab section
            let item = MPContentItem(identifier: "BravePlaylist")
            item.title = "Brave Playlist"
            item.isContainer = true
            item.isPlayable = false
            
            let tabImage = #imageLiteral(resourceName: "browser_lock_popup")
            item.artwork = MPMediaItemArtwork(boundsSize: tabImage.size, requestHandler: { _ -> UIImage in
                return tabImage
            })
            return item
        }
        
        if indexPath.count == 2, indexPath.item < playlistItems.count {
            // Stations section
            let station = playlistItems[indexPath.item]
            let item = MPContentItem(identifier: "\(station.name)")
            item.title = station.pageTitle
            item.subtitle = station.pageSrc
            item.isPlayable = true
            item.isStreamingContent = true
            
            // Get the station image from http or local
            if station.src.contains("http") {
                //Download the image..
                let image: UIImage? = thumbnailForURL(station.src) ?? #imageLiteral(resourceName: "browser_lock_popup")
                DispatchQueue.main.async {
                    guard let image = image else { return }
                    item.artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ -> UIImage in
                        return image
                    })
                }
            } else {
                if let image = UIImage(named: "Something") {
                    item.artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ -> UIImage in
                        return image
                    })
                }
            }
            return item
        }
        
        return nil
    }
    
    private func thumbnailForURL(_ url: String) -> UIImage? {
        let sourceURL = URL(string: url)
        let asset = AVAsset(url: sourceURL!)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let time = CMTimeMakeWithSeconds(2, preferredTimescale: 1)
        guard let imageRef = try? imageGenerator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }
        return UIImage(cgImage: imageRef)
    }
}
