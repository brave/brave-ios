// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI

struct PrivacyEverywhereView: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    //action
                } label: {
                    Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-exit-icon"))
                }
            }
            Text("Privacy. Everywhere.")
            Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-image"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .layoutPriority(1)
            Text("Get Brave privacy on your computer or tablet, and sync bookmarks & extensions between devices.")
                .multilineTextAlignment(.center)
            Button(action: {
                //Action
            }) {
                Text("Sync now")
                    .frame(maxWidth: .infinity)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white)
                    .padding()
            }
            .buttonStyle(BraveFilledButtonStyle(size: .small))
            .foregroundColor(Color(UIColor.braveBlurple))
        }.padding(.all)
            .frame(width: 390)
            .background(Color.white)
            .cornerRadius(20.0)
    }
}

struct PrivacyEverywhereView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyEverywhereView()
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}
