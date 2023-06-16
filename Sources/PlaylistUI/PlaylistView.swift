// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI

struct PlaylistView: View {
  var folder: Folder
  
  @State private var selectedItemID: Item.ID?
  @State private var offset: CGFloat = 0
  @State private var drawerHeight: CGFloat = 0
  @State private var screenHeight: CGFloat = 0
  @State private var listHeight: CGFloat = 0
  @GestureState private var isDragging: Bool = false
  @State private var startHeight: CGFloat?
  
  init(folder: Folder) {
    self.folder = folder
    let appareance = UINavigationBarAppearance().then {
      $0.configureWithTransparentBackground()
      $0.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    UINavigationBar.appearance().scrollEdgeAppearance = appareance
    UINavigationBar.appearance().standardAppearance = appareance
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
  
  var body: some View {
    VStack {
      Color.black.aspectRatio(16/9, contentMode: .fit)
      ControlView(title: "")
        .padding(.vertical)
      Color.clear
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
    .background(Color.gray)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(folder.title)
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        Button { } label: {
          Image(braveSystemName: "leo.picture.in-picture")
        }
        .tint(Color.white)
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
        Button { } label: {
          Image(braveSystemName: "leo.close")
        }
        .tint(Color.white)
      }
    }
  }
}

#if DEBUG
struct PlaylistView_PreviewProvider: PreviewProvider {
  static var previews: some View {
    Color.black.fullScreenCover(isPresented: .constant(true)) {
      NavigationView {
        PlaylistView(folder: .init(id: UUID().uuidString, title: "Play Later", items: (0..<10).map { i in
          .init(id: "\(i)", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!)
        }))
      }
    }
  }
}
#endif

#if swift(>=5.9)
@available(iOS, introduced: 13.0, obsoleted: 16.0, message: "Use UnevenRoundedRectangle")
#endif
struct PartialRoundedRectangle: Shape {
  var cornerRadius: CGFloat
  var corners: UIRectCorner = .allCorners
  
  func path(in rect: CGRect) -> Path {
    Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath)
  }
}

extension DragGesture.Value {
  @_disfavoredOverload
  @available(iOS, introduced: 13.0, obsoleted: 17.0)
  var velocity: CGSize {
    let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
    let d = decelerationRate / (1000.0 * (1.0 - decelerationRate))
    return CGSize(
      width: (location.x - predictedEndLocation.x) / d,
      height: (location.y - predictedEndLocation.y) / d
    )
  }
}
