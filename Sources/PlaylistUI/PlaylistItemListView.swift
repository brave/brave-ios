// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

struct PlaylistItemHeaderView: View {
  var folder: Folder
  
  @ViewBuilder var totalDuration: some View {
    let total = folder.items.reduce(0, { $0 + $1.duration })
    if #available(iOS 16.0, *) {
      Text(Duration.seconds(total), format: .units(width: .condensedAbbreviated))
    } else {
      Text("\(total)") // FIXME: Use legacy formatter
    }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      Capsule()
        .opacity(0.3)
        .frame(width: 32, height: 4)
        .padding(.top, 6)
      HStack {
        VStack(alignment: .leading) {
          Text(folder.title)
            .font(.body.weight(.medium))
          HStack {
            Text("\(folder.items.count) items")
            if !folder.items.isEmpty {
              totalDuration
            }
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
        Spacer()
        Button { } label: {
          VStack(spacing: 4) {
            Image(braveSystemName: "leo.play.circle")
              .font(.title3)
            Text("Play All")
              .font(.caption)
          }
          .foregroundStyle(Color(.braveBlurple))
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      Divider()
    }
    .background(Color(.braveBackground))
  }
}

struct PlaylistItemListView: View {
  var folder: Folder
  var selectedItemId: Item.ID?
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVStack(spacing: 0) {
        Section {
          ForEach(folder.items) { item in
            Button { } label: {
              PlaylistItemView(
                title: item.name,
                isItemPlaying: false,
                duration: Int(item.duration),
                downloadState: nil
              )
            }
            .background(selectedItemId == item.id ? Color(red: 0.941, green: 0.944, blue: 0.957) : Color(.braveBackground))
            .buttonStyle(.spring)
            .contextMenu {
              Section {
                Button { } label: {
                  Label("Delete Offline Cache", braveSystemImage: "leo.cloud.off")
                }
              }
              Section {
                Button { } label: {
                  Label("Open In New Tab", braveSystemImage: "leo.window.tab-new")
                }
                Button { } label: {
                  Label("Open In New Private Tab", braveSystemImage: "leo.product.private-window")
                }
              }
              Section {
                Button { } label: {
                  Label("Move…", braveSystemImage: "leo.folder")
                }
                Button { } label: {
                  Label("Share…", braveSystemImage: "leo.share.macos")
                }
              }
              Section {
                Button(role: .destructive) { } label: {
                  Label("Delete", braveSystemImage: "leo.trash")
                }
              }
            }
          }
        }
      }
    }
  }
}

#if DEBUG
struct PlaylistItemListView_PreviewProvider: PreviewProvider {
  static var previews: some View {
    PlaylistItemListView(
      folder: .init(id: UUID().uuidString, title: "Play Later", items: [
        .init(id: "1", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!),
        .init(id: "2", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!),
        .init(id: "3", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!)
      ]),
      selectedItemId: "2"
    )
  }
}
#endif
