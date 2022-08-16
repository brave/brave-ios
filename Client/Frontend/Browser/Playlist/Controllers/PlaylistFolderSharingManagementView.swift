// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveShared

struct PlaylistFolderSharingManagementView: View {
  var body: some View {
    VStack {
      Text(Strings.PlaylistFolderSharing.offlineManagementViewTitle)
      Text(Strings.PlaylistFolderSharing.offlineManagementViewDescription)
      Text(Strings.PlaylistFolderSharing.offlineManagementViewSubDescription)
      
      Button(Strings.PlaylistFolderSharing.offlineManagementViewAddButtonTitle) {
        
      }
      
      Button(Strings.PlaylistFolderSharing.offlineManagementViewSettingsButtonTitle) {
      }
      
      Button(Strings.cancelButtonTitle) {
        
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
