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

actor SpeechRecognizer: ObservableObject {
  
  private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "voiceRecognizer")
  
  enum RecognizerError: Error {
    case failedSetup
    case notAuthorizedToRecognize
    case notPermittedToRecord
    case recognizerIsUnavailable
  }
  
  weak var delegate: SpeechRecognizerDelegate?
  
  /// Formatted transcript from speech recognizer
  @MainActor @Published var transcript: String = ""
  @MainActor @Published var finalizedRecognition: (status: Bool, searchQuery: String) = (false, "")

  var isVoiceSearchAvailable: Bool {
    if let recognizer, recognizer.isAvailable {
      return true
    }
    
    return false
  }
    
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
  func askForUserPermission() async throws -> (Bool, RecognizerError?) {
    do {
      // Ask for Record Permission if not permitted throw error
      guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
        throw RecognizerError.notPermittedToRecord
      }
      
//      // Ask for Speech Recognizer Authorization if not authorized throw error
//      // Data will be sent to Apple server for improved accuracy
//      guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
//        throw RecognizerError.notAuthorizedToRecognize
//      }
      
      return (true, nil)
    } catch {
      log.debug("Voice Search Authorization Fault \(error.localizedDescription)")

      return (false, error as? RecognizerError)
    }
  }
  
  @MainActor
  func startTranscribing() {
    Task {
      await transcribe()
    }
  }
    
  @MainActor
  func stopTranscribing() {
    Task {
      await reset()
    }
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
          Task {
            await self.reset()
          }
          
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
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
      request.append(buffer)
    }
    
    audioEngine.prepare()
    try audioEngine.start()
    
    return (audioEngine, request)
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

extension AVAudioSession {
  /// Ask for recording permission
  /// - Returns: Authorization state
  func hasPermissionToRecord() async -> Bool {
    await withCheckedContinuation { continuation in
      requestRecordPermission { authorized in
        continuation.resume(returning: authorized)
      }
    }
  }
}

