/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIStackView {
  /// The possible items in a stack view
  public enum StackViewItem {
    /// Place a view in the stack view
    case view(UIView)
    /// Set a custom space after the last item in the stack view
    case customSpace(CGFloat)
  }
  /// Adds a set of stack view items to make static UI creation a bit easier
  public func addStackViewItems(_ items: StackViewItem...) {
    items.forEach {
      switch $0 {
      case .view(let view):
        addArrangedSubview(view)
      case .customSpace(let space):
        guard let lastSubview = arrangedSubviews.last else {
          assertionFailure("Cannot have a space as the first item.")
          return
        }
        setCustomSpacing(space, after: lastSubview)
      }
    }
  }
  // Adds Background StackView with Color and Corner Radius
  public func addBackground(color: UIColor, cornerRadius: CGFloat? = nil) {
    let subView = UIView(frame: bounds)
    subView.backgroundColor = color
    subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    if let radius = cornerRadius {
      subView.layer.cornerRadius = radius
    }
    insertSubview(subView, at: 0)
  }
}
