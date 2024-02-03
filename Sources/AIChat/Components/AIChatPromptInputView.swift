// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem
import SpeechRecognition
import AVFoundation

struct AIChatPromptInputView: View {
  @ObservedObject
  var model: AIChatSpeechRecognitionModel
  
  let onTextSubmitted: (String) -> Void

  @State 
  private var prompt: String = ""

  var body: some View {
    HStack(spacing: 0.0) {
      Text("/")
        .font(.caption2)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
        .padding(.horizontal, 12.0)
        .padding(.vertical, 4.0)
        .background(
          RoundedRectangle(cornerRadius: 4.0, style: .continuous)
            .strokeBorder(Color(braveSystemName: .dividerSubtle), lineWidth: 1.0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
        .padding()
      
      TextField(
        "",
        text: $prompt,
        prompt: Text("Enter a prompt here")
          .font(.subheadline)
          .foregroundColor(Color(braveSystemName: .textTertiary))
      )
      .font(.subheadline)
      .foregroundColor(Color(braveSystemName: .textPrimary))
      .submitLabel(.send)
      .onSubmit {
        if !prompt.isEmpty {
          onTextSubmitted(prompt)
          prompt = ""
        }
      }
      //.padding(.leading)
      
      if prompt.isEmpty {
        Button {
          Task { @MainActor in
            let permissionStatus = await model.speechRecognizer.askForUserPermission()
            if permissionStatus {
              model.isVoiceEntryPresented = true
              model.activeInputView = .promptView
            } else {
              model.isNoMicrophonePermissionPresented = true
              model.activeInputView = .none
            }
          }
        } label: {
          Image(braveSystemName: "leo.microphone")
            .foregroundStyle(Color(braveSystemName: .iconDefault))
        }
        .hidden(isHidden: !model.speechRecognizer.isVoiceSearchAvailable)
        .padding()
      } else {
        Button {
          onTextSubmitted(prompt)
          prompt = ""
        } label: {
          Image(braveSystemName: "leo.send")
            .foregroundStyle(Color(braveSystemName: .iconDefault))
        }
        .padding()
      }
    }
    .background(Color(braveSystemName: .containerBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 8.0, style: .continuous)
        .strokeBorder(Color(braveSystemName: .dividerStrong), lineWidth: 1.0)
    )
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
    .shadow(color: .black.opacity(0.15), radius: 4.0, x: 0.0, y: 1.0)
    .onReceive(model.speechRecognizer.$finalizedRecognition) { recognition in
      if recognition.status && model.activeInputView == .promptView {
        // Feedback indicating recognition is finalized
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        UIImpactFeedbackGenerator(style: .medium).bzzt()
        
        // Update Prompt
        prompt = recognition.searchQuery
        
        // Clear the SpeechRecognizer
        model.speechRecognizer.clearSearch()
        model.isVoiceEntryPresented = false
        model.activeInputView = .none
      }
    }
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatPromptInputView(
    model: AIChatSpeechRecognitionModel(
      speechRecognizer: SpeechRecognizer(),
      activeInputView: .constant(.none),
      isVoiceEntryPresented: .constant(false),
      isNoMicrophonePermissionPresented: .constant(false)
    ),
    onTextSubmitted: {
      print("Prompt Submitted: \($0)")
    }
  )
  .previewLayout(.sizeThatFits)
}
