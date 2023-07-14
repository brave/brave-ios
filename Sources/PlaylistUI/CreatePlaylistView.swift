// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import Data

struct CreatePlaylistView: View {
  var playLaterItems: [Item]
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  
  @State private var name: String = ""
  @State private var selectedIds: Set<Item.ID> = []
  
  @FocusState private var nameFocus: Bool
  
  var body: some View {
    NavigationView {
      List {
        Section {
          TextField("Enter your playlist name", text: $name) // FIXME: Localize
            .focused($nameFocus)
        } header: {
          Text("Playlist Name") // FIXME: Localize
            .foregroundColor(Color(.braveLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(.init(top: 24, leading: 8, bottom: 8, trailing: 8))
            .textCase(.none)
        }
        if !playLaterItems.isEmpty {
          Section {
            LazyVGrid(
              columns: dynamicTypeSize.isAccessibilitySize ? [.init(), .init()] : [.init(), .init(), .init()]
            ) {
              ForEach(playLaterItems) { item in
                Toggle(
                  isOn: Binding(
                    get: { selectedIds.contains(item.id) },
                    set: { isOn in
                      if isOn {
                        selectedIds.insert(item.id)
                      } else {
                        selectedIds.remove(item.id)
                      }
                    }
                  )
                ) {
                  VStack(alignment: .leading, spacing: 4) {
                    // Thumbnail
                    Color.clear
                      .aspectRatio(1.5, contentMode: .fit)
                      .overlay {
                        ThumbnailImage(itemURL: item.source, faviconURL: nil) // FIXME: Pass in favicon url?
                          .containerShape(ContainerRelativeShape())
                      }
                    Text(item.name)
                      .font(.caption)
                      .padding(4)
                      .lineLimit(1)
                  }
                  .padding(4)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(Color.white)
                  .containerShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                  .accessibilityLabel(Text(item.name))
                }
                .toggleStyle(.playlistItemPicker)
              }
            }
            .listRowBackground(Color(.braveGroupedBackground))
            .listRowInsets(.zero)
          } header: {
            VStack(alignment: .leading) {
              Text("Add from your Play later playlist") // FIXME: Localize
                .foregroundColor(Color(.braveLabel))
              Text("Tap to select media") // FIXME: Localize
                .foregroundColor(Color(.secondaryBraveLabel))
            }
            .textCase(.none)
            .listRowInsets(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
          }
        }
      }
      .listStyle(.insetGrouped)
      .background(Color(.braveGroupedBackground))
      .navigationTitle("Create Playlist") // FIXME: Localize
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text("Cancel") // FIXME: Localize
          }
        }
        ToolbarItemGroup(placement: .confirmationAction) {
          Button {
            PlaylistFolder.addFolder(title: name) { id in
              if !selectedIds.isEmpty {
                // FIXME: Move items in
//                PlaylistItem.moveItems(items: <#T##[NSManagedObjectID]#>, to: <#T##String?#>)
              }
            }
            dismiss()
          } label: {
            Text("Done") // FIXME: Localize
          }
          .disabled(name.isEmpty)
        }
      }
    }
    .navigationViewStyle(.stack)
    .onAppear {
      DispatchQueue.main.async {
        nameFocus = true
      }
    }
  }
}

private struct PlaylistItemPickerToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      configuration.label
        .overlay {
          if configuration.isOn {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .strokeBorder(Color(.braveBlurple).opacity(0.5), lineWidth: 2, antialiased: true)
          }
        }
    }
    .buttonStyle(.spring)
  }
}

extension ToggleStyle where Self == PlaylistItemPickerToggleStyle {
  fileprivate static var playlistItemPicker: PlaylistItemPickerToggleStyle {
    .init()
  }
}

#if DEBUG
struct CreatePlaylistView_PreviewProvider: PreviewProvider {
  static var previews: some View {
    CreatePlaylistView(
      playLaterItems: (0..<9).map { i in
        Item(id: String(i), dateAdded: .now, duration: 1000, source: URL(string: "https://brave.com")!, name: "Item \(i)", pageSource: URL(string: "https://brave.com")!)
      }
    )
    .previewDisplayName("Basic")
    CreatePlaylistView(
      playLaterItems: []
    )
    .previewDisplayName("No Play Later Items")
  }
}
#endif
