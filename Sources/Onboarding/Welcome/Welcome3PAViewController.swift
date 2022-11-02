// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveUI
import BraveCore

public class Welcome3PAViewController: UIViewController {
  
  private let backgroundView = UIView()
  private let calloutView = WelcomeViewCallout()

  private let p3aUtilities: BraveP3AUtils

  public init(p3aUtilities: BraveP3AUtils) {
    self.p3aUtilities = p3aUtilities
    super.init(nibName: nil, bundle: nil)
    
    self.modalPresentationStyle = .fullScreen
    self.loadViewIfNeeded()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()

    let backgroundView = UIView().then {
      $0.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    }

    view.addSubview(backgroundView)
    backgroundView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    view.addSubview(calloutView)
    calloutView.snp.makeConstraints {
      
      $0.leading.trailing.equalToSuperview()
      
      $0.centerY.centerX.equalToSuperview()
      
//      $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
    }

  }
  
  public func setLayoutState(state: WelcomeViewCalloutState) {
    calloutView.setState(state: state)
  }
}


////    calloutView.do {
////      $0.setContentHuggingPriority(.init(rawValue: 5), for: .vertical)
////    }
//
//    let backgroundView = UIView().then {
//      $0.backgroundColor = UIColor.black.withAlphaComponent(0.3)
//    }
//
//    view.addSubview(backgroundView)
//    backgroundView.snp.makeConstraints {
//      $0.edges.equalToSuperview()
//    }
//
//    view.addSubview(calloutView)
//    calloutView.snp.makeConstraints {
//      $0.leading.trailing.equalToSuperview()
//      $0.centerX.centerY.equalToSuperview()
//    }
//
////    let stack = UIStackView().then {
////      $0.distribution = .equalSpacing
////      $0.axis = .vertical
////      $0.setContentHuggingPriority(.init(rawValue: 5), for: .vertical)
////    }
////
////    view.addSubview(stack)
////    stack.snp.makeConstraints {
////      $0.leading.trailing.top.equalToSuperview()
////      $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
////    }
////
////    stack.addStackViewItems(
////      .view(UIView.spacer(.vertical, amount: 1)),
////      .view(calloutView),
////      .view(UIView.spacer(.vertical, amount: 1)))
//  }
