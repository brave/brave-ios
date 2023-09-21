// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import BraveUI
import DesignSystem
import SnapKit

struct SubmitReportSuccessView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text(Strings.Shields.siteReportedTitle)
        .multilineTextAlignment(.leading)
        .lineLimit(1)
        .font(.title)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
      Text(Strings.Shields.siteReportedBody)
        .multilineTextAlignment(.leading)
        .lineLimit(3)
        .foregroundStyle(Color(braveSystemName: .textTertiary))
    }
    .padding()
    .background(Color(.braveBackground))
  }
}

#if swift(>=5.9)
#Preview {
  SubmitReportSuccessView()
}
#endif

class SubmitReportSuccessViewController: UIViewController, PopoverContentComponent {
  private lazy var hostingController: UIHostingController<SubmitReportSuccessView> = {
    return UIHostingController(rootView: SubmitReportSuccessView())
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let swiftUIView = hostingController.view {
      swiftUIView.translatesAutoresizingMaskIntoConstraints = false
      addChild(hostingController)
      view.addSubview(swiftUIView)
      
      swiftUIView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
      
      hostingController.didMove(toParent: self)
      updatePreferredContentSize()
    }
  }
  
  private func updatePreferredContentSize() {
    let targetWidth = min(360, UIScreen.main.bounds.width - 20)
    
    let height = self.view.systemLayoutSizeFitting(
      CGSize(width: targetWidth, height: 0),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    ).height

    preferredContentSize = CGSize(
      width: targetWidth,
      height: height
    )
  }
}
