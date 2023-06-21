// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

/// Applies a scale effect when the user presses down with a spring animation attached to it
public struct SpringButtonStyle: ButtonStyle {
  public var scale: CGFloat = 0.95
  public var backgroundStyle: AnyShapeStyle?
  
  @State private var isPressed: Bool = false
  @State private var pressDownTime: Date?
  @State private var delayedTouchUpTask: Task<Void, Error>?
  
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background {
        if let backgroundStyle {
          GeometryReader { proxy in
            if isPressed {
              Rectangle().fill(backgroundStyle)
                .opacity(0.1)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(-8)
                .transition(.asymmetric(
                  insertion: .opacity.animation(.linear(duration: 0.05)),
                  removal: .opacity.animation(.interactiveSpring())
                ))
            }
          }
        }
      }
      .scaleEffect(isPressed ? scale : 1.0)
      .opacity(isPressed ? 0.95 : 1.0)
      .onChange(of: configuration.isPressed, perform: { value in
        if value {
          isPressed = value
          pressDownTime = .now
          delayedTouchUpTask?.cancel()
        } else {
          if let pressDownTime, case let delta = Date.now.timeIntervalSince(pressDownTime), delta < 0.1 {
            delayedTouchUpTask = Task { @MainActor in
              try await Task.sleep(nanoseconds: NSEC_PER_MSEC * UInt64((0.1 - delta) * 1000))
              isPressed = value
            }
          } else {
            isPressed = value
          }
        }
      })
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
  }
}

extension ButtonStyle where Self == SpringButtonStyle {
  public static var spring: SpringButtonStyle {
    .init()
  }
  public static func spring(
    scale: CGFloat = 0.95
  ) -> SpringButtonStyle {
    .init(scale: scale, backgroundStyle: nil)
  }
  public static func spring<S: ShapeStyle>(
    scale: CGFloat = 0.95,
    backgroundStyle: S
  ) -> SpringButtonStyle {
    .init(scale: scale, backgroundStyle: AnyShapeStyle(backgroundStyle))
  }
}

#if DEBUG
struct SpringButtonStyle_PreviewProvider: PreviewProvider {
  static var previews: some View {
    Button("Text Test") { }
      .buttonStyle(.spring(backgroundStyle: Color.black))
  }
}
#endif
