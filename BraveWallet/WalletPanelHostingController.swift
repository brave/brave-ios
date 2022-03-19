// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SwiftUI

/// Displays a summary of the users wallet when they are visiting a webpage that wants to connect with the
/// users wallet
public class WalletPanelHostingController: UIHostingController<WalletPanelContainerView> {
  public init(
    walletStore: WalletStore
  ) {
    gesture = WalletInteractionGestureRecognizer(
      keyringStore: walletStore.keyringStore
    )
    super.init(rootView: WalletPanelContainerView(
      walletStore: walletStore,
      keyringStore: walletStore.keyringStore
    ))
    rootView.presentWalletWithContext = { [weak self] context in
      guard let self = self else { return }
      self.present(WalletHostingViewController(walletStore: walletStore, presentingContext: context), animated: true)
    }
  }
  
  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
  
  deinit {
    gesture.view?.removeGestureRecognizer(gesture)
  }
  
  private let gesture: WalletInteractionGestureRecognizer
  
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    view.window?.addGestureRecognizer(gesture)
  }
  
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    // For some reason these 2 calls are required in order for the `UIHostingController` to layout
    // correctly. Without this it for some reason becomes taller than what it needs to be despite its
    // `sizeThatFits(_:)` calls returning the correct value once the parent does layout.
    view.setNeedsUpdateConstraints()
    view.updateConstraintsIfNeeded()
  }
}
