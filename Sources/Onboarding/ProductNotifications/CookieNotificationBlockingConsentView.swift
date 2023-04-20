// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import DesignSystem
import BraveShared
import Growth
import BraveUI

public struct CookieNotificationBlockingConsentView: View {
  public static let contentHeight = 480.0
  public static let contentWidth = 344.0
  private static let gifHeight = 328.0
  private static let bottomSectionHeight = contentHeight - gifHeight
  private static let textPadding = 16.0
  
  private let animation = Animation.easeOut(duration: 0.5).delay(0)
  private let transition = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
  
  @Environment(\.presentationMode) @Binding private var presentationMode
  @State private var showAnimation = false
  
  public var onYesButtonPressed: (() -> Void)?

  private var yesButton: some View {
    
    Button(Strings.yesBlockCookieConsentNotices,
      action: {
        withAnimation(animation) {
          self.showAnimation = true
        }
      
        Task { @MainActor in
          recordCookieListPromptP3A(answer: .tappedYes)
          onYesButtonPressed?()
          self.dismiss()
        }
      }
    )
    .buttonStyle(BraveFilledButtonStyle(size: .large))
    .multilineTextAlignment(.center)
    .transition(transition)
  }
  
  private var noButton: some View {
    Button(Strings.noThanks) {
      recordCookieListPromptP3A(answer: .tappedNoThanks)
      self.dismiss()
    }
    .font(Font.body.weight(.semibold))
    .foregroundColor(.accentColor)
    .multilineTextAlignment(.center)
    .transition(transition)
  }
  
  public var body: some View {
    ScrollView {
      VStack {
        VStack {
          if !showAnimation {
            VStack(spacing: Self.textPadding) {
              Text(Strings.blockCookieConsentNoticesPopupTitle).font(.title)
              Text(Strings.blockCookieConsentNoticesPopupDescription).font(.body)
            }
            .transition(transition)
            .padding(Self.textPadding)
            .padding(.top, 80)
            .foregroundColor(Color(UIColor.braveLabel))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
          }
        }
        .frame(width: Self.contentWidth)
        .frame(minHeight: Self.gifHeight)
        .background(
          GIFImage(asset: "cookie-consent-animation", animate: showAnimation)
            .frame(width: Self.contentWidth, height: Self.gifHeight, alignment: .top),
          alignment: .top
        )
        
        VStack(spacing: Self.textPadding) {
          if !showAnimation {
            yesButton
            noButton
          }
        }
        .padding(Self.textPadding)
      }
    }
    .frame(width: Self.contentWidth, height: Self.contentHeight)
    .background(
      Image("cookie-consent-background", bundle: .module),
      alignment: .bottomLeading
    )
    .background(Color(UIColor.braveBackground))
    .onAppear {
      recordCookieListPromptP3A(answer: .seen)
    }
  }
  
  private func dismiss() {
    presentationMode.dismiss()
  }
  
  private enum P3AAnswer: Int, CaseIterable {
    case notSeen = 0
    case seen = 1
    case tappedNoThanks = 2
    case tappedYes = 3
  }
  
  private func recordCookieListPromptP3A(answer: P3AAnswer) {
    // Q68 If you have viewed the cookie consent block prompt, how did you react?
    UmaHistogramEnumeration("Brave.Shields.CookieListPrompt", sample: answer)
  }
}

#if DEBUG
struct CookieNotificationBlockingConsentView_Previews: PreviewProvider {
  static var previews: some View {
    CookieNotificationBlockingConsentView()
  }
}
#endif

public class CookieNotificationBlockingConsentViewController: UIHostingController<CookieNotificationBlockingConsentView>, PopoverContentComponent {
  public init() {
    super.init(rootView: CookieNotificationBlockingConsentView())
    
    self.preferredContentSize = CGSize(
      width: CookieNotificationBlockingConsentView.contentWidth,
      height: CookieNotificationBlockingConsentView.contentHeight
    )
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.braveBackground
  }
}

extension Task where Success == Never, Failure == Never {
  public static func sleep(seconds: TimeInterval) async throws {
    try await sleep(nanoseconds: NSEC_PER_MSEC * UInt64(seconds * 1000))
  }
}
