// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI

struct PrivacyEverywhereView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
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
            Text("Privacy. Everywhere.")
                .padding(.vertical, 5)
                .font(.title3.weight(.medium))
                .foregroundColor(Color(.bravePrimary))
            Image(uiImage: #imageLiteral(resourceName: "privacy-everywhere-image"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.vertical, 5)
            Text("Get Brave privacy on your computer or tablet, and sync bookmarks & extensions between devices.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(Color(.bravePrimary))
                .padding(.vertical, 5)
            Button(action: {
                syncNow?()
            }) {
                Text("Sync now")
                    .frame(maxWidth: .infinity)
                    .font(.title3.weight(.medium))
                    .padding()
            }
            .buttonStyle(BraveFilledButtonStyle(size: .small))
            .foregroundColor(Color(.braveBlurple))
        }
        .frame(maxWidth: 450)
        .padding(.all)
        .background(Color(.braveBackground))
        .cornerRadius(20.0)
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

class PrivacyEverywhereController: UIHostingController<PrivacyEverywhereView> & PopupContentComponent {
    
    init() {
        super.init(rootView: PrivacyEverywhereView())
        view.backgroundColor = .clear
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
