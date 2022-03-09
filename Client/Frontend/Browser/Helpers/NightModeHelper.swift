// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import WebKit
import Shared

class NightModeHelper: TabContentScript {
    fileprivate weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
    }

    static func name() -> String {
        return "NightMode"
    }

    func scriptMessageHandlerName() -> String? {
        return "NightMode"
    }

    func userContentController(
        _ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Do nothing.
    }

    static func toggle(tabManager: TabManager) {

    }
 
    static func setNightMode(tabManager: TabManager, enabled: Bool) {
        for tab in tabManager.allTabs {
            tab.nightMode = enabled
            tab.webView?.scrollView.indicatorStyle = enabled ? .white : .default
        }
    }

    static func setEnabledDarkTheme(darkTheme enabled: Bool) {
    }

    static func hasEnabledDarkTheme() -> Bool {
        return true
    }

    static func isActivated() -> Bool {
        return true
    }
}
