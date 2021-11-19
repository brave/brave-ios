// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveUI
import BraveShared

struct PrivacyEverywhereView: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    var dismiss: (() -> Void)?
    var syncNow: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    dismiss?()
                } label: {
                    Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-exit-icon"))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            VStack(spacing: 10) {
                Text(Strings.Callout.privacyEverywhereCalloutTitle)
                    .font(.title3.weight(.medium))
                    .foregroundColor(Color(.bravePrimary))
                Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-image"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text(Strings.Callout.privacyEverywhereCalloutDescription)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(.bravePrimary))
            }
            Button(action: {
                syncNow?()
            }) {
                Text(Strings.Callout.privacyEverywhereCalloutPrimaryButtonTitle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(.title3.weight(.medium))
                    .padding()
            }
            .frame(height: 44)
            .background(Color(.braveBlurple))
            .accentColor(Color(.white))
            .clipShape(Capsule())
        }
        .frame(maxWidth: BraveUX.baseDimensionValue)
        .padding()
        .background(Color(.braveBackground))
        .cornerRadius(16)
        .accessibilityEmbedInScrollView()
    }
}

struct PrivacyEverywhereView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Rectangle()
                    .foregroundColor(.black)
                    .edgesIgnoringSafeArea(.all)
                PrivacyEverywhereView()
            }
            .previewDevice("iPhone 12 Pro")
            
            ZStack {
                Rectangle()
                    .foregroundColor(.black)
                    .edgesIgnoringSafeArea(.all)
                PrivacyEverywhereView()
            }
            .previewDevice("iPad Pro (9.7-inch)")
        }
    }
}
