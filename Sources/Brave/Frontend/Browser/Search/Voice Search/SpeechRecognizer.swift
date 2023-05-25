// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Speech
import SwiftUI
import os.log

protocol SpeechRecognizerDelegate: AnyObject {
    func speechRecognizerDidFinishQuery(query: String)
}

class SpeechRecognizer: ObservableObject {
  
  private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "voiceRecognizer")
  
  enum RecognizerError: Error {
    case failedSetup
    case microphoneAccessDenied
    case recognizerIsUnavailable
  }
  
  enum AnimationType {
    case speech(volume: CGFloat)
    case pulse(scale: CGFloat)
  }
  
  private struct AnimationScale {
    static let max: CGFloat = 1.50
    static let pulse: CGFloat = 0.75
  }
  
  weak var delegate: SpeechRecognizerDelegate?
  
  /// Formatted transcript from speech recognizer
  @MainActor @Published var transcript: String = ""
  @MainActor @Published var finalizedRecognition: (status: Bool, searchQuery: String) = (false, "")

  @Published private(set) var animationType: AnimationType = .pulse(scale: 1)

  var isVoiceSearchAvailable: Bool {
    if let recognizer, recognizer.isAvailable {
      return true
    }
    
    return false
  }
  
  private var isSilent = true
    
  private var audioEngine: AVAudioEngine?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private let recognizer: SFSpeechRecognizer?
    
  ///  Constructor for  speech recognizer. If this is the first time you've used the class, it requests
  ///  access to the speech recognizer and the microphone.
  init() {
    recognizer = SFSpeechRecognizer()
    
    guard recognizer != nil else {
      log.debug("Voice Search Setup failed \(RecognizerError.failedSetup.localizedDescription)")
      return
    }
  }
  
  @MainActor
  func askForUserPermission() async throws -> Bool {
    do {
      // Ask for Record Permission if not permitted throw error
      guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
        throw RecognizerError.microphoneAccessDenied
      }
      
      return true
    } catch {
      log.debug("Voice Search Authorization Fault \(error.localizedDescription)")
    }
    
    return false
  }
  
  @MainActor
  func startTranscribing() {
    transcribe()
  }
    
  @MainActor
  func stopTranscribing() {
    reset()
  }
  
  /// Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
  /// The resulting transcription is continuously written to the published `transcript` property.
  private func transcribe() {
    guard let recognizer, recognizer.isAvailable else {
      log.debug("Voice Search Unavailable \(RecognizerError.recognizerIsUnavailable.localizedDescription)")
      return
    }
    
    do {
      let (audioEngine, request) = try setupStartEngine()
        
      self.audioEngine = audioEngine
      self.request = request
      
      task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
        guard let self = self else {
          return
        }
        
        var isFinal = false
        
        if let result {
          // SpeechRecognitionMetadata is the key to detect speaking finalized
          isFinal = result.isFinal || result.speechRecognitionMetadata != nil
          self.transcribe(result.bestTranscription.formattedString)
        }
        
        // Check voice input final
        if isFinal {
          // Remove audio buffer input
          audioEngine.inputNode.removeTap(onBus: 0)
          // Reset Speech Recognizer
          self.reset()
          
          finalize(searchQuery: result?.bestTranscription.formattedString ?? "")
        }
      })
    } catch {
      reset()
      log.debug("Voice Search Recognization Fault \(error.localizedDescription)")
    }
  }
    
  /// Reset the speech recognizer.
  private func reset() {
    try? AVAudioSession.sharedInstance().setActive(false)
    task?.cancel()
    audioEngine?.stop()
    
    audioEngine = nil
    request = nil
    task = nil
  }
    
  private func setupStartEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
    let audioEngine = AVAudioEngine()
    
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.requiresOnDeviceRecognition = true

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    let inputNode = audioEngine.inputNode
    
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
      guard let self else { return }
      
      request.append(buffer)
      
      guard let channelData = buffer.floatChannelData?[0] else {
          return
      }
      
      let volume = self.getVolumeLevel(from: channelData)
      
      Task { @MainActor in
        self.setupAnimationWithVolume(volume)
      }
    }
    
    audioEngine.prepare()
    try audioEngine.start()
    
    return (audioEngine, request)
  }
  
  func getVolumeLevel(from channelData: UnsafeMutablePointer<Float>) -> Float {
      let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: 1024))
      guard channelDataArray.count != 0 else { return 0 }
      
      let silenceThreshold: Float = 0.0030
      let loudThreshold: Float = 0.07
      
      let sumChannelData = channelDataArray.reduce(0) { $0 + abs($1) }
      var channelAverage = sumChannelData / Float(channelDataArray.count)
      channelAverage = min(channelAverage, loudThreshold)
      channelAverage = max(channelAverage, silenceThreshold)

      let normalized = (channelAverage - silenceThreshold) / (loudThreshold - silenceThreshold)
      return normalized
  }

  nonisolated private func transcribe(_ message: String) {
    Task { @MainActor in
      transcript = message
    }
  }
  
  nonisolated private func finalize(searchQuery: String) {
    Task { @MainActor in
      if !finalizedRecognition.status {
        finalizedRecognition = (true, searchQuery)
      }
    }
  }
  
  nonisolated private func clearSearch() {
    Task { @MainActor in
      finalizedRecognition = (false, "")
    }
  }
  
  func startSilenceAnimation() {
    animationType = .pulse(scale: AnimationScale.pulse)
  }

  func startSpeechAnimation(_ scale: CGFloat) {
    animationType = .speech(volume: scale)
  }
  
  private func setupAnimationWithVolume(_ volume: Float) {
    let isCurrentlySilent = volume <= 0
    // We want to make sure that every detected sound makes the outer circle bigger
    let minScale: CGFloat = 1.25
    
    if !isCurrentlySilent {
        let scaleValue = min(CGFloat(volume) + minScale, AnimationScale.max)
        self.startSpeechAnimation(scaleValue)
    }
    
    if !self.isSilent && isCurrentlySilent {
        self.startSilenceAnimation()
    }
    
    self.isSilent = isCurrentlySilent
  }
}

extension AVAudioSession {
  /// Ask for recording permission
  ///  this is used for access microphone
  /// - Returns: Authorization state
  func hasPermissionToRecord() async -> Bool {
    await withCheckedContinuation { continuation in
      requestRecordPermission { authorized in
        continuation.resume(returning: authorized)
      }
    }
  }
}

extension SFSpeechRecognizer {
  /// Ask for Speech recognization authorization
  /// - Returns: Authorization state
  static func hasAuthorizationToRecognize() async -> Bool {
    await withCheckedContinuation { continuation in
      requestAuthorization { status in
        continuation.resume(returning: status == .authorized)
      }
    }
  }
}

