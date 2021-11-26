// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveUI
import BraveShared

struct ReleaseNotesView: View {
    var dismiss: (() -> Void)?
    var actionTest: (() -> Void)?
    
    var body: some View {
        VStack {
            Image(uiImage: #imageLiteral(resourceName: "brave-vpn-ad-top-shimmer"))
                .resizable()
                .aspectRatio(contentMode: .fit)
            VStack {
                Button {
                    dismiss?()
                } label: {
                    Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-exit-icon"))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
     
                Text("Brave new releases")
                    .font(.title3.weight(.medium))
                    .foregroundColor(Color(.bravePrimary))
                Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-image"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("• One line of release notes")
                    Text("• Another line of release notes")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                Button(action: {
                    actionTest?()
                }) {
                    Text("Action Button")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .font(.title3.weight(.medium))
                        .padding()
                }
                .frame(height: 44)
                .background(Color(.braveBlurple))
                .accentColor(Color(.white))
                .clipShape(Capsule())
            }
            .padding()
        }
        .frame(maxWidth: BraveUX.baseDimensionValue)
        .background(Color(.braveBackground))
        .accessibilityEmbedInScrollView()
    }
}

struct ReleaseNotesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Group {
                BraveUI.PopupView {
                    ReleaseNotesView()
                }
                .previewDevice("iPhone 12 Pro")
                
                BraveUI.PopupView {
                    ReleaseNotesView()
                }
                .previewDevice("iPad Pro (9.7-inch)")
            }
        }
    }
}

