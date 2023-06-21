// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI
import Introspect

public struct PlaylistView: View {
  public var folder: Folder
  
  @State private var selectedItemID: Item.ID?
  @State private var offset: CGFloat = 0
  @State private var drawerHeight: CGFloat = 0
  @State private var screenHeight: CGFloat = 0
  @State private var listHeight: CGFloat = 0
  @GestureState private var isDragging: Bool = false
  @State private var startHeight: CGFloat?
  
  @Environment(\.dismiss) var dismiss
  
  public init(folder: Folder) {
    self.folder = folder
  }
  
  var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .global)
      .updating($isDragging, body: { _, state, _ in
        state = true
      })
      .onChanged { (value: DragGesture.Value) in
        if startHeight == nil {
          startHeight = drawerHeight
        }
        drawerHeight = min(screenHeight, startHeight! - value.translation.height)
      }
      .onEnded { (value: DragGesture.Value) in
        let endHeight = startHeight! - value.predictedEndTranslation.height
        startHeight = nil
        let stopPoints = [0, 0.75, 1.0].map { screenHeight * $0 }
        let ranges = stopPoints.enumerated().reduce(into: [(Range<Double>, Int)](), {
          if $1.offset == stopPoints.count - 1 {
            $0.append(($1.element..<CGFloat.infinity, $1.offset))
          } else {
            let nextElement = stopPoints[$1.offset+1]
//            let halfPoint = $1.element + ((nextElement - $1.element) / 2.0)
//            $0.append(($1.element..<halfPoint, $1.offset))
//            $0.append((halfPoint..<nextElement, $1.offset+1))
            $0.append(($1.element..<nextElement, $1.offset))
          }
        })
        withAnimation(.interpolatingSpring(duration: 0.3, bounce: 0.0, initialVelocity: value.velocity.height / screenHeight)) {
          if let index = ranges.first(where: { $0.0.contains(endHeight)})?.1 {
            let screenRelativeHeight = stopPoints[index] / screenHeight
            drawerHeight = listHeight + (screenRelativeHeight * (screenHeight - listHeight))
          } else {
            drawerHeight = listHeight
          }
        }
      }
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      Color.black
        .overlay {
          LinearGradient(braveGradient: .gradient03) // Video player?
            .aspectRatio(16/9, contentMode: .fit)
        }
        .clipped()
      ControlView(title: "")
        .padding(.vertical, 24)
        .contentShape(Rectangle())
      Color.clear
        .frame(minHeight: 100)
        .background {
          GeometryReader { proxy in
            Color.clear
              .onAppear {
                listHeight = proxy.size.height
                drawerHeight = listHeight
              }
              .onChange(of: proxy.size.height) { newValue in
                listHeight = newValue
                if !isDragging {
                  drawerHeight = listHeight
                }
              }
          }
        }
        .overlay(alignment: .bottom) {
          VStack(spacing: 0) {
            PlaylistItemHeaderView(folder: folder)
              .clipShape(PartialRoundedRectangle(cornerRadius: 10, corners: [.topLeft, .topRight]))
              .contentShape(PartialRoundedRectangle(cornerRadius: 10, corners: [.topLeft, .topRight]))
              .simultaneousGesture(dragGesture)
            
            PlaylistItemListView(folder: folder, selectedItemId: selectedItemID)
              .background(Color(.braveBackground))
          }
          .frame(height: drawerHeight)
        }
    }
    .frame(maxHeight: .infinity)
    .background {
      GeometryReader { proxy in
        Color.clear
          .onAppear { screenHeight = proxy.size.height }
          .onChange(of: proxy.size.height) { newValue in
            screenHeight = newValue
          }
      }
    }
    .background {
      ZStack {
        // Thumbnail or some representation of the video
        LinearGradient(braveGradient: .gradient03)
        VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
      }
      .ignoresSafeArea()
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(folder.title)
//    .sheet(isPresented: .constant(true)) {
//      VStack(spacing: 0) {
//        PlaylistItemHeaderView(folder: folder)
//          .clipShape(PartialRoundedRectangle(cornerRadius: 10, corners: [.topLeft, .topRight]))
//          .contentShape(PartialRoundedRectangle(cornerRadius: 10, corners: [.topLeft, .topRight]))
//        
//        PlaylistItemListView(folder: folder, selectedItemId: selectedItemID)
//          .background(Color(.braveBackground))
//      }
//      .osAvailabilityModifiers { content in
//        if #available(iOS 16.0, *) {
//          content
//            .presentationDetents([.fraction(0.2), .large])
//        } else {
//          content
//        }
//      }
//      .osAvailabilityModifiers { content in
//        if #available(iOS 16.4, *) {
//          content
//            .presentationBackgroundInteraction(.enabled(upThrough: .large))
//        } else {
//          content
//        }
//      }
//      .interactiveDismissDisabled()
//    }
    .osAvailabilityModifiers { content in
      if #available(iOS 16.0, *) {
        content
          .toolbarColorScheme(.dark, for: .navigationBar)
      } else {
        content
      }
    }
    .introspectViewController { controller in
      let appearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        return appearance
      }()
      controller.navigationItem.standardAppearance = appearance
      controller.navigationItem.compactAppearance = appearance
      controller.navigationItem.scrollEdgeAppearance = appearance
    }
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Menu {
          Button { } label: {
            Label("Edit", braveSystemImage: "leo.folder.exchange")
          }
          Button { } label: {
            Label("Rename", braveSystemImage: "leo.edit.box")
          }
          Button { } label: {
            Label("Remove Offline Data", braveSystemImage: "leo.cloud.off")
          }
          Button(role: .destructive) { } label: {
            Label("Delete", braveSystemImage: "leo.trash")
          }
        } label: {
          Image(braveSystemName: "leo.more.horizontal")
        }
        .tint(Color.white)
        Button {
          dismiss()
        } label: {
          Image(braveSystemName: "leo.close")
        }
        .tint(Color.white)
      }
    }
  }
}

@available(iOS, introduced: 13.0, obsoleted: 16.0, message: "Use UnevenRoundedRectangle")
struct PartialRoundedRectangle: Shape {
  var cornerRadius: CGFloat
  var corners: UIRectCorner = .allCorners
  
  func path(in rect: CGRect) -> Path {
    Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath)
  }
}

// These definitions can be removed once we move to Xcode 15
#if swift(<5.9)
extension DragGesture.Value {
  /// This version of `velocity` is found the iOS 17 SDK's SwiftUI swiftinterface file and
  /// is backported to iOS 13
  public var velocity: CGSize {
    let predicted = predictedEndLocation
    return CGSize(
      width: 4.0 * (predicted.x - location.x),
      height: 4.0 * (predicted.y - location.y)
    )
  }
}

extension SwiftUI.Animation {
  /// This version of `interpolatingSpring` is found the iOS 17 SDK's SwiftUI swiftinterface
  /// file and is backported to iOS 13
  public static func interpolatingSpring(
    duration: TimeInterval = 0.5,
    bounce: Double = 0.0,
    initialVelocity: Swift.Double = 0.0
  ) -> SwiftUI.Animation {
    func springStiffness(response: Double) -> Double {
      if response <= 0 {
        return .infinity
      } else {
        let freq = (2.0 * Double.pi) / response
        return freq * freq
      }
    }
    func springDamping(fraction: Double, stiffness: Double) -> Double {
      let criticalDamping = 2 * stiffness.squareRoot()
      return criticalDamping * fraction
    }
    func springDampingFraction(bounce: Double) -> Double {
      (bounce < 0.0) ? 1.0 / (bounce + 1.0) : 1.0 - bounce
    }
    let stiffness = springStiffness(response: duration)
    let fraction = springDampingFraction(bounce: bounce)
    let damping = springDamping(fraction: fraction, stiffness: stiffness)
    return interpolatingSpring(
      stiffness: stiffness,
      damping: damping,
      initialVelocity: initialVelocity
    )
  }
}
#endif

#if DEBUG
struct PlaylistView_PreviewProvider: PreviewProvider {
  static var previews: some View {
//    Color.black.fullScreenCover(isPresented: .constant(true)) {
      NavigationView {
        PlaylistView(folder: .init(id: UUID().uuidString, title: "Play Later", items: (0..<10).map { i in
            .init(id: "\(i)", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!)
        }))
//      }
    }
  }
}
#endif
