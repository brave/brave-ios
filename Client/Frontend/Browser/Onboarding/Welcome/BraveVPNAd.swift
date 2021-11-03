// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct BraveVPNAd: View {
    var body: some View {
        VStack {
            Image(uiImage: #imageLiteral(resourceName: "brave-vpn-ad-top-shimmer"))
            HStack {
                Spacer()
                Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-exit-icon"))
            }.offset(y: 10.0)
            Text("Brave new releases")
            Image(uiImage: #imageLiteral(resourceName: "brave-vpn-ad-background"))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(imageOverlay, alignment: .center)
            
            VStack {
                Text("• One line of release notes\n• Another line of release notes")
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }.padding()
         .frame(width: 374.0)
    }
    
    private var imageOverlay: some View {
        VStack {
            HStack {
                Text("Firewall")
                    .font(Font(UIFont.systemFont(ofSize: 27.0, weight: .bold)))
                    .rotationEffect(Angle(degrees: -9.57), anchor: .bottomLeading)
                    .foregroundColor(Color.white)
                
                Text("+")
                    .font(Font(UIFont.systemFont(ofSize: 35.0, weight: .bold)))
                    .foregroundColor(Color.white)
                    .offset(y: -15.0)
            }.offset(x: -20.0, y: 10.0)
            
            Text("VPN")
                .foregroundColor(Color.white)
                .font(Font(UIFont.systemFont(ofSize: 56.0, weight: .bold)))
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 12.0)
                            .stroke(Color.white, lineWidth: 9.5)
                )
                .offset(y: -15.0)
        }
    }
}

struct BraveVPNAd_Previews: PreviewProvider {
    static var previews: some View {
        BraveVPNAd()
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}
