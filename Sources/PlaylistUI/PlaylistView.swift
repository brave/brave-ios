// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI

@available(iOS 16.0, *)
struct PlaylistView: View {
  var folder: Folder
  
  @State private var selectedItemID: Item.ID?
  @State private var offset: CGFloat?
  @State private var screenHeight: CGFloat = 0
  
  var body: some View {
    VStack {
      Color.gray.aspectRatio(16/9, contentMode: .fit)
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
      PlaylistItemListView(folder: folder, selectedItemId: selectedItemID)
        .background(Color(.braveBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .offset(y: min(screenHeight - 66, max(66, screenHeight - 66 + (offset ?? 0))))
//        .scrollDisabled(true)
        .disabled(true)
    }
    .background(Color.black)
    .simultaneousGesture(DragGesture().onChanged { state in
      offset = state.translation.height
    })
    .toolbarBackground(.hidden, for: .navigationBar)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(folder.title)
  }
}

#if DEBUG
@available(iOS 16.0, *)
struct PlaylistView_PreviewProvider: PreviewProvider {
  static var previews: some View {
    NavigationView {
      PlaylistView(folder: .init(id: UUID().uuidString, title: "Play Later", items: [
        .init(id: "1", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!),
        .init(id: "2", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!),
        .init(id: "3", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!)
      ]))
    }
  }
}
#endif
