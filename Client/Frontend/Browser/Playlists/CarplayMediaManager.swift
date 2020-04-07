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
    private var player: AVPlayer
    private var playableItems: [PlaylistInfo]
    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration().then {
        $0.processPool = WKProcessPool()
        
        let script: WKUserScript? = {
            guard let path = Bundle.main.path(forResource: "Playlist", ofType: "js"), let source = try? String(contentsOfFile: path) else {
                return nil
            }
            
            var alteredSource = source
            let token = UserScriptManager.securityToken.uuidString.replacingOccurrences(of: "-", with: "", options: .literal)
            alteredSource = alteredSource.replacingOccurrences(of: "$<videosSupportFullscreen>", with: "VSF\(token)", options: .literal)
            
            return WKUserScript(source: alteredSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        }()
        
        if let script = script {
            $0.userContentController.addUserScript(script)
        }
    })
    
    public static let shared = CarplayMediaManager()
    
    private override init() {
        contentManager = MPPlayableContentManager.shared()
        playableItems = []
        player = AVPlayer()
        
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
//            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
//            UIApplication.shared.beginReceivingRemoteControlEvents()
//        } catch {
//            print(error)
//        }

        super.init()
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
            self?.player.pause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
            self?.player.play()
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

        webView.navigationDelegate = self
        webView.configuration.userContentController.add(self, name: "playlistManager")
        UIApplication.shared.keyWindow?.insertSubview(webView, at: 0)
        contentManager.delegate = self
        contentManager.dataSource = self
        self.updatePlayableItems()
        
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
    
    public func updatePlayableItems() {
        playableItems = Playlist.shared.getItems()
        contentManager.reloadData()
    }
    
    private var completion: ((Error?) -> Void)?
    private var currentStation: PlaylistInfo?
}

extension CarplayMediaManager: MPPlayableContentDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let completion = completion, let station = currentStation else {
            return
        }
        
        do {
            guard let item = try PlaylistInfo.from(message: message) else { return }
            if !item.mediaSource.isEmpty {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                    MPNowPlayingInfoPropertyMediaType: "Audio",
                    MPMediaItemPropertyTitle: item.title,
                    MPMediaItemPropertyArtist: item.mediaSource,
                    MPNowPlayingInfoPropertyIsLiveStream: true,
                    MPNowPlayingInfoPropertyAssetURL: URL(string: item.mediaSource)!
                ]
                
                if #available(iOS 13.0, *) {
                    MPNowPlayingInfoCenter.default().playbackState = .playing
                }
                
                self.player.replaceCurrentItem(with: AVPlayerItem(url: URL(string: item.mediaSource)!))
                self.player.play()
                completion(nil)
            }
        } catch {
            print(error)
        }
        
        DispatchQueue.main.async {
            self.webView.loadHTMLString("<html><body>PlayList</body></html>", baseURL: nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
    func playableContentManager(_ contentManager: MPPlayableContentManager, initiatePlaybackOfContentItemAt indexPath: IndexPath, completionHandler: @escaping (Error?) -> Void) {
        
        DispatchQueue.main.async {
            self.currentStation = nil
            self.completion = nil
            
            if indexPath.count == 2 {
                let station = self.playableItems[indexPath[1]]
                self.currentStation = station
                self.completion = completionHandler
                
                var request = URLRequest(url: URL(string: station.mediaSource)!)
                request.httpMethod = "GET"
                self.webView.load(request)
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
        return playableItems.count
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
        
        if indexPath.count == 2, indexPath.item < playableItems.count {
            // Stations section
            let station = playableItems[indexPath.item]
            let item = MPContentItem(identifier: "\(station.title)")
            item.title = station.title
            item.subtitle = station.mediaSource
            item.isPlayable = true
            item.isStreamingContent = true
            
            // Get the station image from http or local
            if station.mediaSource.contains("http") {
                //Download the image..
                let image: UIImage? = thumbnailForURL(station.mediaSource) ?? #imageLiteral(resourceName: "browser_lock_popup")
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
