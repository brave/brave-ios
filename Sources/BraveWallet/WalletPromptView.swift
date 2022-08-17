// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import DesignSystem

struct WalletPromptContentView<Content: View>: View {
  let content: () -> Content
  var buttonTitle: String
  var action: (_ proceed: Bool) -> Void
  
  init(
    buttonTitle: String,
    action: @escaping (_ proceed: Bool) -> Void,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.buttonTitle = buttonTitle
    self.action = action
    self.content = content
  }
  
  var body: some View {
    VStack {
      content()
        .padding(.bottom)
      Button(action: { action(true) }) {
        Text(buttonTitle)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))
    }
    .frame(maxWidth: .infinity)
    .padding(20)
    .overlay(
      Button(action: { action(false) }) {
        Image(systemName: "xmark")
          .padding(16)
      }
        .font(.headline)
        .foregroundColor(.gray),
      alignment: .topTrailing
    )
    .accessibilityEmbedInScrollView()
  }
}

struct WalletPromptView<Content>: UIViewControllerRepresentable where Content: View {
  @Binding var isPresented: Bool
  var buttonTitle: String
  var action: (Bool, UINavigationController?) -> Bool
  var content: () -> Content
  
  func makeUIViewController(context: Context) -> UIViewController {
    .init()
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    if isPresented {
      if uiViewController.presentedViewController != nil {
        return
      }
      let controller = PopupViewController(
        rootView: WalletPromptContentView(
          buttonTitle: buttonTitle,
          action: { proceed in
            if action(proceed, uiViewController.navigationController) {
              uiViewController.dismiss(animated: true) {
                isPresented = false
              }
            }
          },
          content: content
        )
      )
      uiViewController.present(controller, animated: true)
    } else {
      uiViewController.presentedViewController?.dismiss(animated: true)
    }
  }
}

