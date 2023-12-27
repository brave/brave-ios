

import SwiftUI
import DesignSystem

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

struct AIChatNavigationView: View {
  let onClose: (() -> Void)
  let onErase: (() -> Void)
  let onMenu: (() -> Void)
  
  var body: some View {
    TopView {
      Button {
        onClose()
      } label: {
        Text("Close")
          .font(.body)
          .foregroundStyle(Color(braveSystemName: .textTertiary))
      }
      .padding()
    } center: {
      Text("Leo")
        .font(.body)
        .fontWeight(.bold)
        .foregroundStyle(Color(braveSystemName: .textPrimary))
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
    } right: {
      HStack {
        Button {
          onErase()
        } label: {
          Image(braveSystemName: "leo.erase")
            .tint(Color(braveSystemName: .textTertiary))
        }
        .padding()
        
        Button {
          onMenu()
        } label: {
          Image(braveSystemName: "leo.more.horizontal")
            .tint(Color(braveSystemName: .textTertiary))
        }
        .padding()
      }
    }
    .background(Color(braveSystemName: .pageBackground))
  }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
  AIChatNavigationView(onClose: {
    print("Closed Chat")
  }, onErase: {
    print("Erased Chat History")
  }, onMenu: {
    print("Opened Chat Menu")
  })
    .previewLayout(.sizeThatFits)
}
