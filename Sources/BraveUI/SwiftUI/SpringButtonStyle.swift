// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

/// Applies a scale effect when the user presses down with a spring animation attached to it
public struct SpringButtonStyle: ButtonStyle {
  public var scale: CGFloat = 0.95
  
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? scale : 1.0)
      .opacity(configuration.isPressed ? 0.95 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == SpringButtonStyle {
  public static var spring: SpringButtonStyle {
    .init()
  }
  public static func spring(scale: CGFloat = 0.95) -> SpringButtonStyle {
    .init(scale: scale)
  }
}
