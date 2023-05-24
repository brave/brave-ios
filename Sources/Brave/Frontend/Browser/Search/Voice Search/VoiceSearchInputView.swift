// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import Shared
import Preferences
import Data

struct VoiceSearchInputView: View {
  @Environment(\.presentationMode) @Binding private var presentationMode
  @ObservedObject var speechModel: SpeechRecognizer

  var onEnterSearchKeyword: (() -> Void)?
  @State private var animationScale: CGFloat = 0.75

  private func dismissView() {
    presentationMode.dismiss()
  }
  
  var body: some View {
    NavigationView {
      VStack {
        Spacer()
        microphoneView
      }
      .onAppear {
        speechModel.startTranscribing()
      }.onDisappear {
        speechModel.stopTranscribing()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
      .navigationTitle("Voice Search")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          doneButton
        }
      }
      .background(Color(.secondaryBraveBackground).ignoresSafeArea())
    }
    .navigationViewStyle(.stack)
  }
    
  private var microphoneView: some View {
    VStack {
      Spacer()
      Text(speechModel.transcript)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 25)
        ZStack {
          Circle()
            .foregroundColor(Color(.braveDarkerBlurple).opacity(0.25))
            .frame(width: 150, height: 150, alignment: .center)
            .scaleEffect(animationScale)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationScale)
            .onAppear {
              self.animationScale = 1
            }
          Button {
            onEnterSearchKeyword?()
            dismissView()
          } label: {
            Circle()
              .foregroundColor(Color(.braveDarkerBlurple))
              .frame(width: 75, height: 75, alignment: .center)
          }
          Image(systemName: "mic.fill")
            .resizable()
            .renderingMode(.template)
            .frame(width: 22, height: 35)
            .foregroundColor(.white)
        }
        .padding(.bottom, 45)
        .padding(.top, 45)
        Spacer()
        Text("Brave will never store your searches or share it with any entity.")
          .font(.footnote)
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.secondaryBraveLabel))
          .padding(.horizontal, 25)
    }
    .padding(.bottom, 75)
  }
  
  private var doneButton: some View {
    Button(Strings.done, action: dismissView)
      .foregroundColor(Color(.braveBlurpleTint))
  }
}
