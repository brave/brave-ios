// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem

struct AIChatFeedbackToastModifier<Toast>: ViewModifier where Toast: View {
  @State
  private var task: Task<Void, Error>?
  
  private let displayDuration = 3.0

  let toastView: Toast
  
  @Binding
  var isShowing: Bool
  
  func body(content: Content) -> some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(
        ZStack {
          if isShowing {
            VStack {
              Spacer()
              toastView
            }
            .transition(.move(edge: .bottom))
            .offset(y: -10.0)
          }
        }
          .animation(.spring(), value: isShowing)
      )
      .onChange(of: isShowing) { isShowing in
        if isShowing {
          show()
        }
      }
  }
  
  private func show() {
    guard displayDuration > 0.0 else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    
    task?.cancel()
    task = Task.delayed(bySeconds: displayDuration) { @MainActor in
      dismiss()
    }
  }
  
  private func dismiss() {
    withAnimation {
      isShowing = false
    }
    
    task?.cancel()
    isShowing = false
  }
}

struct AIChatFeedbackToastView: View {
  @Binding
  var isShowing: Bool
  
  var body: some View {
    HStack(spacing: 0.0) {
      Text("Feedback sent successfully")
        .font(.subheadline)
        .foregroundStyle(Color(braveSystemName: .gray10))
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing)
      
      Button {
        isShowing = false
      } label: {
        Image(systemName: "xmark")
          .foregroundStyle(Color(braveSystemName: .primary30))
      }
    }
    .padding()
    .background(Color(braveSystemName: .primary70))
    .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
    .shadow(color: Color.black.opacity(0.25), radius: 8.0, x: 0.0, y: 1.0)
    .padding(.horizontal)
  }
}

extension View {
  func toastView(_ isShowing: Binding<Bool>) -> some View {
    self.modifier(
      AIChatFeedbackToastModifier(
        toastView: AIChatFeedbackToastView(isShowing: isShowing),
        isShowing: isShowing
      )
    )
  }
}

#Preview {
  AIChatFeedbackToastView(isShowing: .constant(true))
}
