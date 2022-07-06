// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

public struct InvisibleUIView: UIViewRepresentable {
  let uiView = UIView()
  public func makeUIView(context: Context) -> UIView {
    uiView.backgroundColor = .clear
    return uiView
  }
  public func updateUIView(_ uiView: UIView, context: Context) {
  }
}

private struct CoinTypesMenuAnchorKey: EnvironmentKey {
  static var defaultValue: InvisibleUIView = .init()
}

extension EnvironmentValues {
  var coinTypesMenuAnchor: InvisibleUIView {
    get { self[CoinTypesMenuAnchorKey.self] }
    set { self[CoinTypesMenuAnchorKey.self] = newValue }
  }
}

