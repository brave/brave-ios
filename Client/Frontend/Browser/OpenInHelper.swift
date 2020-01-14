/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MobileCoreServices
import PassKit
import WebKit
import Shared

struct MIMEType {
    static let bitmap = "image/bmp"
    static let CSS = "text/css"
    static let GIF = "image/gif"
    static let javaScript = "text/javascript"
    static let JPEG = "image/jpeg"
    static let HTML = "text/html"
    static let octetStream = "application/octet-stream"
    static let passbook = "application/vnd.apple.pkpass"
    static let PDF = "application/pdf"
    static let plainText = "text/plain"
    static let PNG = "image/png"
    static let webP = "image/webp"
    static let xHTML = "application/xhtml+xml"

    private static let webViewViewableTypes: [String] = [MIMEType.bitmap, MIMEType.GIF, MIMEType.JPEG, MIMEType.HTML, MIMEType.PDF, MIMEType.plainText, MIMEType.PNG, MIMEType.webP, MIMEType.xHTML]

    static func canShowInWebView(_ mimeType: String) -> Bool {
        return webViewViewableTypes.contains(mimeType.lowercased())
    }

    static func mimeTypeFromFileExtension(_ fileExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue(), let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimeType as String
        }

        return MIMEType.octetStream
    }
}

extension String {
    var isKindOfHTML: Bool {
        return [MIMEType.HTML, MIMEType.xHTML].contains(self)
    }
}

protocol OpenInHelper {
    init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, forceDownload: Bool, browserViewController: BrowserViewController)
    func open()
}

class DownloadHelper: NSObject, OpenInHelper {
    fileprivate let request: URLRequest
    fileprivate let preflightResponse: URLResponse
    fileprivate let browserViewController: BrowserViewController

    required init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, forceDownload: Bool, browserViewController: BrowserViewController) {
        guard let request = request else {
            return nil
        }

        let contentDisposition = (response as? HTTPURLResponse)?.allHeaderFields["Content-Disposition"] as? String
        let mimeType = response.mimeType ?? MIMEType.octetStream
        let isAttachment = contentDisposition?.starts(with: "attachment") ?? (mimeType == MIMEType.octetStream)

        guard isAttachment || !canShowInWebView || forceDownload else {
            return nil
        }

        self.request = request
        self.preflightResponse = response
        self.browserViewController = browserViewController
    }
    
    func open() {
        guard let host = request.url?.host, let filename = request.url?.lastPathComponent else {
            return
        }
        
        let download = HTTPDownload(preflightResponse: preflightResponse, request: request)
        
        let expectedSize = download.totalBytesExpected != nil ? ByteCountFormatter.string(fromByteCount: download.totalBytesExpected!, countStyle: .file) : nil
        
        let title = "\(filename) - \(host)"
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        var downloadActionText = Strings.download
        // The download can be of undetermined size, adding expected size only if it's available.
        if let expectedSize = expectedSize {
            downloadActionText += " (\(expectedSize))"
        }
        
        let okAction = UIAlertAction(title: downloadActionText, style: .default) { _ in
            self.browserViewController.downloadQueue.enqueue(download)
        }
        
        let cancelAction = UIAlertAction(title: Strings.cancelButtonTitle, style: .cancel)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        alert.popoverPresentationController?.do {
            guard let view = browserViewController.view else { return }
            $0.sourceView = view
            $0.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 16, width: 0, height: 0)
            $0.permittedArrowDirections = []
        }
        
        browserViewController.present(alert, animated: true, completion: nil)
    }
}

class OpenPassBookHelper: NSObject, OpenInHelper {
    fileprivate var url: URL

    fileprivate let browserViewController: BrowserViewController

    required init?(request: URLRequest?, response: URLResponse, canShowInWebView: Bool, forceDownload: Bool, browserViewController: BrowserViewController) {
        guard let mimeType = response.mimeType, mimeType == MIMEType.passbook, PKAddPassesViewController.canAddPasses(),
            let responseURL = response.url, !forceDownload else { return nil }
        self.url = responseURL
        self.browserViewController = browserViewController
        super.init()
    }

    func open() {
        guard let passData = try? Data(contentsOf: url) else { return }
        do {
            let pass = try PKPass(data: passData)
            let passLibrary = PKPassLibrary()
            if passLibrary.containsPass(pass) {
                UIApplication.shared.open(pass.passURL!, options: [:])
            } else {
                if let addController = PKAddPassesViewController(pass: pass) {
                    browserViewController.present(addController, animated: true, completion: nil)
                }
            }
        } catch {
            // display an error
            let alertController = UIAlertController(
                title: Strings.unableToAddPassErrorTitle,
                message: Strings.unableToAddPassErrorMessage,
                preferredStyle: .alert)
            alertController.addAction(
                UIAlertAction(title: Strings.unableToAddPassErrorDismiss, style: .cancel) { (action) in
                    // Do nothing.
                })
            browserViewController.present(alertController, animated: true, completion: nil)
            return
        }
    }
}
