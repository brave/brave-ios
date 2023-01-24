// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI

struct WebStoreInstallUI: View {
  let title: String
  let author: String
  let iconURL: String
  let permissions: [String]
  
  var onCancel: (() -> Void)?
  var onInstall: (() -> Void)?
  
  var body: some View {
    VStack(spacing: 0.0) {
      HStack(alignment: .top, spacing: 20.0) {
        if !iconURL.isEmpty, let url = URL(string: iconURL) {
          AsyncImage(url: url) { image in
            image
              .resizable()
          } placeholder: {
            ProgressView()
          }
          .aspectRatio(contentMode: .fit)
          .frame(width: 64.0, height: 64.0, alignment: .center)
        } else {
          Image(systemName: "photo")
        }
        
        VStack(alignment: .leading) {
          Text("**Extension:** \(title)")
          Text("**Author:** \(author)")
          
          if !permissions.isEmpty {
            Text("**Permissions:**")
            
            ForEach(permissions, id: \.self) { permission in
              Text("* \(permission)")
                .padding(.horizontal)
            }
          }
        }
        Spacer()
      }
      .padding()
      
      Divider()
      
      HStack(spacing: 0.0) {
        Button(action: {
          onCancel?()
        }) {
          Text("Cancel")
            .font(.system(.body))
            .foregroundColor(Color(.braveLabel))
            .padding()
            .frame(maxWidth: .infinity)
        }
        
        Divider()
        
        Button(action: {
          onInstall?()
        }) {
          Text("Install")
            .font(.system(.body))
            .foregroundColor(Color(.braveLabel))
            .padding()
            .frame(maxWidth: .infinity)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
    }
    .background(Color(UIColor.secondaryBraveBackground))
    .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
  }
}

#if DEBUG
struct WebStoreInstallUI_Previews: PreviewProvider {
  static var previews: some View {
    WebStoreInstallUI(title: "Brave Shields",
                      author: "Brave Inc.",
                      iconURL: "https://brave.com/static-assets/images/cropped-brave_appicon_release-192x192.png",
                      permissions: ["Network", "Tabs", "Background"])
      .previewLayout(.sizeThatFits)
  }
}
#endif
