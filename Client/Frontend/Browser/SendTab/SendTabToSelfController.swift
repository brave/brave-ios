/* Copyright 2022 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import BraveUI
import DesignSystem
import UIKit

public class SendTabToSelfController: UIViewController {
  private let contentController: UIViewController

  private let backgroundView = UIView().then {
    $0.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
  }
  
  public init() {
    
    // TODO: Random Controller or view
    contentController = UIViewController()
    contentController.view = UIView()
    
    super.init(nibName: nil, bundle: nil)
    transitioningDelegate = self
    modalPresentationStyle = .overFullScreen
    addChild(contentController)
    contentController.didMove(toParent: self)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear

    view.addSubview(backgroundView)
    view.addSubview(contentController.view)

    backgroundView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    contentController.view.snp.makeConstraints {
      $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
      $0.centerX.centerY.equalToSuperview()
      $0.height.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(20)
    }
  }

  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
}

// MARK: BasicAnimationControllerDelegate

extension SendTabToSelfController: BasicAnimationControllerDelegate {
  public func animatePresentation(context: UIViewControllerContextTransitioning) {
    context.containerView.addSubview(view)

    backgroundView.alpha = 0.0
    contentController.view.transform = CGAffineTransform(translationX: 0, y: context.containerView.bounds.height)

    UIViewPropertyAnimator(duration: 0.35, dampingRatio: 1.0) { [self] in
      backgroundView.alpha = 1.0
      contentController.view.transform = .identity
    }.startAnimation()

    context.completeTransition(true)
  }

  public func animateDismissal(context: UIViewControllerContextTransitioning) {
    let animator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1.0) { [self] in
      backgroundView.alpha = 0.0
      contentController.view.transform = CGAffineTransform(translationX: 0, y: context.containerView.bounds.height)
    }
    animator.addCompletion { _ in
      self.view.removeFromSuperview()
      context.completeTransition(true)
    }
    animator.startAnimation()
  }
}

// MARK: UIViewControllerTransitioningDelegate

extension SendTabToSelfController: UIViewControllerTransitioningDelegate {
  public func animationController(
    forPresented presented: UIViewController,
    presenting: UIViewController,
    source: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    return BasicAnimationController(delegate: self, direction: .presenting)
  }

  public func animationController(
    forDismissed dismissed: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    return BasicAnimationController(delegate: self, direction: .dismissing)
  }
}
