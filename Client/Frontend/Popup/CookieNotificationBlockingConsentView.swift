// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import DesignSystem
import BraveShared

struct CookieNotificationBlockingConsentView: View {
  public static let contentHeight: CGFloat = 480
  private static let topSectionHeight: CGFloat = 328
  private static let bottomSectionHeight = contentHeight - topSectionHeight
  
  private let animation = Animation.easeOut(duration: 0.5).delay(0)
  private let transition = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
  private let textPadding: CGFloat = 16
  
  @Environment(\.presentationMode) var presentationMode
  @State private var showAnimation = false
  
  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        ZStack {
          GIFImage(asset: "cookie-consent-animation", animate: showAnimation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
        if !showAnimation {
          VStack(alignment: .center, spacing: textPadding) {
            Text(Strings.blockCookieConsentNoticesPopupTitle)
              .font(.title)
              .foregroundColor(Color(UIColor.braveLabel))
              .multilineTextAlignment(.center)
              .transition(transition)
              .padding(.horizontal, textPadding)
            Text(Strings.blockCookieConsentNoticesPopupDescription)
              .font(.body)
              .foregroundColor(Color(UIColor.braveLabel))
              .multilineTextAlignment(.center)
              .transition(transition)
              .padding(.horizontal, textPadding)
          }
          .padding(.top, 80)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
      }
      .frame(height: Self.topSectionHeight, alignment: Alignment.center)
      
      VStack(alignment: .center, spacing: textPadding) {
        if !showAnimation {
          Button(Strings.yesBlockCookieConsentNotices) {
            withAnimation(animation) {
              self.showAnimation = true
            }

            if !FilterListResourceDownloader.shared.enableFilterList(forFilterListUUID: FilterListResourceDownloader.cookieConsentNoticesUUID, isEnabled: true) {
              assertionFailure("This filter list should exist or this UI is completely useless")
            }
            
            Task {
              try await Task.sleep(seconds: 3.5)
              self.presentationMode.wrappedValue.dismiss()
            }
          }
          .buttonStyle(BraveFilledButtonStyle(size: .large))
          .multilineTextAlignment(.center)
          .transition(transition)
          .padding(.horizontal, textPadding)

          Button(Strings.noThanks) {
            self.presentationMode.wrappedValue.dismiss()
          }
          .font(Font.body.weight(.semibold))
          .foregroundColor(.accentColor)
          .multilineTextAlignment(.center)
          .transition(transition)
          .padding(.horizontal, textPadding)
        }
      }
      .frame(height: Self.bottomSectionHeight, alignment: .center)
    }
    .background(
      Image("cookie-consent-background", bundle: .module),
      alignment: .bottomLeading
    )
    .background(Color(UIColor.braveBackground))
    .padding(0)
  }
}

#if DEBUG
struct CookieNotificationBlockingConsentView_Previews: PreviewProvider {
  static var previews: some View {
    CookieNotificationBlockingConsentView()
  }
}
#endif
