// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import BraveUI
import DesignSystem
import Strings
import Preferences
import BraveShields
import SnapKit
import Data

public struct AntiAdBlockWarningView: View {
  public typealias DismissCallback = (Bool) -> Void
  
  let url: URL
  let dismiss: DismissCallback
  
  private var playerDescription: AttributedString? {
    do {
      return try AttributedString(markdown: Strings.Shields.antiAdBlockWarningBravePlayerDescription)
    } catch {
      assertionFailure()
      return nil
    }
  }
  
  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text(Strings.Shields.antiAdBlockWarningTitle)
          .font(.headline).foregroundStyle(Color(braveSystemName: .textPrimary))
        Text(Strings.Shields.antiAdBlockWarningDescription)
        Text(Strings.Shields.antiAdBlockWarningDescription2)
        
        if let playerDescription = playerDescription {
          VStack(spacing: 0) {
            Image("youtube_warning_address_bar", bundle: .module)
            Text(playerDescription)
              .multilineTextAlignment(.center)
              .font(.caption)
              .padding()
              .frame(maxWidth: .infinity, alignment: .center)
          }
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color(braveSystemName: .gray20), lineWidth: 1)
          )
        }
        
        VStack(alignment: .center) {
          Button {
            ShieldPreferences.hasSeenAntiAdBlockWarning.value = true
            Domain.setBraveShield(forUrl: url, shield: .AllOff, isOn: true, isPrivateBrowsing: false)
            dismiss(true)
          } label: {
            Text(Strings.Shields.antiAdBlockWarningConfirmationButton)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(4)
          }
          .buttonStyle(BraveFilledButtonStyle(size: .normal))
          
          Button {
            ShieldPreferences.hasSeenAntiAdBlockWarning.value = true
            dismiss(false)
          } label: {
            Text(Strings.Shields.antiAdBlockWarningDismissButton)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(4)
          }
          .buttonStyle(BravePlainButtonStyle(size: .normal))
        }
      }
      .foregroundStyle(Color(braveSystemName: .textSecondary))
      .background(Color(.braveBackground))
      .padding(24)
    }
  }
}

#if swift(>=5.9)
#Preview {
  AntiAdBlockWarningView(
    url: URL(string: "https://youtube.com")!,
    dismiss: { _ in }
  )
}
#endif

public class AntiAdBlockWarningViewController: UIViewController, PopoverContentComponent {
  private lazy var hostingController: UIHostingController<AntiAdBlockWarningView> = {
    return UIHostingController(rootView: AntiAdBlockWarningView(url: url, dismiss: { [weak self] needsReload in
      self?.dismissCallback?(needsReload)
    }))
  }()
  
  private let url: URL
  public var dismissCallback: ((Bool) -> Void)?
  
  public init(url: URL) {
    self.url = url
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    hostingController.willMove(toParent: self)
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)

    hostingController.view.snp.makeConstraints {
      $0.edges.equalTo(view.safeAreaLayoutGuide)
    }
    
    updatePreferredContentSize()
  }
  
  private func updatePreferredContentSize() {
    let width = min(360, UIScreen.main.bounds.width - 20)
    // Ensure the a static width is given to the main view so we can calculate the height
    // correctly when we force a layout
    let height = view.systemLayoutSizeFitting(
      CGSize(width: width, height: 0),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).height

    preferredContentSize = CGSize(
      width: width,
      height: height
    )
  }
}
