//
//  SwiftUIView.swift
//  
//
//  Created by Jacob on 2023-10-26.
//

import SwiftUI
import BraveUI
import DesignSystem
import Strings
import Preferences
import BraveShields
import SnapKit

struct BravePlayerInfoView: View {
  public typealias DismissCallback = (Bool) -> Void
  
  let dismiss: DismissCallback
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(Strings.Shields.bravePlayerInfoTitle)
          .font(.headline).foregroundStyle(Color(braveSystemName: .textPrimary))
        Text(Strings.Shields.bravePlayerInfoMessage)
        
        HStack {
          Spacer()
          
          Button {
            dismiss(false)
          } label: {
            Text(Strings.Shields.bravePlayerDismissButton)
              .multilineTextAlignment(.center)
          }
          .buttonStyle(BravePlainButtonStyle(size: .normal))
          
          Button {
            dismiss(true)
          } label: {
            Text(Strings.Shields.bravePlayerConfirmButton)
              .multilineTextAlignment(.center)
          }
          .buttonStyle(BraveFilledButtonStyle(size: .normal))
        }.frame(maxWidth: .infinity, alignment: .trailing)
      }
      .foregroundStyle(Color(braveSystemName: .textSecondary))
      .background(Color(.braveBackground))
      .padding(16)
    }
  }
}

#if swift(>=5.9)
#Preview {
  BravePlayerInfoView(dismiss: { _ in })
}
#endif

public class BravePlayerInfoViewController: UIViewController, PopoverContentComponent {
  private lazy var hostingController: UIHostingController<BravePlayerInfoView> = {
    return UIHostingController(rootView: BravePlayerInfoView(dismiss: { [weak self] needsReload in
      self?.dismissCallback?(needsReload)
    }))
  }()
  
  public var dismissCallback: ((Bool) -> Void)?
  
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
    let width = min(280, UIScreen.main.bounds.width - 20)
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
