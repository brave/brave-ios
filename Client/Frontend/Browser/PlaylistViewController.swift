// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveShared
import AVKit
import AVFoundation

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
        $0.image = #imageLiteral(resourceName: "videoThumbSlider")
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
            endTimeLabel.text = self.timeToString(endTime)
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
            $0.left.equalToSuperview()
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
        
        slider.snp.makeConstraints {
            $0.left.equalTo(currentTimeLabel.snp.right).offset(5.0)
            $0.right.equalTo(endTimeLabel.snp.left).offset(-5.0)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(2.5)
        }
        
        endTimeLabel.snp.makeConstraints {
            $0.right.equalToSuperview()
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
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

private class VideoView: UIView, VideoTrackerBarDelegate {
    private let player = AVPlayer(playerItem: nil).then {
        $0.seek(to: .zero)
        $0.actionAtItemEnd = .none
    }
    
    private let thumbnailView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let overlayView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
    }
    
    private let skipBackButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "videoSkipBack"), for: .normal)
        $0.tintColor = .white
    }
    
    private let skipForwardButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "videoSkipForward"), for: .normal)
        $0.tintColor = .white
    }
    
    private let playPauseButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "videoPlay"), for: .normal)
        $0.tintColor = .white
    }
    
    private let castButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "videoAirplay"), for: .normal)
        
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
    
    private let fullScreenButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "videoFullscreen"), for: .normal)
        $0.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        $0.layer.cornerRadius = 5.0
        $0.layer.masksToBounds = true
    }
    
    private let exitFullScreenButton = UIButton().then {
        $0.imageView?.contentMode = .scaleAspectFit
        $0.setImage(#imageLiteral(resourceName: "close-medium").template, for: .normal)
        $0.tintColor = .white
        $0.isHidden = true
    }
    
    private let trackBarBackground = UIView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
    }
    
    private let playControlsStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .fill
        $0.distribution = .fillEqually
        $0.spacing = 15.0
    }
    
    private let trackBar = VideoTrackerBar()
    private let orientation: UIInterfaceOrientation = .portrait
    private var playObserver: Any?
    
    private(set) public var isPlaying: Bool = false
    private(set) public var isSeeking: Bool = false
    private(set) public var isFullscreen: Bool = false
    private(set) public var isOverlayDisplayed: Bool = false
    private var notificationObservers = [NSObjectProtocol]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //Setup
        self.backgroundColor = .black
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOverlayTapped(_:))).then {
            $0.numberOfTapsRequired = 1
            $0.numberOfTouchesRequired = 1
        })
        
        (self.layer as? AVPlayerLayer)?.do {
            $0.player = self.player
            $0.videoGravity = .resizeAspect
            $0.needsDisplayOnBoundsChange = true
        }

        playPauseButton.addTarget(self, action: #selector(onPlay(_:)), for: .touchUpInside)
        castButton.addTarget(self, action: #selector(onCast(_:)), for: .touchUpInside)
        fullScreenButton.addTarget(self, action: #selector(onFullscreen(_:)), for: .touchUpInside)
        exitFullScreenButton.addTarget(self, action: #selector(onExitFullscreen(_:)), for: .touchUpInside)
        
        //Layout
        self.addSubview(trackBarBackground)
        self.addSubview(thumbnailView)
        self.addSubview(overlayView)
        self.addSubview(playControlsStackView)
        self.addSubview(castButton)
        self.addSubview(fullScreenButton)
        self.addSubview(exitFullScreenButton)
        self.addSubview(trackBar)
        
        [skipBackButton, playPauseButton, skipForwardButton].forEach({ playControlsStackView.addArrangedSubview($0) })
        
        trackBarBackground.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(trackBar.snp.top)
        }
        
        thumbnailView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        playControlsStackView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(20.0)
            $0.top.equalTo(trackBar.snp.top).offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
        
        trackBar.snp.makeConstraints {
            $0.left.equalTo(playControlsStackView.snp.right).offset(20.0)
            $0.bottom.equalToSuperview()
        }
        
        castButton.snp.makeConstraints {
            $0.left.equalTo(trackBar.snp.right).offset(15.0)
            $0.right.equalToSuperview().offset(-20.0)
            $0.top.equalTo(trackBar.snp.top).offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
        
        fullScreenButton.snp.makeConstraints {
            $0.left.top.equalToSuperview().offset(15.0)
            $0.width.equalTo(43.0)
            $0.height.equalTo(30.0)
        }
        
        exitFullScreenButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-15.0)
            $0.top.equalToSuperview().offset(15.0)
        }
        
        registerNotifications()
        trackBar.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let observer = self.playObserver {
            player.removeTimeObserver(observer)
        }
        
        notificationObservers.forEach({
            NotificationCenter.default.removeObserver($0)
        })
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    @objc
    private func onOverlayTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        if isSeeking {
            showOverlays(true, except: [overlayView, playPauseButton], display: [trackBarBackground, trackBar])
        } else if isPlaying && !isOverlayDisplayed {
            showOverlays(true)
            isOverlayDisplayed = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isOverlayDisplayed = false
                if self.isPlaying && !self.isSeeking {
                    self.showOverlays(true)
                }
            }
        } else if !isPlaying && !isSeeking && !isOverlayDisplayed {
            showOverlays(true)
            isOverlayDisplayed = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isOverlayDisplayed = false
                if self.isPlaying && !self.isSeeking {
                    self.showOverlays(false)
                }
            }
        }
    }
    
    @objc
    private func onPlay(_ button: UIButton) {
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
    private func onFullscreen(_ button: UIButton) {
        
    }
    
    @objc
    private func onExitFullscreen(_ button: UIButton) {
        
    }
    
    func onValueChanged(_ trackBar: VideoTrackerBar, value: CGFloat) {
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
    
    func onValueEnded(_ trackBar: VideoTrackerBar, value: CGFloat) {
        isSeeking = false
        
        if self.isPlaying {
            player.play()
        }
        
        showOverlays(false, except: [overlayView], display: [overlayView])
        overlayView.alpha = 1.0
    }
    
    private func registerNotifications() {
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
    
    private func showOverlays(_ show: Bool) {
        self.showOverlays(show, except: [self.overlayView], display: [])
    }
    
    private func showOverlays(_ show: Bool, except: [UIView] = [], display: [UIView] = []) {
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.subviews.forEach({
                if except.contains($0) {
                    $0.alpha = !show ? 1.0 : 0.0
                } else if display.contains($0) {
                    $0.alpha = 1.0
                }
            })
        })
    }
    
    public func play() {
        if !isPlaying {
            isPlaying.toggle()
            playPauseButton.setImage(#imageLiteral(resourceName: "videoPause"), for: .normal)
            player.play()
            
            showOverlays(false)
        }
    }
    
    public func pause() {
        if isPlaying {
            isPlaying.toggle()
            playPauseButton.setImage(#imageLiteral(resourceName: "videoPlay"), for: .normal)
            player.pause()
            
            showOverlays(true)
        }
    }
    
    public func stop() {
        isPlaying = false
        playPauseButton.setImage(#imageLiteral(resourceName: "videoPlay"), for: .normal)
        player.pause()
        
        showOverlays(true)
        player.replaceCurrentItem(with: nil)
    }
    
    public func load(url: URL) {
        thumbnailView.isHidden = false
        let asset = AVAsset(url: url)
        
        if let currentItem = player.currentItem, currentItem.asset.isKind(of: AVURLAsset.self) && player.status == .readyToPlay {
            if let asset = currentItem.asset as? AVURLAsset, asset.url.absoluteString == url.absoluteString {
                thumbnailView.isHidden = true
                
                if isPlaying {
                    player.pause()
                    player.play()
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
            }
        }
    }
}

class PlaylistViewController: UIViewController {
    private var tabManager: TabManager
    
    private let stackView = UIStackView().then {
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)
    }
    
    private let infoLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12.0, weight: .regular)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.appearanceTextColor = .white
        $0.numberOfLines = 0
        $0.text = "Hello Brave Welcome to blah blah blah.."
    }
    
    private let playerView = VideoView()
    private var tableView = UITableView(frame: .zero, style: .grouped)
    private var playlistItems = [PlaylistInfo]()
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationController?.navigationBar.tintColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        navigationController?.navigationBar.appearanceBarTintColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        view.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        
        tableView.backgroundView = UIView()
        tableView.backgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        tableView.appearanceBackgroundColor = #colorLiteral(red: 0.231372549, green: 0.2431372549, blue: 0.3137254902, alpha: 1)
        tableView.separatorColor = .clear
        tableView.appearanceSeparatorColor = .clear
        
        tableView.register(PlaylistCell.self, forCellReuseIdentifier: "PlaylistCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        view.addSubview(stackView)
        view.addSubview(playerView)
        stackView.addArrangedSubview(infoLabel)
        
        stackView.snp.makeConstraints {
            $0.leading.trailing.top.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(40.0)
        }
        
        playerView.snp.makeConstraints {
            $0.top.equalTo(stackView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.60 * view.bounds.width)
        }
        
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeArea.edges)
        }
        
        //tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: (0.60 * view.bounds.width) + 40.0, left: 0.0, bottom: 0.0, right: 0.0)
        tableView.contentOffset = CGPoint(x: 0.0, y: (-0.60 * view.bounds.width) - 40.0)
        
        tabManager.tabsForCurrentMode.forEach({
            $0.playlistItems.observe { [weak self] _, _ in
                guard let self = self else { return }
                self.updateItems()
            }.bind(to: self)
        })
    }
    
    private func updateItems() {
        playlistItems = tabManager.tabsForCurrentMode.map({ $0.playlistItems }).flatMap({ $0.value })
        playlistItems.forEach({
            Playlist.shared.addItem(item: $0)
        })
        
        CarplayMediaManager.shared.updatePlayableItems()
    }
}

extension PlaylistViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as? PlaylistCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        cell.indicatorIcon.image = #imageLiteral(resourceName: "videoThumbSlider").template
        cell.indicatorIcon.tintColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        cell.thumbnailView.image = #imageLiteral(resourceName: "shields-menu-icon")
        cell.titleLabel.text = "Welcome to Brave Video Player"
        cell.detailLabel.text = "22 mins"
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return PlaylistHeader()
    }
}

extension PlaylistViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.playlistItems[indexPath.row]
        self.playerView.load(url: URL(string: item.src)!)
    }
}

private class PlaylistHeader: UIView {
    
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 17.0, weight: .bold)
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.text = "Playlist"
    }
    
    private let sortButton = UIButton().then {
        $0.setTitle("Sort by Most Recent ", for: .normal)
        $0.setTitleColor(#colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14.0, weight: .regular)
        $0.setImage(#imageLiteral(resourceName: "find_next").scale(toSize: CGSize(width: 12, height: 8)).template, for: .normal)
        $0.imageView?.tintColor = #colorLiteral(red: 0, green: 0.6666666667, blue: 1, alpha: 1)
        $0.imageView?.contentMode = .scaleAspectFit
        
        $0.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        $0.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        $0.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }
    
    private let separator = UIView().then {
        $0.backgroundColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        addSubview(sortButton)
        addSubview(separator)
        
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-15.0)
        }
        
        sortButton.snp.makeConstraints {
            $0.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(15.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-15.0)
        }
        
        separator.snp.makeConstraints {
            $0.left.equalToSuperview().offset(87.0)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class PlaylistCell: UITableViewCell {
    public let indicatorIcon = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    public let thumbnailView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 5.0
        $0.layer.masksToBounds = true
    }
    
    public let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.appearanceTextColor = .white
        $0.font = .systemFont(ofSize: 14.0, weight: .medium)
    }
    
    public let detailLabel = UILabel().then {
        $0.textColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
        $0.appearanceTextColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
        $0.font = .systemFont(ofSize: 12.0, weight: .regular)
    }
    
    private let iconStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 15.0
    }
    
    private let infoStackView = UIStackView().then {
        $0.axis = .vertical
    }
    
    private let separator = UIView().then {
        $0.backgroundColor = #colorLiteral(red: 0.5176470588, green: 0.5411764706, blue: 0.568627451, alpha: 1)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.preservesSuperviewLayoutMargins = false
        self.selectionStyle = .none
        
        contentView.addSubview(iconStackView)
        contentView.addSubview(infoStackView)
        iconStackView.addArrangedSubview(indicatorIcon)
        iconStackView.addArrangedSubview(thumbnailView)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(detailLabel)
        contentView.addSubview(separator)
        
        indicatorIcon.snp.makeConstraints {
            $0.width.height.equalTo(12.0)
        }
        
        thumbnailView.snp.makeConstraints {
            $0.width.height.equalTo(30.0)
        }
        
        iconStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
        
        infoStackView.snp.makeConstraints {
            $0.left.equalTo(iconStackView.snp.right).offset(15.0)
            $0.right.equalToSuperview().offset(-15.0)
            $0.top.equalToSuperview().offset(5.0)
            $0.bottom.equalToSuperview().offset(-5.0)
        }
        
        separator.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.left)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var layoutMargins: UIEdgeInsets {
        get {
            return .zero
        }

        set (newValue) {
            super.layoutMargins = .zero
        }
    }
    
    override var separatorInset: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
        
        set (newValue) {
            super.separatorInset = UIEdgeInsets(top: 0, left: self.titleLabel.frame.origin.x, bottom: 0, right: 0)
        }
    }
}
