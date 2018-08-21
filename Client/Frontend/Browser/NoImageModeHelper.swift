/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared

struct NoImageModePrefsKey {
    static let NoImageModeStatus = PrefsKeys.KeyNoImageModeStatus
}

class NoImageModeHelper: TabContentScript {
    fileprivate weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
    }

    static func name() -> String {
        return "NoImageMode"
    }

    func scriptMessageHandlerName() -> String? {
        return "NoImageMode"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Do nothing.
    }

    static var isActivated: Bool {
        return Preferences.Shields.blockImages.value
    }
}
