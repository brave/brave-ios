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

protocol VideoViewDelegate: class {
    func onPreviousTrack()
    func onNextTrack()
    func onPictureInPicture(enabled: Bool)
    func onFullScreen()
    func onExitFullScreen()
}

public class VideoView: UIView, VideoTrackerBarDelegate {
    
    weak var delegate: VideoViewDelegate?
    
    public let player = AVPlayer(playerItem: nil).then {
        $0.seek(to: .zero)
        $0.actionAtItemEnd = .none
    }
    
    public let playerLayer = AVPlayerLayer().then {
        $0.videoGravity = .resizeAspect
        $0.needsDisplayOnBoundsChange = true
    }
    
    private var requestedPlaybackRate = 1.0
    
    private let particleView = PlaylistParticleEmitter().then {
        $0.isHidden = false
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }
    
    private let overlayView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
        $0.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.4024561216)
    }
    
    private let infoView = VideoPlayerInfoBar().then {
        $0.layer.cornerRadius = 18.0
        $0.layer.masksToBounds = true
    }
    
    private let controlsView = VideoPlayerControlsView().then {
        $0.layer.cornerRadius = 18.0
        $0.layer.masksToBounds = true
    }
    
    // State
    private let orientation: UIInterfaceOrientation = .portrait
    private var playObserver: Any?
    private var fadeAnimationWorkItem: DispatchWorkItem?
    
    public var isPlaying: Bool {
        // It is better NOT to keep tracking of isPlaying OR rate > 0.0
        // Instead we should use the timeControlStatus because PIP and Background play
        // via control-center will modify the timeControlStatus property
        // This will keep our UI consistent with what is on the lock-screen.
        // This will also allow us to properly determine play state in
        // PlaylistMediaInfo -> init -> MPRemoteCommandCenter.shared().playCommand
        return player.timeControlStatus == .playing
    }
    private var wasPlayingBeforeSeeking = false
    private(set) public var isSeeking = false
    private(set) public var isFullscreen = false
    private(set) public var isOverlayDisplayed = false
    private var notificationObservers = [NSObjectProtocol]()
    private var pictureInPictureObservers = [NSObjectProtocol]()
    private(set) public var pictureInPictureController: AVPictureInPictureController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            log.error(error)
        }

        // Setup
        self.backgroundColor = .black
        self.playerLayer.player = self.player

        infoView.pictureInPictureButton.addTarget(self, action: #selector(onPictureInPicture(_:)), for: .touchUpInside)
        infoView.fullscreenButton.addTarget(self, action: #selector(onFullscreen(_:)), for: .touchUpInside)
        infoView.exitButton.addTarget(self, action: #selector(onExitFullscreen(_:)), for: .touchUpInside)
        
        controlsView.playPauseButton.addTarget(self, action: #selector(onPlay(_:)), for: .touchUpInside)
        controlsView.castButton.addTarget(self, action: #selector(onCast(_:)), for: .touchUpInside)
        controlsView.playbackRateButton.addTarget(self, action: #selector(onPlaybackRateChanged(_:)), for: .touchUpInside)
        controlsView.skipBackButton.addTarget(self, action: #selector(onSeekBackwards(_:)), for: .touchUpInside)
        controlsView.skipForwardButton.addTarget(self, action: #selector(onSeekForwards(_:)), for: .touchUpInside)
        controlsView.skipBackButton.addTarget(self, action: #selector(onSeekPrevious(_:event:)), for: .touchDownRepeat)
        controlsView.skipForwardButton.addTarget(self, action: #selector(onSeekNext(_:event:)), for: .touchDownRepeat)
        
        // Layout
        layer.addSublayer(playerLayer)
        addSubview(particleView)
        addSubview(overlayView)
        addSubview(infoView)
        addSubview(controlsView)
        
        particleView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        infoView.snp.makeConstraints {
            $0.leading.equalTo(self.safeArea.leading).inset(20.0)
            $0.trailing.equalTo(self.safeArea.trailing).inset(20.0)
            $0.top.equalTo(self.safeArea.top).inset(25.0)
            $0.height.equalTo(70.0)
        }
        
        controlsView.snp.makeConstraints {
            $0.leading.equalTo(self.safeArea.leading).inset(20.0)
            $0.trailing.equalTo(self.safeArea.trailing).inset(20.0)
            $0.bottom.equalTo(self.safeArea.bottom).inset(25.0)
            $0.height.equalTo(100.0)
        }

        registerNotifications()
        registerPictureInPictureNotifications()
        controlsView.trackBar.delegate = self
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOverlayTapped(_:))).then {
            $0.numberOfTapsRequired = 1
            $0.numberOfTouchesRequired = 1
        })
        
        self.showOverlays(true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longForm, options: [.allowAirPlay, .allowBluetooth, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print(error)
        }
        
        if let observer = self.playObserver {
            player.removeTimeObserver(observer)
        }
        
        notificationObservers.forEach({
            NotificationCenter.default.removeObserver($0)
        })
        
        pictureInPictureObservers.removeAll()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer.frame = self.bounds
    }
    
    @objc
    private func onOverlayTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        if isSeeking {
            showOverlays(true, except: [overlayView, infoView, controlsView.playPauseButton], display: [controlsView.trackBar])
        } else if isPlaying && !isOverlayDisplayed {
            showOverlays(true)
            isOverlayDisplayed = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.isOverlayDisplayed = false
                if self.isPlaying && !self.isSeeking {
                    self.showOverlays(false)
                }
            }
        } else if !isPlaying && !isSeeking && !isOverlayDisplayed {
            showOverlays(true)
            isOverlayDisplayed = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.isOverlayDisplayed = false
                if self.isPlaying && !self.isSeeking {
                    self.showOverlays(false)
                }
            }
        } else {
            showOverlays(true)
            isOverlayDisplayed = true
        }
    }

    private func seekDirectionWithAnimation(_ seekBlock: () -> Void) {
        isSeeking = true
        showOverlays(true)
        
        seekBlock()
        
        fadeAnimationWorkItem?.cancel()
        fadeAnimationWorkItem = DispatchWorkItem(block: {
            self.isSeeking = false
            self.showOverlays(false)
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: fadeAnimationWorkItem!)
    }
    
    @objc
    private func onPlay(_ button: UIButton) {
        fadeAnimationWorkItem?.cancel()
        
        if self.isPlaying {
            self.pause()
        } else {
            self.play()
        }
    }
    
    @objc
    private func onCast(_ button: UIButton) {
        // print("Route Picker Video")
    }
    
    @objc
    private func onPlaybackRateChanged(_ button: UIButton) {
        if requestedPlaybackRate == 1.0 {
            requestedPlaybackRate = 1.5
            button.setTitle("1.5x", for: .normal)
        } else if requestedPlaybackRate == 1.5 {
            requestedPlaybackRate = 2.0
            button.setTitle("2x", for: .normal)
        } else {
            requestedPlaybackRate = 1.0
            button.setTitle("1x", for: .normal)
        }
        
        player.rate = Float(requestedPlaybackRate)
        controlsView.playPauseButton.setImage(#imageLiteral(resourceName: "playlist_pause"), for: .normal)
    }
    
    @objc
    private func onPictureInPicture(_ button: UIButton) {
        guard let pictureInPictureController = pictureInPictureController else { return }
        
        DispatchQueue.main.async {
            if pictureInPictureController.isPictureInPictureActive {
                self.delegate?.onPictureInPicture(enabled: false)
                pictureInPictureController.stopPictureInPicture()
            } else {
                if #available(iOS 14.2, *) {
                    pictureInPictureController.canStartPictureInPictureAutomaticallyFromInline = true
                }
                
                if #available(iOS 14.0, *) {
                    pictureInPictureController.requiresLinearPlayback = false
                }
                
                self.delegate?.onPictureInPicture(enabled: true)
                pictureInPictureController.startPictureInPicture()
            }
        }
    }
    
    @objc
    private func onFullscreen(_ button: UIButton) {
        isFullscreen = true
        infoView.fullscreenButton.isHidden = true
        infoView.exitButton.isHidden = false
        self.delegate?.onFullScreen()
    }
    
    @objc
    private func onExitFullscreen(_ button: UIButton) {
        isFullscreen = false
        infoView.fullscreenButton.isHidden = false
        infoView.exitButton.isHidden = true
        self.delegate?.onExitFullScreen()
    }
    
    @objc
    private func onSeekBackwards(_ button: UIButton) {
        seekDirectionWithAnimation {
            self.seekBackwards()
        }
    }
    
    @objc
    private func onSeekForwards(_ button: UIButton) {
        seekDirectionWithAnimation {
            self.seekForwards()
        }
    }
    
    @objc
    private func onSeekPrevious(_ button: UIButton, event: UIEvent) {
        if let tapCount = event.allTouches?.first?.tapCount, tapCount >= 2 {
            self.delegate?.onPreviousTrack()
        }
    }
    
    @objc
    private func onSeekNext(_ button: UIButton, event: UIEvent) {
        if let tapCount = event.allTouches?.first?.tapCount, tapCount >= 2 {
            self.delegate?.onNextTrack()
        }
    }
    
    func onValueChanged(_ trackBar: VideoTrackerBar, value: CGFloat) {
        isSeeking = true
        
        if isPlaying {
            player.pause()
            wasPlayingBeforeSeeking = true
        }
        
        showOverlays(false, except: [infoView, controlsView], display: [controlsView])
        
        if let currentItem = player.currentItem {
            let seekTime = CMTimeMakeWithSeconds(Float64(value * CGFloat(currentItem.asset.duration.value) / CGFloat(currentItem.asset.duration.timescale)), preferredTimescale: currentItem.currentTime().timescale)
            player.seek(to: seekTime)
        }
    }
    
    func onValueEnded(_ trackBar: VideoTrackerBar, value: CGFloat) {
        isSeeking = false
        
        if wasPlayingBeforeSeeking {
            player.play()
            player.rate = Float(requestedPlaybackRate)
            wasPlayingBeforeSeeking = false
        }
        
        showOverlays(false, except: [overlayView], display: [overlayView])
        overlayView.alpha = 1.0
    }
    
    private func registerNotifications() {
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            
            if self.pictureInPictureController?.isPictureInPictureActive == false {
                self.playerLayer.player = nil
            }
        })
        
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            
            if self.pictureInPictureController?.isPictureInPictureActive == false {
                self.playerLayer.player = self.player
            }
        })
        
        notificationObservers.append(NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { [weak self] _ in
            guard let self = self, let currentItem = self.player.currentItem else { return }
            
            self.controlsView.playPauseButton.isEnabled = false
            self.controlsView.playPauseButton.setImage(nil, for: .normal)
            self.player.pause()
            
            let endTime = CMTimeConvertScale(currentItem.asset.duration, timescale: self.player.currentTime().timescale, method: .roundHalfAwayFromZero)
            
            self.controlsView.trackBar.setTimeRange(currentTime: currentItem.currentTime(), endTime: endTime)
            self.player.seek(to: .zero)
            
            self.controlsView.playPauseButton.isEnabled = true
            self.showOverlays(true)
            
            self.next()
        })
        
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: UIDevice.current, queue: .main) { _ in
            
        })
        
        let interval = CMTimeMake(value: 25, timescale: 1000)
        self.playObserver = self.player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            guard let self = self, let currentItem = self.player.currentItem else { return }
            
            let endTime = CMTimeConvertScale(currentItem.asset.duration, timescale: self.player.currentTime().timescale, method: .roundHalfAwayFromZero)
            
            if CMTimeCompare(endTime, .zero) != 0 && endTime.value > 0 {
                self.controlsView.trackBar.setTimeRange(currentTime: self.player.currentTime(), endTime: endTime)
            }
        })
    }
    
    private func registerPictureInPictureNotifications() {
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pictureInPictureController = AVPictureInPictureController(playerLayer: self.playerLayer)
            guard let pictureInPictureController = pictureInPictureController else { return }
            
            pictureInPictureObservers.append(pictureInPictureController.observe(\AVPictureInPictureController.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] _, change in
                self?.infoView.pictureInPictureButton.isEnabled = change.newValue ?? false
            })
        } else {
            infoView.pictureInPictureButton.isEnabled = false
        }
    }
    
    private func showOverlays(_ show: Bool) {
        self.showOverlays(show, except: [], display: [])
    }
    
    private func showOverlays(_ show: Bool, except: [UIView] = [], display: [UIView] = []) {
        var except = except
        var display = display
        
        if !isVideoAvailable() {
            // If the overlay is showing, hide the particle view.. else show it..
            except.append(particleView)
            
            if !show {
                display.append(particleView)
            }
        } else {
            if show {
                except.append(particleView)
            }
        }
        
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            self.subviews.forEach({
                if !except.contains($0) {
                    $0.alpha = show ? 1.0 : 0.0
                } else if display.contains($0) {
                    $0.alpha = 1.0
                } else {
                    $0.alpha = 0.0
                }
            })
        })
    }
    
    public func setVideoInfo(videoDomain: String) {
        infoView.titleLabel.text = URL(string: videoDomain)?.host ?? videoDomain
        infoView.updateFavIcon(domain: videoDomain)
    }
    
    public func setControlsEnabled(_ enabled: Bool) {
        isUserInteractionEnabled = enabled
    }
    
    public func setFullscreenButtonHidden(_ hidden: Bool) {
        infoView.fullscreenButton.isHidden = hidden
    }
    
    public func attachLayer() {
        layer.insertSublayer(playerLayer, at: 0)
        playerLayer.player = player
    }
    
    public func detachLayer() {
        playerLayer.removeFromSuperlayer()
        playerLayer.player = nil
    }
    
    public func play() {
        if !isPlaying {
            controlsView.playPauseButton.setImage(#imageLiteral(resourceName: "playlist_pause"), for: .normal)
            player.play()
            
            showOverlays(false)
        } else {
            showOverlays(isOverlayDisplayed)
        }
    }
    
    public func pause() {
        if isPlaying {
            controlsView.playPauseButton.setImage(#imageLiteral(resourceName: "playlist_play"), for: .normal)
            player.pause()
            
            showOverlays(true)
        } else {
            showOverlays(isOverlayDisplayed)
        }
    }
    
    public func stop() {
        controlsView.playPauseButton.setImage(#imageLiteral(resourceName: "playlist_play"), for: .normal)
        player.pause()
        
        showOverlays(true)
        player.replaceCurrentItem(with: nil)
    }
    
    public func seek(to time: Double) {
        if let currentItem = player.currentItem {
            var seekTime = time
            if seekTime < 0.0 {
                seekTime = 0.0
            }
            
            if seekTime >= currentItem.duration.seconds {
                seekTime = currentItem.duration.seconds
            }
            
            let absoluteTime = CMTimeMakeWithSeconds(seekTime, preferredTimescale: currentItem.currentTime().timescale)
            player.seek(to: absoluteTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    public func seekBackwards() {
        if let currentItem = player.currentItem {
            let currentTime = currentItem.currentTime().seconds
            var seekTime = currentTime - 15.0

            if seekTime < 0 {
                seekTime = 0
            }
            
            let absoluteTime = CMTimeMakeWithSeconds(seekTime, preferredTimescale: currentItem.currentTime().timescale)
            player.seek(to: absoluteTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    public func seekForwards() {
        if let currentItem = player.currentItem {
            let currentTime = currentItem.currentTime().seconds
            let seekTime = currentTime + 15.0

            if seekTime < (currentItem.duration.seconds - 15.0) {
                let absoluteTime = CMTimeMakeWithSeconds(seekTime, preferredTimescale: currentItem.currentTime().timescale)
                player.seek(to: absoluteTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }
    
    public func previous() {
        self.delegate?.onPreviousTrack()
    }
    
    public func next() {
        self.delegate?.onNextTrack()
    }
    
    public func load(url: URL, resourceDelegate: AVAssetResourceLoaderDelegate?) {
        let asset = AVURLAsset(url: url)
        
        if let delegate = resourceDelegate {
            asset.resourceLoader.setDelegate(delegate, queue: .main)
        }
        
        if let currentItem = player.currentItem, currentItem.asset.isKind(of: AVURLAsset.self) && player.status == .readyToPlay {
            if let asset = currentItem.asset as? AVURLAsset, asset.url.absoluteString == url.absoluteString {
                if isPlaying {
                    self.pause()
                    self.play()
                }
                
                return
            }
        }
        
        asset.loadValuesAsynchronously(forKeys: ["playable", "tracks", "duration"]) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let item = AVPlayerItem(asset: asset)
                self.player.replaceCurrentItem(with: item)
                
                let endTime = CMTimeConvertScale(item.asset.duration, timescale: self.player.currentTime().timescale, method: .roundHalfAwayFromZero)
                self.controlsView.trackBar.setTimeRange(currentTime: item.currentTime(), endTime: endTime)
                self.play()
            }
        }
    }
    
    public func load(asset: AVURLAsset) {
        if let currentItem = player.currentItem, currentItem.asset.isKind(of: AVURLAsset.self) && player.status == .readyToPlay {
            if let currentAsset = currentItem.asset as? AVURLAsset, currentAsset.url.absoluteString == asset.url.absoluteString {
                if isPlaying {
                    self.pause()
                    self.play()
                }
                
                return
            }
        }
        
        asset.loadValuesAsynchronously(forKeys: ["playable", "tracks", "duration"]) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let item = AVPlayerItem(asset: asset)
                self.player.replaceCurrentItem(with: item)
                
                let endTime = CMTimeConvertScale(item.asset.duration, timescale: self.player.currentTime().timescale, method: .roundHalfAwayFromZero)
                self.controlsView.trackBar.setTimeRange(currentTime: item.currentTime(), endTime: endTime)
                self.play()
            }
        }
    }
    
    public func checkInsideTrackBar(point: CGPoint) -> Bool {
        controlsView.trackBar.frame.contains(point)
    }
    
    private func isAudioAvailable() -> Bool {
        if let tracks = self.player.currentItem?.asset.tracks {
            return tracks.filter({ $0.mediaType == .audio }).isEmpty == false
        }
        return false
    }

    private func isVideoAvailable() -> Bool {
        if let tracks = self.player.currentItem?.asset.tracks {
            return tracks.isEmpty || tracks.filter({ $0.mediaType == .video }).isEmpty == false
        }
        
        // We do this because for m3u8 HLS streams,
        // tracks may not always be available and the particle effect will show even on videos..
        // It's best to assume this type of media is a video stream.
        return true
    }
}
