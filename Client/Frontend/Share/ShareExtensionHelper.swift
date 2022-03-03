/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

/// A helper class that aids in the creation of share sheets
class ShareExtensionHelper {
    typealias CompletionHandler = (_ completed: Bool, _ activityType: UIActivity.ActivityType?, _ documentURL: URL?) -> Void

    /// Create a activity view controller with the given elements.
    /// - Parameters:
    ///   - selectedURL: The url or url content to share. May include an internal file or a link
    ///   - selectedTab: The provided tab is used for additional info such as a print renderer and title
    ///   - applicationActivities: The application activities to include in this share sheet.
    ///   - completionHandler: This will be triggered once the share sheet is dismissed and can be used to cleanup any lingering data
    /// - Returns: An `UIActivityViewController` prepped and ready to present.
    static func makeActivityViewController(
        selectedURL: URL,
        selectedTab: Tab? = nil,
        applicationActivities: [UIActivity] = [],
        completionHandler: @escaping CompletionHandler
    ) -> UIActivityViewController {
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = selectedURL.absoluteString
        printInfo.outputType = .general

        var activityItems: [Any] = [
            printInfo, selectedURL
        ]

        if let tab = selectedTab {
            // Adds the ability to "Print" or "Markup" the page using this custom renderer
            // Without this, the "Print" or "Markup feature would not exist"
            activityItems.append(TabPrintPageRenderer(tab: tab))
        }

        if let title = selectedTab?.title {
            // Makes sure the share sheet shows the same title as the tab
            // Also adds a title to several places, such as the Subject field in Mail
            activityItems.append(TitleActivityItemProvider(title: title))
        }

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)

        // Hide 'Add to Reading List' which currently uses Safari.
        // We would also hide View Later, if possible, but the exclusion list doesn't currently support
        // third-party activity types (rdar://19430419).
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.addToReadingList,
        ]

        activityViewController.completionWithItemsHandler = { [weak selectedTab] activityType, completed, returnedItems, activityError in
            if let activityType = activityType, activityType == .openInIBooks, let selectedTab = selectedTab {
                // TODO: @JS Investigate why this is needed.
                // Is it for Fix #2961? Fix sharing to iBooks
                // (note: Could not test this as I could not trigger this scenario)
                // #2961 steps don't use `openInIBooks`. Perhaps that's an os change?
                Self.writeWebPagePDFDataToURL(selectedTab: selectedTab) { url, error in
                    completionHandler(completed, activityType, url)
                }
            } else {
                completionHandler(completed, activityType, nil)
            }
        }
        
        return activityViewController
    }

    // TODO: @JS Figure of if this is ever used
    /// Function that writes the current webpage data to a PDF
    private static func writeWebPagePDFDataToURL(selectedTab: Tab, completion: @escaping (URL?, Error?) -> Void) {
        #if compiler(>=5.3)
        if let webView = selectedTab.webView, selectedTab.temporaryDocument == nil {
            
            webView.createPDF { result in
                dispatchPrecondition(condition: .onQueue(.main))
                
                switch result {
                case .success(let data):
                    let validFilenameSet = CharacterSet(charactersIn: ":/")
                        .union(.newlines)
                        .union(.controlCharacters)
                        .union(.illegalCharacters)
                    let filename = webView.title?.components(separatedBy: validFilenameSet).joined()

                    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename ?? "Untitled").pdf")
                    
                    do {
                        try data.write(to: url)
                        completion(url, nil)
                    } catch {
                        completion(nil, error)
                        Logger.browserLogger.error("Failed to write PDF to disk: \(error)")
                    }
                case .failure(let error):
                    completion(nil, error)
                    Logger.browserLogger.error("Failed to write PDF to disk: \(error)")
                }
            }
        }
        #endif
    }
}
