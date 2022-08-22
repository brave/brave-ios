// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveShared
import BraveUI
import DesignSystem

struct PlaylistFolderSharingManagementView: View {
  private struct UX {
    static let hPadding = 20.0
    static let vPadding = 20.0
  }
  
  var onAddToPlaylistPressed: (() -> Void)?
  var onSettingsPressed: (() -> Void)?
  var onCancelPressed: (() -> Void)?
  
  var body: some View {
    ScrollView(.vertical) {
      VStack {
        Text(Strings.PlaylistFolderSharing.offlineManagementViewTitle)
          .font(.title2.weight(.medium))
          .multilineTextAlignment(.center)
          .foregroundColor(Color(.bravePrimary))
          .padding(.horizontal, UX.hPadding)
          .padding(.bottom, UX.vPadding)
        
        Text(Strings.PlaylistFolderSharing.offlineManagementViewDescription)
          .font(.body)
          .foregroundColor(Color(.braveLabel))
          .padding(.horizontal, UX.hPadding)
          .padding(.bottom, UX.vPadding)
        
        VStack(spacing: UX.vPadding) {
          Button(action: {
            onAddToPlaylistPressed?()
          }) {
            Text(Strings.PlaylistFolderSharing.offlineManagementViewAddButtonTitle)
              .frame(maxWidth: .infinity)
              .font(.callout.weight(.medium))
              .padding()
          }
          .frame(minHeight: 44.0)
          .background(Color(.braveBlurple))
          .clipShape(Capsule())
          
          Button(action: {
            onSettingsPressed?()
          }) {
            Text(Strings.PlaylistFolderSharing.offlineManagementViewSettingsButtonTitle)
              .frame(maxWidth: .infinity)
              .font(.callout.weight(.medium))
              .padding()
          }
          .frame(minHeight: 44.0)
          .background(Color(.braveBlurple))
          .clipShape(Capsule())
          
          Button(action: {
            onCancelPressed?()
          }) {
            Text(Strings.cancelButtonTitle)
              .frame(maxWidth: .infinity)
              .font(.callout.weight(.medium))
              .padding()
          }
          .frame(minHeight: 44.0)
          .foregroundColor(Color(.braveLighterBlurple))
          .clipShape(Capsule())
        }
        .padding(.horizontal, UX.hPadding)
      }
      .accentColor(Color(.white))
      .padding(EdgeInsets(top: UX.vPadding, leading: UX.hPadding, bottom: UX.vPadding, trailing: UX.hPadding))
      .background(Color(.braveBackground))
    }
    .environment(\.colorScheme, .dark)
  }
}

#if DEBUG
struct PlaylistFolderSharingManagementView_Previews: PreviewProvider {
  static var previews: some View {
    PlaylistFolderSharingManagementView(onAddToPlaylistPressed: nil,
                                        onSettingsPressed: nil,
                                        onCancelPressed: nil)
  }
}
#endif
