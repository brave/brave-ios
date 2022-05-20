// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared

@objcMembers
class ToolbarHelper: NSObject {
  let toolbar: ToolbarProtocol

  init(toolbar: ToolbarProtocol) {
    self.toolbar = toolbar
    super.init()

    toolbar.backButton.setImage(UIImage(named: "nav-back", in: .module, compatibleWith: nil)!.template, for: .normal)
    toolbar.backButton.accessibilityLabel = Strings.tabToolbarBackButtonAccessibilityLabel
    let longPressGestureBackButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressBack))
    toolbar.backButton.addGestureRecognizer(longPressGestureBackButton)
    toolbar.backButton.addTarget(self, action: #selector(didClickBack), for: .touchUpInside)

    toolbar.shareButton.setImage(UIImage(named: "nav-share", in: .module, compatibleWith: nil)!.template, for: .normal)
    toolbar.shareButton.accessibilityLabel = Strings.tabToolbarShareButtonAccessibilityLabel
    toolbar.shareButton.addTarget(self, action: #selector(didClickShare), for: UIControl.Event.touchUpInside)

    toolbar.tabsButton.addTarget(self, action: #selector(didClickTabs), for: .touchUpInside)

    toolbar.addTabButton.setImage(UIImage(named: "add_tab", in: .module, compatibleWith: nil)!.template, for: .normal)
    toolbar.addTabButton.accessibilityLabel = Strings.tabToolbarAddTabButtonAccessibilityLabel
    toolbar.addTabButton.addTarget(self, action: #selector(didClickAddTab), for: UIControl.Event.touchUpInside)

    toolbar.searchButton.setImage(UIImage(named: "ntp-search", in: .module, compatibleWith: nil)!.template, for: .normal)
    // Accessibility label not needed, since overriden in the bottom tool bar class.
    toolbar.searchButton.addTarget(self, action: #selector(didClickSearch), for: UIControl.Event.touchUpInside)

    toolbar.menuButton.setImage(UIImage(named: "menu_more", in: .module, compatibleWith: nil)!.template, for: .normal)
    toolbar.menuButton.accessibilityLabel = Strings.tabToolbarMenuButtonAccessibilityLabel
    toolbar.menuButton.addTarget(self, action: #selector(didClickMenu), for: UIControl.Event.touchUpInside)

    toolbar.forwardButton.setImage(UIImage(named: "nav-forward", in: .module, compatibleWith: nil)!.template, for: .normal)
    toolbar.forwardButton.accessibilityLabel = Strings.tabToolbarForwardButtonAccessibilityLabel
    let longPressGestureForwardButton = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressForward))
    toolbar.forwardButton.addGestureRecognizer(longPressGestureForwardButton)
    toolbar.forwardButton.addTarget(self, action: #selector(didClickForward), for: .touchUpInside)
  }

  func didClickMenu() {
    toolbar.tabToolbarDelegate?.tabToolbarDidPressMenu(toolbar)
  }

  func didClickBack() {
    toolbar.tabToolbarDelegate?.tabToolbarDidPressBack(toolbar, button: toolbar.backButton)
  }

  func didLongPressBack(_ recognizer: UILongPressGestureRecognizer) {
    if recognizer.state == .began {
      toolbar.tabToolbarDelegate?.tabToolbarDidLongPressBack(toolbar, button: toolbar.backButton)
    }
  }

  func didClickTabs() {
    toolbar.tabToolbarDelegate?.tabToolbarDidPressTabs(toolbar, button: toolbar.tabsButton)
  }

  func didClickForward() {
    toolbar.tabToolbarDelegate?.tabToolbarDidPressForward(toolbar, button: toolbar.forwardButton)
  }

  func didLongPressForward(_ recognizer: UILongPressGestureRecognizer) {
    if recognizer.state == .began {
      toolbar.tabToolbarDelegate?.tabToolbarDidLongPressForward(toolbar, button: toolbar.forwardButton)
    }
  }

  func didClickShare() {
    toolbar.tabToolbarDelegate?.tabToolbarDidPressShare()
  }

  func didClickAddTab() {
    toolbar.tabToolbarDelegate?.tabToolbarDidPressAddTab(toolbar, button: toolbar.shareButton)
  }

  func didClickSearch() {
    toolbar.tabToolbarDelegate?.tabToolbarDidPressSearch(toolbar, button: toolbar.searchButton)
  }
}
