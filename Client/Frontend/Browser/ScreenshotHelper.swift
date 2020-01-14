/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * Handles screenshots for a given tab, including pages with non-webview content.
 */
class ScreenshotHelper {
    var viewIsVisible = false

    fileprivate weak var controller: BrowserViewController?

    init(controller: BrowserViewController) {
        self.controller = controller
    }

    func takeScreenshot(_ tab: Tab) {
        var screenshot: UIImage?

        if let url = tab.url {
            if url.isAboutHomeURL {
                if let homePanel = controller?.favoritesViewController {
                    screenshot = homePanel.view.screenshot(quality: UIConstants.activeScreenshotQuality)
                }
            } else {
                let offset = CGPoint(x: 0, y: -(tab.webView?.scrollView.contentInset.top ?? 0))
                screenshot = tab.webView?.screenshot(offset: offset, quality: UIConstants.activeScreenshotQuality)
            }
        }

        tab.setScreenshot(screenshot)
    }

    /// Takes a screenshot after a small delay.
    /// Trying to take a screenshot immediately after didFinishNavigation results in a screenshot
    /// of the previous page, presumably due to an iOS bug. Adding a brief delay fixes this.
    func takeDelayedScreenshot(_ tab: Tab) {
        let time = DispatchTime.now() + Double(Int64(100 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            // If the view controller isn't visible, the screenshot will be blank.
            // Wait until the view controller is visible again to take the screenshot.
            guard self.viewIsVisible else {
                tab.pendingScreenshot = true
                return
            }

            self.takeScreenshot(tab)
        }
    }

    func takePendingScreenshots(_ tabs: [Tab]) {
        for tab in tabs where tab.pendingScreenshot {
            tab.pendingScreenshot = false
            takeDelayedScreenshot(tab)
        }
    }
}
