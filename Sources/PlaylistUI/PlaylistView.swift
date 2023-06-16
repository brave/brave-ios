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
  @State private var screenHeight: CGFloat = 0
  @State private var listHeight: CGFloat = 0
  @GestureState private var isDragging: Bool = false
  @State private var startOffset: CGFloat?
  
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
    DragGesture(minimumDistance: 0)
      .updating($isDragging, body: { _, state, _ in
        state = true
      })
      .onChanged { (value: DragGesture.Value) in
        if startOffset == nil {
          startOffset = offset
        }
        offset = max(-listHeight + 66, min(0, startOffset! + value.translation.height))
      }
      .onEnded { (value: DragGesture.Value) in
        let endOffset = max(-listHeight + 66, min(0, startOffset! + value.predictedEndTranslation.height))
        startOffset = nil
        let stopPoints = [0, 0.3, 0.8, 1.0].map { listHeight * $0 }
        let ranges = stopPoints.enumerated().reduce(into: [(Range<Double>, Int)](), {
          if $1.offset == stopPoints.count - 1 {
            $0.append(($1.element..<CGFloat.infinity, $1.offset))
          } else {
            let nextElement = stopPoints[$1.offset+1]
            let halfPoint = $1.element + ((nextElement - $1.element) / 2.0)
            $0.append(($1.element..<halfPoint, $1.offset))
            $0.append((halfPoint..<nextElement, $1.offset+1))
          }
        })
        withAnimation(.interpolatingSpring(duration: 0.3, bounce: 0.0, initialVelocity: value.velocity.height / listHeight)) {
          if let index = ranges.first(where: { $0.0.contains(-endOffset)})?.1 {
            offset = -(stopPoints[index])
          } else {
            offset = 0
          }
        }
      }
  }
  
  var body: some View {
    VStack {
      Color.black.aspectRatio(16/9, contentMode: .fit)
      ControlView(title: "")
        .padding(.vertical)
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
    .overlay {
      VStack(spacing: 0) {
        PlaylistItemHeaderView(folder: folder)
        PlaylistItemListView(folder: folder, selectedItemId: selectedItemID)
          .background(Color(.braveBackground))
          .disabled(isDragging)
      }
      .background {
        GeometryReader { proxy in
          Color.clear
            .onAppear { listHeight = proxy.size.height }
            .onChange(of: proxy.size.height) { newValue in
              listHeight = newValue
            }
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .offset(y: min(screenHeight, max(0, screenHeight - 66 + offset))) // offset must be on top of gesture otherwise it glitches
      .gesture(dragGesture)
      .ignoresSafeArea(.container, edges: .bottom)
    }
    .background(Color.gray)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(folder.title)
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
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
      }
    }
  }
}

#if DEBUG
struct PlaylistView_PreviewProvider: PreviewProvider {
  static var previews: some View {
    Color.black.sheet(isPresented: .constant(true)) {
      NavigationView {
        PlaylistView(folder: .init(id: UUID().uuidString, title: "Play Later", items: (0..<10).map { i in
          .init(id: "\(i)", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!)
        }))
      }
    }
  }
}
#endif

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
