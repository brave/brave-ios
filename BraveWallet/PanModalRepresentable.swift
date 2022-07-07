// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import PanModal
import BraveUI

struct PanModalRepresentable<Content: View>: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  var content: Content
  
  func makeUIViewController(context: Context) -> UIViewController {
    return .init()
  }
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    if isPresented {
      if uiViewController.presentedViewController != nil {
        return
      }
      let hostingController = FixedHeightHostingPanModalController(rootView: content)
      hostingController.didDismiss = {
        isPresented = false
      }
      uiViewController.presentPanModal(hostingController, sourceView: uiViewController.view, sourceRect: uiViewController.view.bounds, completion: nil)
    } else {
      guard uiViewController.presentedViewController is FixedHeightHostingPanModalController<Content> else {
        return
      }
      uiViewController.dismiss(animated: true, completion: nil)
    }
  }
}

extension View {
  func panModal<Content: View>(
    isPresented: Binding<Bool>,
    @ViewBuilder content: () -> Content
  ) -> some View {
    self
      .background(PanModalRepresentable(isPresented: isPresented, content: content()))
  }
}
