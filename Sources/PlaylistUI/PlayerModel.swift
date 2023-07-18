// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import AVKit
import Combine
import MediaPlayer
import Data
import OrderedCollections

public final class PlayerModel: ObservableObject {
  
  public init() {
    player.seek(to: .zero)
    player.actionAtItemEnd = .none
    
    playerLayer.videoGravity = .resizeAspect
    playerLayer.needsDisplayOnBoundsChange = true
    playerLayer.player = player
    
    setupPlayerKeyPathObservation()
    setupRemoteCommandCenterHandlers()
    updateSystemPlayer()
  }
  
  deinit {
    stop()
  }
  
  public var folder: Folder? {
    didSet {
      playerItems.removeAll()
      guard let folder else {
        return
      }
      for item in folder.items {
        playerItems[item.id] = .init(asset: AVURLAsset(url: item.source, options: [:]))
      }
    }
  }
  
  private var playerItems: OrderedDictionary<Item.ID, AVPlayerItem> = [:]
  
  @Published public var selectedItem: Item? {
    didSet {
      guard let selectedItem, let playerItem = playerItems[selectedItem.id] else { return }
      player.pause()
      player.replaceCurrentItem(with: playerItem)
    }
  }
  
  // MARK: - Player Controls
  
  public var isPlaying: Bool {
    get {
      // It is better NOT to keep tracking of isPlaying OR rate > 0.0
      // Instead we should use the timeControlStatus because PIP and Background play
      // via control-center will modify the timeControlStatus property
      // This will keep our UI consistent with what is on the lock-screen.
      // This will also allow us to properly determine play state in
      // PlaylistMediaInfo -> init -> MPRemoteCommandCenter.shared().playCommand
      player.timeControlStatus == .playing
    } set {
      if newValue {
        play()
      } else {
        pause()
      }
    }
  }
  
  public var currentTime: TimeInterval {
    guard let item = player.currentItem else { return 0 }
    let seconds = item.currentTime().seconds
    return seconds.isNaN ? 0.0 : seconds
  }
  
  public var duration: TimeInterval {
    guard let item = player.currentItem else { return 0 }
    let seconds = CMTimeConvertScale(
      item.asset.duration,
      timescale: item.currentTime().timescale,
      method: .roundHalfAwayFromZero
    ).seconds
    return seconds.isNaN ? 0.0 : seconds
  }
  
  public func play() {
    if isPlaying {
      return
    }
    player.rate = playbackSpeed.rawValue
    player.play()
    // FIXME: We may want to move this to a separate observable object, since we may not want our model updating every hit, or allow a View to subscribe to it independently since its only the media scrubber that needs it
//    periodicTimeObserver = player.addCancellablePeriodicTimeObserver(forInterval: 500) { _ in
//      self.objectWillChange.send()
//    }
  }
  
  public var currentTimeStream: AsyncStream<TimeInterval> {
    return .init { [weak self] continuation in
      guard let self else { return }
      let observer = player.addCancellablePeriodicTimeObserver(forInterval: 500) { [weak self] _ in
        guard let self else { return }
        continuation.yield(currentTime)
      }
      self.cancellables.insert(observer) // Should be tied to the View, but adding ane extra killswitch
      continuation.onTermination = { _ in
        observer.cancel()
      }
    }
  }
  
  public func pause() {
    if !isPlaying {
      return
    }
    player.pause()
  }
  
  public func stop() {
    if !isPlaying {
      return
    }
    player.pause()
    player.replaceCurrentItem(with: nil)
    periodicTimeObserver?.cancel()
  }
  
  public func playPreviousTrack() {
    // Implement
  }
  
  public func playNextTrack() {
    // Implement
  }
  
  private let seekInterval: TimeInterval = 15.0
  
  public func seekBackwards() async {
    guard let currentItem = player.currentItem else {
      return
    }
    await seek(to: currentItem.currentTime().seconds - seekInterval)
  }
  
  public func seekForwards() async {
    guard let currentItem = player.currentItem else {
      return
    }
    await seek(to: currentItem.currentTime().seconds + seekInterval)
  }
  
  public func seek(to time: TimeInterval) async {
    guard let currentItem = player.currentItem else {
      return
    }
    let seekTime = CMTimeMakeWithSeconds(
      max(0.0, min(currentItem.duration.seconds, time)),
      preferredTimescale: currentItem.currentTime().timescale
    )
    await player.seek(to: seekTime)
  }
  
  // MARK: - Playback Extras
  
  public enum RepeatMode {
    case none
    case one
    case all
  }
  
  @Published public var repeatMode: RepeatMode = .none
  
  @Published public var isShuffleEnabled: Bool = false
  
  public enum PlaybackSpeed: Float {
    case normal = 1.0
    case fast = 1.5
    case faster = 2
    
    public mutating func increase() {
      switch self {
      case .normal: self = .fast
      case .fast: self = .faster
      case .faster: self = .normal
      }
    }
  }
  
  @Published public var playbackSpeed: PlaybackSpeed = .normal {
    didSet {
      player.rate = playbackSpeed.rawValue
    }
  }
  
  // MARK: - Picture in Picture
  
  @Published public private(set) var isPictureInPictureSupported: Bool = AVPictureInPictureController.isPictureInPictureSupported()
  
  // MARK: - AirPlay
  
  
  // MARK: -
  
  /*private*/ let player: AVPlayer = .init()
  private let playerLayer: AVPlayerLayer = .init()
  
  private var cancellables: Set<AnyCancellable> = []
  private var periodicTimeObserver: AnyCancellable?
  
  /// Sets up KVO observations for AVPlayer properties which trigger the `objectWillChange` publisher
  private func setupPlayerKeyPathObservation() {
    func subscriber<Value>(for keyPath: KeyPath<AVPlayer, Value>) -> AnyCancellable {
      let observation = player.observe(keyPath, options: [.prior]) { [weak self] _, change in
        if change.isPrior {
          self?.objectWillChange.send()
        }
      }
      return .init {
        observation.invalidate()
      }
    }
    cancellables.formUnion([
      subscriber(for: \.timeControlStatus)
    ])
  }
}

extension AVPlayer {
  fileprivate func addCancellablePeriodicTimeObserver(
    forInterval interval: TimeInterval,
    using block: @escaping @Sendable (CMTime) -> Void
  ) -> AnyCancellable {
    let observer = addPeriodicTimeObserver(
      forInterval: CMTime(value: Int64(interval), timescale: 1000),
      queue: .main,
      using: block
    )
    return .init {
      self.removeTimeObserver(observer)
    }
  }
}

// MARK: - System Media Player
extension PlayerModel {
  private func updateSystemPlayer() {
    let remoteCommandsCenter: MPRemoteCommandCenter = .shared()
    remoteCommandsCenter.skipBackwardCommand.preferredIntervals = [.init(value: seekInterval)]
    remoteCommandsCenter.skipForwardCommand.preferredIntervals = [.init(value: seekInterval)]
    
    let nowPlayingCenter: MPNowPlayingInfoCenter = .default()
    nowPlayingCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
  }
  
  private func setupRemoteCommandCenterHandlers() {
    let center: MPRemoteCommandCenter = .shared()
    let commands: [MPRemoteCommand] = [
      center.pauseCommand,
      center.playCommand,
      center.stopCommand,
      // FIXME: Add the rest
    ]
    cancellables.formUnion(commands.map {
      $0.addCancellableTarget { [weak self] event in
        self?.handleControlCenterCommand(event) ?? .noSuchContent
      }
    })
  }
  
  private func handleControlCenterCommand(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
    let center: MPRemoteCommandCenter = .shared()
    switch event.command {
    case center.pauseCommand:
      pause()
    case center.playCommand:
      play()
    case center.stopCommand:
      stop()
    default:
      break
    }
    return .success
  }
}

extension MPRemoteCommand {
  fileprivate func addCancellableTarget(
    handler: @escaping (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
  ) -> AnyCancellable {
    let handle = addTarget(handler: handler)
    return .init {
      self.removeTarget(handle)
    }
  }
}
