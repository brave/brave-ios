// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import DesignSystem
import BraveCore

private struct TopView<L, C, R>: View where L: View, C: View, R: View {
  private let left: () -> L
  private let center: () -> C
  private let right: () -> R

  init(@ViewBuilder left: @escaping () -> L,
       @ViewBuilder center: @escaping () -> C,
       @ViewBuilder right: @escaping () -> R) {
      self.left = left
      self.center = center
      self.right = right
  }

  var body: some View {
    ZStack {
      HStack {
        left()
        Spacer()
      }

      center()

      HStack {
          Spacer()
          right()
      }
    }
  }
}

struct AIChatNavigationView<Content>: View where Content: View {
  let isMenusAvailable: Bool
  let premiumStatus: AiChat.PremiumStatus
  let onClose: (() -> Void)
  let onErase: (() -> Void)
  
  @ViewBuilder
  let menuContent: (() -> Content)
  
  @State
  private var showSettingsMenu = false
  
  var body: some View {
    TopView {
      Button {
        onClose()
      } label: {
        Text("Close")
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textInteractive))
      }
      .padding()
    } center: {
      HStack(spacing: 0.0) {
        Text("Leo")
          .font(.body)
          .fontWeight(.bold)
          .foregroundStyle(Color(braveSystemName: .textPrimary))
          .padding(.horizontal, 8.0)
          .padding(.vertical)
       
        if premiumStatus == .active {
          Text("PREMIUM")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(Color(braveSystemName: .blue50))
            .padding(.horizontal, 6.0)
            .padding(.vertical, 4.0)
            .background(RoundedRectangle(cornerRadius: 4.0, style: .continuous)
              .fill(Color(braveSystemName: .blue20)))
        }
      }
    } right: {
      if isMenusAvailable {
        HStack(spacing: 0.0) {
          Button {
            onErase()
          } label: {
            Image(braveSystemName: "leo.erase")
              .tint(Color(braveSystemName: .textInteractive))
          }
          
          Button {
            showSettingsMenu = true
          } label: {
            Image(braveSystemName: "leo.settings")
              .tint(Color(braveSystemName: .textInteractive))
          }
          .padding()
          .popover(isPresented: $showSettingsMenu,
                   content: {
            menuContent()
          })
        }
      }
    }
    .background(Color(braveSystemName: .pageBackground))
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatNavigationView(
    isMenusAvailable: true,
    premiumStatus: .active,
    onClose: {
      print("Closed Chat")
    }, onErase: {
      print("Erased Chat History")
    }, menuContent: {
      EmptyView()
    }
  )
  .previewLayout(.sizeThatFits)
}
