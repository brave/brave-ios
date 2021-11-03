// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
//import Lottie
//
//enum WelcomeViewState {
//    case welcome
//    case privacySimplified
//    case defaultBrowser
//    case setDefaultBrowser
//}
//
//struct WelcomeView: View {
//    var body: some View {
//        VStack(alignment: .center) {
//            Image(uiImage: #imageLiteral(resourceName: "Launch_Leaves_Top"))
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .frame(maxWidth: .infinity)
//            Spacer(minLength: 20.0)
//            
//            ZStack(alignment: .center) {
//                WelcomViewCallout()
//                    .offset(x: 0.0, y: -30.0)
//
//                Image(uiImage: #imageLiteral(resourceName: "welcome-view-icon"))
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .offset(x: 0.0, y: 130.0)
//            }.frame(maxWidth: .infinity)
//            
//            Spacer(minLength: 20.0)
//            Image(uiImage: #imageLiteral(resourceName: "Launch_Leaves_Bottom"))
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .frame(maxWidth: .infinity)
//        }
//        .edgesIgnoringSafeArea(.all)
//        .background(
//            Image(uiImage: #imageLiteral(resourceName: "LaunchBackground"))
//            .resizable()
//            .aspectRatio(contentMode: .fill)
//        )
//        .frame(maxWidth: .infinity,
//               maxHeight: .infinity,
//               alignment: .center)
//    }
//}
//
//private struct WelcomViewCallout: View {
//    var body: some View {
//        VStack(alignment: .center, spacing: 0.0) {
//            Text("Welcome to Brave!")
//                .font(.title)
//            .padding(.all, 30.0)
//            .background(Color.white)
//            .cornerRadius(16.0)
//            
//            CalloutArrow()
//            .rotation(.degrees(180.0))
//            .fill(Color.white)
//            .frame(width: 20.6, height: 10.0)
//        }
//    }
//}
//
//private struct CalloutArrow: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        
//        // Middle Top
//        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
//        
//        // Bottom Left
//        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
//        
//        // Bottom Right
//        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
//        
//        // Middle Top
//        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
//        return path
//    }
//}
//
//struct WelcomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            WelcomeView()
//            WelcomeView()
//                .previewDevice("iPad Pro (12.9-inch) (5th generation)")
//        }
//    }
//}
