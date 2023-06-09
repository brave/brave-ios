// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import Data
import Strings
import BraveUI
import BraveStrings
import DesignSystem

struct Folder: Identifiable {
  var id: String
  var title: String
  var items: [Item]
}

extension String {
  static let defaultPlaylistID: Folder.ID = PlaylistFolder.savedFolderUUID
}

struct Item: Identifiable {
  var id: String
  var dateAdded: Date
  var duration: TimeInterval
  var source: URL
  var name: String
  var pageSource: URL
}

/// The root view that displays the list of playlists (folders) the user has created
struct PlaylistListView: View {
  var folders: [Folder]
  var sharedFolders: [Folder]
  
  @Environment(\.dismiss) private var dismiss
  
  struct NoUserFoldersView: View {
    var body: some View {
      VStack(spacing: 24) {
        Text("Create custom playlists: make it theme based or subject based. It’s all up to you.") // TODO: Localize
          .font(.callout)
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.braveLabel))
        Button {
          
        } label: {
          Text("Create Playlist") // TODO: Localize
            .foregroundColor(Color(.braveBlurpleTint))
            .font(.callout.weight(.semibold))
            .padding(.horizontal)
        }
        .buttonStyle(BraveOutlineButtonStyle(size: .large))
      }
      .padding(.horizontal, 40)
    }
  }
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVStack(spacing: 8) {
        Section {
          ForEach(folders) { folder in
            Button {
              // Navigate to the folder…
            } label: {
              PlaylistFolderView(folder: folder)
                .contextMenu {
                  // Can you share the default playlist?
                  Button {
                    
                  } label: {
                    Label("Share Playlist", braveSystemImage: "leo.share.macos")
                  }
                  // TODO: Do we hide this if all content in the folder is downloaded?
                  Button {
                    
                  } label: {
                    Label("Download", braveSystemImage: "leo.cloud.download")
                  }
                  if folder.id != .defaultPlaylistID {
                    Button(role: .destructive) {
                      
                    } label: {
                      Label("Delete", braveSystemImage: "leo.trash")
                    }
                  }
                }
            }
            .buttonStyle(.spring)
          }
        }
        if sharedFolders.isEmpty {
          if folders.count == 1 {
            // Empty state
            NoUserFoldersView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .aspectRatio(1, contentMode: .fit)
              .padding(.vertical)
          }
        } else {
          Section {
            ForEach(sharedFolders) { folder in
              Button {
                // Navigate to the folder…
              } label: {
                PlaylistFolderView(folder: folder)
              }
              .buttonStyle(.spring)
            }
          } header: {
            Text("Shared Playlists") // TODO: Localize
              .foregroundColor(Color(.braveLabel))
              .padding([.horizontal, .top])
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
      .padding(.horizontal, 8)
    }
    .listBackgroundColor(Color(.braveBackground))
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Create") { // TODO: Localize
          // Create
        }
      }
      ToolbarItem(placement: .cancellationAction) {
        Button(Strings.close) {
          dismiss()
        }
      }
    }
    .navigationTitle("Playlist") // TODO: Localize
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct PlaylistFolderView: View {
  var folder: Folder
  
  @ViewBuilder var icon: some View {
    Group {
      if folder.id == .defaultPlaylistID {
        Image(braveSystemName: "leo.history")
          .foregroundColor(.white)
      } else {
        Image(braveSystemName: "leo.product.playlist")
          .foregroundColor(Color(.braveLabel))
      }
    }
    .imageScale(.large)
    .frame(width: 64, height: 64)
    .background(folder.id == .defaultPlaylistID ? Color(UIColor(rgb: 0x423EEE)) : .white)
  }
  
  var background: some ShapeStyle {
    if folder.id == .defaultPlaylistID {
      return Color(UIColor(rgb: 0x3835CA))
    } else {
      return Color(UIColor(rgb: 0xF0F1F4))
    }
  }
  
  private var containerShape: some InsettableShape {
    RoundedRectangle(cornerRadius: 12, style: .continuous)
  }
  
  var body: some View {
    HStack {
      icon
        .clipShape(ContainerRelativeShape())
        .padding(8)
      VStack(alignment: .leading) {
        Text(folder.title)
          .font(.callout.weight(.semibold))
          .foregroundColor(folder.id == .defaultPlaylistID ? .white : Color(.braveLabel))
        Text("\(folder.items.count) items") // TODO: Localize
          .font(.footnote)
          .foregroundColor(folder.id == .defaultPlaylistID ? .white : Color(.secondaryBraveLabel))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(background)
    .containerShape(containerShape)
    .contentShape(.contextMenuPreview, containerShape)
  }
}

#if DEBUG
struct PlaylistListView_PreviewProvider: PreviewProvider {
  static var previews: some View {
    NavigationView {
      PlaylistListView(
        folders: [
          .init(id: .defaultPlaylistID, title: "Play Later", items: [])
        ],
        sharedFolders: []
      )
    }
    .previewDisplayName("Empty State")
    
    NavigationView {
      PlaylistListView(
        folders: [
          .init(id: .defaultPlaylistID, title: "Play Later", items: []),
          .init(id: UUID().uuidString, title: "Chill Playlist", items: []),
        ],
        sharedFolders: [
          .init(id: UUID().uuidString, title: "Shared Playlist", items: []),
        ]
      )
    }
    .previewDisplayName("Empty Folders")
//    PlaylistListView(folders: [.init(id: .defaultPlaylistID, title: "Play Later", items: [])
  }
}
#endif
