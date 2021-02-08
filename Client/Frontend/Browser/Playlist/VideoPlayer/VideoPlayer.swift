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

private class VideoSliderBar: UIControl {
    public var trackerInsets = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
    public var value: CGFloat = 0.0 {
        didSet {
            trackerConstraint?.constant = boundaryView.bounds.size.width * value
            filledConstraint?.constant = value >= 1.0 ? bounds.size.width : ((bounds.size.width - (trackerInsets.left + trackerInsets.right)) * value) + trackerInsets.left
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tracker.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPanned(_:))))
        
        addSubview(background)
        addSubview(boundaryView)
        
        background.addSubview(filledView)
        boundaryView.addSubview(tracker)
        
        background.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        boundaryView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        filledView.snp.makeConstraints {
            $0.right.top.bottom.equalTo(background)
        }
        
        tracker.snp.makeConstraints {
            $0.centerY.equalTo(boundaryView.snp.centerY)
            $0.width.height.equalTo(12.0)
        }
        
        filledConstraint = filledView.leftAnchor.constraint(equalTo: background.leftAnchor).then {
            $0.isActive = true
        }
        
        trackerConstraint = tracker.centerXAnchor.constraint(equalTo: boundaryView.leftAnchor).then {
            $0.isActive = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.background.layer.cornerRadius = self.bounds.size.height / 2.0
        
        boundaryView.snp.remakeConstraints {
            $0.edges.equalToSuperview().inset(self.trackerInsets)
        }
        
        if self.filledConstraint?.constant ?? 0 < self.trackerInsets.left {
            self.filledConstraint?.constant = self.trackerInsets.left
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if tracker.bounds.size.width < 44.0 || tracker.bounds.size.height < 44.0 {
            let adjustedBounds = CGRect(x: tracker.center.x, y: tracker.center.y, width: 0.0, height: 0.0).inset(by: touchInsets)
            
            if adjustedBounds.contains(point) {
                return tracker
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if tracker.bounds.size.width < 44.0 || tracker.bounds.size.height < 44.0 {
            let adjustedBounds = CGRect(x: tracker.center.x, y: tracker.center.y, width: 0.0, height: 0.0).inset(by: touchInsets)
            
            if adjustedBounds.contains(point) {
                return true
            }
        }
        
        return super.point(inside: point, with: event)
    }
    
    @objc
    private func onPanned(_ recognizer: UIPanGestureRecognizer) {
        let offset = min(boundaryView.bounds.size.width, max(0.0, recognizer.location(in: boundaryView).x))
        
        value = offset / boundaryView.bounds.size.width
        
        sendActions(for: .valueChanged)
        
        if recognizer.state == .cancelled || recognizer.state == .ended {
            sendActions(for: .touchUpInside)
        }
    }
    
    private var filledConstraint: NSLayoutConstraint?
    private var trackerConstraint: NSLayoutConstraint?
    
    private let touchInsets = UIEdgeInsets(top: 44.0, left: 44.0, bottom: 44.0, right: 44.0)
    
    private var background = UIView().then {
        $0.backgroundColor = .white
        $0.clipsToBounds = true
    }
    
    private var filledView = UIView().then {
        $0.backgroundColor = #colorLiteral(red: 0.337254902, green: 0.337254902, blue: 0.337254902, alpha: 1)
        $0.clipsToBounds = true
    }
    
    private var boundaryView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private var tracker = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
        $0.image = #imageLiteral(resourceName: "playlist_video_thumb")
    }
}

private protocol VideoTrackerBarDelegate: class {
    func onValueChanged(_ trackBar: VideoTrackerBar, value: CGFloat)
    func onValueEnded(_ trackBar: VideoTrackerBar, value: CGFloat)
}

private class VideoTrackerBar: UIView {
    public weak var delegate: VideoTrackerBarDelegate?
    
    private let slider = VideoSliderBar()
    
    private let currentTimeLabel = UILabel().then {
        $0.text = "0:00"
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.font = .systemFont(ofSize: 12.0)
    }
    
    private let endTimeLabel = UILabel().then {
        $0.text = "0:00"
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.font = .systemFont(ofSize: 12.0)
    }
    
    public func setTimeRange(currentTime: CMTime, endTime: CMTime) {
        if CMTimeCompare(endTime, .zero) != 0 && endTime.value > 0 {
            slider.value = CGFloat(currentTime.value) / CGFloat(endTime.value)
            
            currentTimeLabel.text = self.timeToString(currentTime)
            endTimeLabel.text = "-\(self.timeToString(endTime - currentTime))"
        } else {
            slider.value = 0.0
            currentTimeLabel.text = "0:00"
            endTimeLabel.text = "0:00"
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        slider.addTarget(self, action: #selector(onValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(onValueEnded(_:)), for: .touchUpInside)
        
        addSubview(slider)
        addSubview(currentTimeLabel)
        addSubview(endTimeLabel)
        
        currentTimeLabel.snp.makeConstraints {
            $0.left.equalToSuperview().inset(10.0)
            $0.top.equalToSuperview().offset(2.0)
            $0.bottom.equalTo(slider.snp.top).offset(-5.0)
        }
        
        endTimeLabel.snp.makeConstraints {
            $0.right.equalToSuperview().inset(10.0)
            $0.top.equalToSuperview().offset(2.0)
            $0.bottom.equalTo(slider.snp.top).offset(-5.0)
        }
        
        slider.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(10.0)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(2.5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func onValueChanged(_ slider: VideoSliderBar) {
        self.delegate?.onValueChanged(self, value: slider.value)
    }
    
    @objc
    private func onValueEnded(_ slider: VideoSliderBar) {
        self.delegate?.onValueEnded(self, value: slider.value)
    }
    
    private func timeToString(_ time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let minutes = floor(totalSeconds.truncatingRemainder(dividingBy: 3600.0) / 60.0)
        let seconds = floor(totalSeconds.truncatingRemainder(dividingBy: 60.0))
        return String(format: "%02zu:%02zu", Int(minutes), Int(seconds))
    }
}

protocol VideoViewDelegate: class {
    func onPreviousTrack()
    func onNextTrack()
    func onPictureInPicture(enabled: Bool)
    func onFullScreen()
}

public class VideoView: UIView, VideoTrackerBarDelegate {
    
    weak var delegate: VideoViewDelegate?
    
    public let player = AVPlayer(playerItem: nil).then {
        $0.seek(to: .zero)
        $0.actionAtItemEnd = .none
    }
    
    private var requestedPlaybackRate = 1.0
    
    private let thumbnailView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
    }
    
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
    
    private let skipBackButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setBackgroundImage(#imageLiteral(resourceName: "playlist_rewind"), for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.setTitle("15", for: .normal)
        $0.tintColor = .white
    }
    
    private let skipForwardButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setBackgroundImage(#imageLiteral(resourceName: "playlist_forward"), for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.setTitle("15", for: .normal)
        $0.tintColor = .white
    }
    
    private let playPauseButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "playlist_play"), for: .normal)
    }
    
    private let castButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "playlist_airplay"), for: .normal)
        $0.tintColor = .white
        
        let routePicker = AVRoutePickerView()
        routePicker.tintColor = .clear
        routePicker.activeTintColor = .clear

        if #available(iOS 13.0, *) {
            routePicker.prioritizesVideoDevices = true
        }
        
        $0.addSubview(routePicker)
        routePicker.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private let pipButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "playlist_pip"), for: .normal)
        $0.isHidden = !AVPictureInPictureController.isPictureInPictureSupported()
    }
    
    private let fullScreenButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "playlist_fullscreen"), for: .normal)
    }
    
    private let playbackRateButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setTitle("1x", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 21.0, weight: .medium)
    }
    
    private let trackBarBackground = UIView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6004120291)
    }
    
    private let playControlsView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private let playerLayer = AVPlayerLayer().then {
        $0.videoGravity = .resizeAspect
        $0.needsDisplayOnBoundsChange = true
    }
    
    private let trackBar = VideoTrackerBar()
    private let orientation: UIInterfaceOrientation = .portrait
    private var playObserver: Any?
    private var fadeAnimationWorkItem: DispatchWorkItem?
    
    private(set) public var isPlaying: Bool = false
    private(set) public var isSeeking: Bool = false
    private(set) public var isFullscreen: Bool = false
    private(set) public var isOverlayDisplayed: Bool = false
    private var notificationObservers = [NSObjectProtocol]()
    private(set) public var pictureInPictureController: AVPictureInPictureController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            log.error(error)
        }

        //Setup
        self.backgroundColor = .black
        self.playerLayer.player = self.player

        playPauseButton.addTarget(self, action: #selector(onPlay(_:)), for: .touchUpInside)
        castButton.addTarget(self, action: #selector(onCast(_:)), for: .touchUpInside)
        playbackRateButton.addTarget(self, action: #selector(onPlaybackRateChanged(_:)), for: .touchUpInside)
        pipButton.addTarget(self, action: #selector(onPictureInPicture(_:)), for: .touchUpInside)
        fullScreenButton.addTarget(self, action: #selector(onFullscreen(_:)), for: .touchUpInside)
        skipBackButton.addTarget(self, action: #selector(onSeekBackwards(_:)), for: .touchUpInside)
        skipForwardButton.addTarget(self, action: #selector(onSeekForwards(_:)), for: .touchUpInside)
        skipBackButton.addTarget(self, action: #selector(onSeekPrevious(_:event:)), for: .touchDownRepeat)
        skipForwardButton.addTarget(self, action: #selector(onSeekNext(_:event:)), for: .touchDownRepeat)
        
        //Layout
        layer.addSublayer(playerLayer)
        addSubview(trackBarBackground)
        addSubview(thumbnailView)
        addSubview(particleView)
        addSubview(overlayView)
        addSubview(playControlsView)
        addSubview(castButton)
        addSubview(playbackRateButton)
        addSubview(pipButton)
        addSubview(fullScreenButton)
        addSubview(trackBar)
                
        [skipBackButton, playPauseButton, skipForwardButton].forEach({ playControlsView.addSubview($0) })
        
        playPauseButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        skipBackButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().multipliedBy(0.5)
        }

        skipForwardButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().multipliedBy(1.5)
        }
        
        trackBarBackground.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(trackBar.snp.top)
        }
        
        thumbnailView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        particleView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        playControlsView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        trackBar.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
        }
        
        fullScreenButton.snp.makeConstraints {
            $0.top.right.equalToSuperview().inset(15.0)
        }
        
        castButton.snp.makeConstraints {
            $0.top.left.equalToSuperview().inset(15.0)
        }
        
        playbackRateButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(15.0)
            $0.left.equalTo(castButton.snp.right).offset(15.0)
            $0.width.height.equalTo(castButton)
        }
        
        pipButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(15.0)
            $0.right.equalTo(fullScreenButton.snp.left).offset(-15.0)
        }

        registerNotifications()
        registerPictureInPictureNotifications()
        trackBar.delegate = self
        
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
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer.frame = self.bounds
    }
    
    @objc
    private func onOverlayTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        if isSeeking {
            showOverlays(true, except: [overlayView, playPauseButton], display: [trackBarBackground, trackBar])
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
        //print("Route Picker Video")
    }
    
    @objc
    private func onPlaybackRateChanged(_ button: UIButton) {
        requestedPlaybackRate += 1.0
        if Int(requestedPlaybackRate) > 3 {
            requestedPlaybackRate = 1.0
        }
        
        player.rate = Float(requestedPlaybackRate)
        button.setTitle("\(Int(requestedPlaybackRate))x", for: .normal)
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
        self.delegate?.onFullScreen()
    }
    
    @objc
    private func onExitFullscreen(_ button: UIButton) {
        
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
    
    fileprivate func onValueChanged(_ trackBar: VideoTrackerBar, value: CGFloat) {
        isSeeking = true
        
        if isPlaying {
            player.pause()
        }
        
        showOverlays(false, except: [trackBar, trackBarBackground], display: [trackBar, trackBarBackground])
        
        if let currentItem = player.currentItem {
            let seekTime = CMTimeMakeWithSeconds(Float64(value * CGFloat(currentItem.asset.duration.value) / CGFloat(currentItem.asset.duration.timescale)), preferredTimescale: currentItem.currentTime().timescale)
            player.seek(to: seekTime)
        }
    }
    
    fileprivate func onValueEnded(_ trackBar: VideoTrackerBar, value: CGFloat) {
        isSeeking = false
        
        if self.isPlaying {
            player.play()
        }
        
        showOverlays(false, except: [overlayView], display: [overlayView])
        overlayView.alpha = 1.0
    }
    
    private func registerNotifications() {
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.playerLayer.player = nil
        })
        
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.playerLayer.player = self.player
        })
        
        notificationObservers.append(NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { [weak self] _ in
            guard let self = self, let currentItem = self.player.currentItem else { return }
            
            self.playPauseButton.isEnabled = false
            self.playPauseButton.setImage(nil, for: .normal)
            self.player.pause()
            
            let endTime = CMTimeConvertScale(currentItem.asset.duration, timescale: self.player.currentTime().timescale, method: .roundHalfAwayFromZero)
            
            self.trackBar.setTimeRange(currentTime: currentItem.currentTime(), endTime: endTime)
            self.player.seek(to: .zero)
            
            self.isPlaying = false
            self.playPauseButton.isEnabled = true
            self.showOverlays(true)
            
            self.next()
            
            if self.isFullscreen {
                self.onFullscreen(self.fullScreenButton)
            }
        })
        
        notificationObservers.append(NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: UIDevice.current, queue: .main) { _ in
            
        })
        
        let interval = CMTimeMake(value: 25, timescale: 1000)
        self.playObserver = self.player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            guard let self = self, let currentItem = self.player.currentItem else { return }
            
            let endTime = CMTimeConvertScale(currentItem.asset.duration, timescale: self.player.currentTime().timescale, method: .roundHalfAwayFromZero)
            
            if CMTimeCompare(endTime, .zero) != 0 && endTime.value > 0 {
                self.trackBar.setTimeRange(currentTime: self.player.currentTime(), endTime: endTime)
            }
        })
    }
    
    private func registerPictureInPictureNotifications() {
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pictureInPictureController = AVPictureInPictureController(playerLayer: self.playerLayer)
            guard let pictureInPictureController = pictureInPictureController else { return }
            
            notificationObservers.append(pictureInPictureController.observe(\AVPictureInPictureController.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] _, change in
                self?.pipButton.isEnabled = change.newValue ?? false
            })
        } else {
            pipButton.isEnabled = false
        }
    }
    
    private func showOverlays(_ show: Bool) {
        //self.showOverlays(show, except: [self.overlayView], display: [])
        self.showOverlays(show, except: [], display: [])
    }
    
    private func showOverlays(_ show: Bool, except: [UIView] = [], display: [UIView] = []) {
        var except = except
        var display = display
        
        if !isVideoAvailable() {
            //if the overlay is showing, hide the particle view.. else show it..
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
    
    public func setControlsEnabled(_ enabled: Bool) {
//        [skipBackButton, playPauseButton, skipForwardButton,
//         pipButton, castButton, fullScreenButton].forEach({
//            $0.isEnabled = enabled
//         })
        
        isUserInteractionEnabled = enabled
    }
    
    public func play() {
        if !isPlaying {
            isPlaying.toggle()
            playPauseButton.setImage(#imageLiteral(resourceName: "playlist_pause"), for: .normal)
            player.play()
            
            showOverlays(false)
        } else {
            showOverlays(isOverlayDisplayed)
        }
    }
    
    public func pause() {
        if isPlaying {
            isPlaying.toggle()
            playPauseButton.setImage(#imageLiteral(resourceName: "playlist_play"), for: .normal)
            player.pause()
            
            showOverlays(true)
        } else {
            showOverlays(isOverlayDisplayed)
        }
    }
    
    public func stop() {
        isPlaying = false
        playPauseButton.setImage(#imageLiteral(resourceName: "playlist_play"), for: .normal)
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
        thumbnailView.isHidden = false
        let asset = AVURLAsset(url: url)
        
        if let delegate = resourceDelegate {
            asset.resourceLoader.setDelegate(delegate, queue: .main)
        }
        
        if let currentItem = player.currentItem, currentItem.asset.isKind(of: AVURLAsset.self) && player.status == .readyToPlay {
            if let asset = currentItem.asset as? AVURLAsset, asset.url.absoluteString == url.absoluteString {
                thumbnailView.isHidden = true
                
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
                self.trackBar.setTimeRange(currentTime: item.currentTime(), endTime: endTime)
                self.thumbnailView.isHidden = true
                self.play()
            }
        }
    }
    
    public func load(asset: AVURLAsset) {
        thumbnailView.isHidden = false
        
        if let currentItem = player.currentItem, currentItem.asset.isKind(of: AVURLAsset.self) && player.status == .readyToPlay {
            if let currentAsset = currentItem.asset as? AVURLAsset, currentAsset.url.absoluteString == asset.url.absoluteString {
                thumbnailView.isHidden = true
                
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
                self.trackBar.setTimeRange(currentTime: item.currentTime(), endTime: endTime)
                self.thumbnailView.isHidden = true
                self.play()
            }
        }
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
        
        //We do this because for m3u8 HLS streams,
        //tracks may not always be available and the particle effect will show even on videos..
        //It's best to assume this type of media is a video stream.
        return true
    }
}
