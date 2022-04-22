// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import Shared
import BraveShared

private let log = Logger.browserLogger

extension PrivacyReportsView {
  struct NotificationCalloutView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.sizeCategory) private var sizeCategory
    
    private func askForNotificationAuthorization() {
      let center = UNUserNotificationCenter.current()
      
      center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
          
          if let error = error {
            log.warning("requestAuthorization: \(error)")
            return
          }
          
        DispatchQueue.main.async {
          Preferences.PrivacyHub.shouldShowNotificationPermissionCallout.value = false
        }
      }
    }
    
    var closeButton: some View {
      Button(action: {
        Preferences.PrivacyHub.shouldShowNotificationPermissionCallout.value = false
      }, label: {
        Image(systemName: "xmark")
      })
      
    }
    
    private var enableNotificationsButton: some View {
      Button(action: askForNotificationAuthorization, label: {
        ZStack {
          VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
            .edgesIgnoringSafeArea(.all)
          
          Group {
            if sizeCategory.isAccessibilityCategory {
              Text(Strings.PrivacyHub.notificationCalloutButtonText)
            } else {
              Label(Strings.PrivacyHub.notificationCalloutButtonText, image: "brave.bell")
            }
          }
          .font(.callout)
          .padding(.vertical, 12)
        }
        .clipShape(Capsule())
        .fixedSize(horizontal: false, vertical: true)
      })
    }
    
    var body: some View {
      Group {
        VStack {
          if horizontalSizeClass == .compact
              || (horizontalSizeClass == .regular && sizeCategory.isAccessibilityCategory) {
            HStack(alignment: .top) {
              HStack {
                if !sizeCategory.isAccessibilityCategory {
                  Image(uiImage: .init(imageLiteralResourceName: "brave_document"))
                }
                Text(Strings.PrivacyHub.notificationCalloutBody)
                  .font(.headline)
                  .fixedSize(horizontal: false, vertical: true)
              }
              Spacer()
              closeButton
            }
            .frame(maxWidth: .infinity)
            
            enableNotificationsButton
              .frame(maxWidth: .infinity)
          } else {
            HStack {
              Spacer()
              closeButton
            }
            
            HStack(spacing: 24) {
              Image(uiImage: .init(imageLiteralResourceName: "brave_document"))
              Text(Strings.PrivacyHub.notificationCalloutBody)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
              Spacer()
              enableNotificationsButton
            }
            .padding()
            // Extra bottom padding to offset the close button we have in top right.
            .padding(.bottom)
          }
        }
        .padding()
        .foregroundColor(Color.white)
        .background(
          LinearGradient(braveGradient: .gradient05)
        )
        .clipShape(RoundedRectangle(
          cornerRadius: 12.0, style: .continuous)
        )
      }
    }
  }
}

#if DEBUG
struct NotificationCalloutView_Previews: PreviewProvider {
  static var previews: some View {
    PrivacyReportsView.NotificationCalloutView()
  }
}
#endif
