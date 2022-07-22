//
//  SwiftUIView.swift
//  
//
//  Created by Brandon on 2022-07-22.
//

import SwiftUI

struct PlaylistFolderSharingManagementView: View {
  var body: some View {
    VStack {
      Text("Managing your Playlist data")
      Text("Auto-save for offline use is on, meaning new additions to playlists, including shared playlists are saveed to your device for viewing offline and could use your cellular data.")
      Text("Auto-save for offlien use can be managed in Playlist settings.")
      
      Button("Add playlist now") {
        
      }
      
      Button("Settings") {
      }
      
      Button("Cancel") {
        
      }
    }
    .environment(\.colorScheme, .dark)
  }
}

#if DEBUG
struct PlaylistFolderSharingManagementView_Previews: PreviewProvider {
  static var previews: some View {
    PlaylistFolderSharingManagementView()
  }
}
#endif
