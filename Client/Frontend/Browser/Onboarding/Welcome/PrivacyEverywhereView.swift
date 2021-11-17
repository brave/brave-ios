// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveUI

struct PrivacyEverywhereView: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    var dismiss: (() -> Void)?
    var syncNow: (() -> Void)?

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    dismiss?()
                } label: {
                    Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-exit-icon"))
                }
            }
            Text(Strings.Callout.privacyEverywhereCalloutTitle)
                .padding(.vertical, 5)
                .font(.title3.weight(.medium))
                .foregroundColor(Color(.bravePrimary))
            Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-image"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.vertical, 5)
            Text(Strings.Callout.privacyEverywhereCalloutDescription)
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(Color(.bravePrimary))
                .padding(.vertical, 5)
            Button(action: {
                syncNow?()
            }) {
                Text(Strings.Callout.privacyEverywhereCalloutPrimaryButtonTitle)
                    .frame(maxWidth: .infinity)
                    .font(.title3.weight(.medium))
                    .padding()
            }
            .buttonStyle(BraveFilledButtonStyle(size: .small))
            .foregroundColor(Color(.braveBlurple))
        }
        .frame(maxWidth: 450)
        .padding()
        .background(Color(.braveBackground))
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
