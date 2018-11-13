/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Deferred

@available(iOS 11, *)
extension ContentBlockerHelper: TabContentScript {
    class func name() -> String {
        return "TrackingProtectionStats"
    }

    func scriptMessageHandlerName() -> String? {
        return "trackingProtectionStats"
    }

    func clearPageStats() {
        stats = TPPageStats()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard isEnabled,
            let body = message.body as? [String: String],
            let urlString = body["url"],
            let mainDocumentUrl = tab?.webView?.url else {
            return
        }
        
        // TODO: 161, if domain is "all_off", can just skip
        
        guard var components = URLComponents(string: urlString) else { return }
        components.scheme = "http"
        guard let url = components.url else { return }

        TPStatsBlocklistChecker.shared.isBlocked(url: url).uponQueue(.main) { listItem in
            if let listItem = listItem {
                self.stats = self.stats.create(byAddingListItem: listItem)
            }
        }
    }
}
