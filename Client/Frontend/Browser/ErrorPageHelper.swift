/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers
import Shared
import Storage

private let log = Logger.browserLogger

class ErrorPageHelper {
    static let mozDomain = "mozilla"
    static let mozErrorDownloadsNotEnabled = 100

    fileprivate static let messageOpenInSafari = "openInSafari"
    fileprivate static let messageCertVisitOnce = "certVisitOnce"

    // When an error page is intentionally loaded, its added to this set. If its in the set, we show
    // it as an error page. If its not, we assume someone is trying to reload this page somehow, and
    // we'll instead redirect back to the original URL.
    fileprivate static var redirecting = [URL]()

    fileprivate static weak var certStore: CertStore?

    // Regardless of cause, NSURLErrorServerCertificateUntrusted is currently returned in all cases.
    // Check the other cases in case this gets fixed in the future.
    fileprivate static let certErrors = [
        NSURLErrorServerCertificateUntrusted,
        NSURLErrorServerCertificateHasBadDate,
        NSURLErrorServerCertificateHasUnknownRoot,
        NSURLErrorServerCertificateNotYetValid
    ]

    // Error codes copied from Gecko. The ints corresponding to these codes were determined
    // by inspecting the NSError in each of these cases.
    fileprivate static let certErrorCodes = [
        -9813: "SEC_ERROR_UNKNOWN_ISSUER",
        -9814: "SEC_ERROR_EXPIRED_CERTIFICATE",
        -9843: "SSL_ERROR_BAD_CERT_DOMAIN",
    ]

    class func cfErrorToName(_ err: CFNetworkErrors) -> String {
        switch err {
        case .cfHostErrorHostNotFound: return "CFHostErrorHostNotFound"
        case .cfHostErrorUnknown: return "CFHostErrorUnknown"
        case .cfsocksErrorUnknownClientVersion: return "CFSOCKSErrorUnknownClientVersion"
        case .cfsocksErrorUnsupportedServerVersion: return "CFSOCKSErrorUnsupportedServerVersion"
        case .cfsocks4ErrorRequestFailed: return "CFSOCKS4ErrorRequestFailed"
        case .cfsocks4ErrorIdentdFailed: return "CFSOCKS4ErrorIdentdFailed"
        case .cfsocks4ErrorIdConflict: return "CFSOCKS4ErrorIdConflict"
        case .cfsocks4ErrorUnknownStatusCode: return "CFSOCKS4ErrorUnknownStatusCode"
        case .cfsocks5ErrorBadState: return "CFSOCKS5ErrorBadState"
        case .cfsocks5ErrorBadResponseAddr: return "CFSOCKS5ErrorBadResponseAddr"
        case .cfsocks5ErrorBadCredentials: return "CFSOCKS5ErrorBadCredentials"
        case .cfsocks5ErrorUnsupportedNegotiationMethod: return "CFSOCKS5ErrorUnsupportedNegotiationMethod"
        case .cfsocks5ErrorNoAcceptableMethod: return "CFSOCKS5ErrorNoAcceptableMethod"
        case .cfftpErrorUnexpectedStatusCode: return "CFFTPErrorUnexpectedStatusCode"
        case .cfErrorHTTPAuthenticationTypeUnsupported: return "CFErrorHTTPAuthenticationTypeUnsupported"
        case .cfErrorHTTPBadCredentials: return "CFErrorHTTPBadCredentials"
        case .cfErrorHTTPConnectionLost: return "CFErrorHTTPConnectionLost"
        case .cfErrorHTTPParseFailure: return "CFErrorHTTPParseFailure"
        case .cfErrorHTTPRedirectionLoopDetected: return "CFErrorHTTPRedirectionLoopDetected"
        case .cfErrorHTTPBadURL: return "CFErrorHTTPBadURL"
        case .cfErrorHTTPProxyConnectionFailure: return "CFErrorHTTPProxyConnectionFailure"
        case .cfErrorHTTPBadProxyCredentials: return "CFErrorHTTPBadProxyCredentials"
        case .cfErrorPACFileError: return "CFErrorPACFileError"
        case .cfErrorPACFileAuth: return "CFErrorPACFileAuth"
        case .cfErrorHTTPSProxyConnectionFailure: return "CFErrorHTTPSProxyConnectionFailure"
        case .cfStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod: return "CFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod"

        case .cfurlErrorBackgroundSessionInUseByAnotherProcess: return "CFURLErrorBackgroundSessionInUseByAnotherProcess"
        case .cfurlErrorBackgroundSessionWasDisconnected: return "CFURLErrorBackgroundSessionWasDisconnected"
        case .cfurlErrorUnknown: return "CFURLErrorUnknown"
        case .cfurlErrorCancelled: return "CFURLErrorCancelled"
        case .cfurlErrorBadURL: return "CFURLErrorBadURL"
        case .cfurlErrorTimedOut: return "CFURLErrorTimedOut"
        case .cfurlErrorUnsupportedURL: return "CFURLErrorUnsupportedURL"
        case .cfurlErrorCannotFindHost: return "CFURLErrorCannotFindHost"
        case .cfurlErrorCannotConnectToHost: return "CFURLErrorCannotConnectToHost"
        case .cfurlErrorNetworkConnectionLost: return "CFURLErrorNetworkConnectionLost"
        case .cfurlErrorDNSLookupFailed: return "CFURLErrorDNSLookupFailed"
        case .cfurlErrorHTTPTooManyRedirects: return "CFURLErrorHTTPTooManyRedirects"
        case .cfurlErrorResourceUnavailable: return "CFURLErrorResourceUnavailable"
        case .cfurlErrorNotConnectedToInternet: return "CFURLErrorNotConnectedToInternet"
        case .cfurlErrorRedirectToNonExistentLocation: return "CFURLErrorRedirectToNonExistentLocation"
        case .cfurlErrorBadServerResponse: return "CFURLErrorBadServerResponse"
        case .cfurlErrorUserCancelledAuthentication: return "CFURLErrorUserCancelledAuthentication"
        case .cfurlErrorUserAuthenticationRequired: return "CFURLErrorUserAuthenticationRequired"
        case .cfurlErrorZeroByteResource: return "CFURLErrorZeroByteResource"
        case .cfurlErrorCannotDecodeRawData: return "CFURLErrorCannotDecodeRawData"
        case .cfurlErrorCannotDecodeContentData: return "CFURLErrorCannotDecodeContentData"
        case .cfurlErrorCannotParseResponse: return "CFURLErrorCannotParseResponse"
        case .cfurlErrorInternationalRoamingOff: return "CFURLErrorInternationalRoamingOff"
        case .cfurlErrorCallIsActive: return "CFURLErrorCallIsActive"
        case .cfurlErrorDataNotAllowed: return "CFURLErrorDataNotAllowed"
        case .cfurlErrorRequestBodyStreamExhausted: return "CFURLErrorRequestBodyStreamExhausted"
        case .cfurlErrorFileDoesNotExist: return "CFURLErrorFileDoesNotExist"
        case .cfurlErrorFileIsDirectory: return "CFURLErrorFileIsDirectory"
        case .cfurlErrorNoPermissionsToReadFile: return "CFURLErrorNoPermissionsToReadFile"
        case .cfurlErrorDataLengthExceedsMaximum: return "CFURLErrorDataLengthExceedsMaximum"
        case .cfurlErrorSecureConnectionFailed: return "CFURLErrorSecureConnectionFailed"
        case .cfurlErrorServerCertificateHasBadDate: return "CFURLErrorServerCertificateHasBadDate"
        case .cfurlErrorServerCertificateUntrusted: return "CFURLErrorServerCertificateUntrusted"
        case .cfurlErrorServerCertificateHasUnknownRoot: return "CFURLErrorServerCertificateHasUnknownRoot"
        case .cfurlErrorServerCertificateNotYetValid: return "CFURLErrorServerCertificateNotYetValid"
        case .cfurlErrorClientCertificateRejected: return "CFURLErrorClientCertificateRejected"
        case .cfurlErrorClientCertificateRequired: return "CFURLErrorClientCertificateRequired"
        case .cfurlErrorCannotLoadFromNetwork: return "CFURLErrorCannotLoadFromNetwork"
        case .cfurlErrorCannotCreateFile: return "CFURLErrorCannotCreateFile"
        case .cfurlErrorCannotOpenFile: return "CFURLErrorCannotOpenFile"
        case .cfurlErrorCannotCloseFile: return "CFURLErrorCannotCloseFile"
        case .cfurlErrorCannotWriteToFile: return "CFURLErrorCannotWriteToFile"
        case .cfurlErrorCannotRemoveFile: return "CFURLErrorCannotRemoveFile"
        case .cfurlErrorCannotMoveFile: return "CFURLErrorCannotMoveFile"
        case .cfurlErrorDownloadDecodingFailedMidStream: return "CFURLErrorDownloadDecodingFailedMidStream"
        case .cfurlErrorDownloadDecodingFailedToComplete: return "CFURLErrorDownloadDecodingFailedToComplete"

        case .cfhttpCookieCannotParseCookieFile: return "CFHTTPCookieCannotParseCookieFile"
        case .cfNetServiceErrorUnknown: return "CFNetServiceErrorUnknown"
        case .cfNetServiceErrorCollision: return "CFNetServiceErrorCollision"
        case .cfNetServiceErrorNotFound: return "CFNetServiceErrorNotFound"
        case .cfNetServiceErrorInProgress: return "CFNetServiceErrorInProgress"
        case .cfNetServiceErrorBadArgument: return "CFNetServiceErrorBadArgument"
        case .cfNetServiceErrorCancel: return "CFNetServiceErrorCancel"
        case .cfNetServiceErrorInvalid: return "CFNetServiceErrorInvalid"
        case .cfNetServiceErrorTimeout: return "CFNetServiceErrorTimeout"
        case .cfNetServiceErrorDNSServiceFailure: return "CFNetServiceErrorDNSServiceFailure"
        default: return "Unknown"
        }
    }

    class func register(_ server: WebServer, certStore: CertStore?) {
        self.certStore = certStore

        server.registerHandlerForMethod("GET", module: "errors", resource: "error.html", handler: { (request) -> GCDWebServerResponse? in
            guard let url = request?.url.originalURLFromErrorURL else {
                return GCDWebServerResponse(statusCode: 404)
            }

            guard let index = self.redirecting.firstIndex(of: url) else {
                return GCDWebServerDataResponse(redirect: url, permanent: false)
            }

            self.redirecting.remove(at: index)

            guard let query = request?.query, 
                  let code = query["code"],
                  let errCode = Int(code),
                  let errDescription = query["description"],
                  let errURLString = query["url"],
                  var errDomain = query["domain"] else {
                return GCDWebServerResponse(statusCode: 404)
            }

            var asset = Bundle.main.path(forResource: "NetError", ofType: "html")
            var variables = [
                "error_code": "\(errCode)",
                "error_title": errDescription,
                "short_description": errDomain,
            ]

            var actions = "<button onclick='webkit.messageHandlers.localRequestHelper.postMessage({ type: \"reload\" })'>\(Strings.errorPageReloadButtonTitle)</button>"

            if errDomain == kCFErrorDomainCFNetwork as String {
                if let code = CFNetworkErrors(rawValue: Int32(errCode)) {
                    errDomain = self.cfErrorToName(code)
                }
            } else if errDomain == ErrorPageHelper.mozDomain {
                if errCode == ErrorPageHelper.mozErrorDownloadsNotEnabled {
                    // Overwrite the normal try-again action.
                    actions = "<button onclick='webkit.messageHandlers.errorPageHelperMessageManager.postMessage({type: \"\(messageOpenInSafari)\"})'>\(Strings.errorPageOpenInSafariButtonTitle)</button>"
                }
                errDomain = ""
            } else if certErrors.contains(errCode) {
                guard let query = request?.query, let certError = query["certerror"],
                    let errURLDomain = URL(string: errURLString)?.host else {
                    return GCDWebServerResponse(statusCode: 404)
                }

                asset = Bundle.main.path(forResource: "CertError", ofType: "html")
                actions = "<button onclick='history.back()'>\(Strings.errorPagesGoBackButton)</button>"
                variables["error_title"] = Strings.errorPagesCertWarningTitle
                variables["cert_error"] = certError
                variables["long_description"] = String(format: Strings.errorPagesCertWarningDescription, "<b>\(errURLDomain)</b>")
                variables["advanced_button"] = Strings.errorPagesAdvancedButton
                variables["warning_description"] = Strings.errorPagesCertWarningDescription
                variables["warning_advanced1"] = Strings.errorPagesAdvancedWarning1
                variables["warning_advanced2"] = Strings.errorPagesAdvancedWarning2
                variables["warning_actions"] =
                    "<p><a href='javascript:webkit.messageHandlers.errorPageHelperMessageManager.postMessage({type: \"\(messageCertVisitOnce)\"})'>\(Strings.errorPagesVisitOnceButton)</button></p>"
            }

            variables["actions"] = actions

            guard let unwrappedAsset = asset else {
                log.error("Asset is nil")
                return GCDWebServerResponse(statusCode: 404)
            }
            
            let response = GCDWebServerDataResponse(htmlTemplate: unwrappedAsset, variables: variables)
            response?.setValue("no cache", forAdditionalHeader: "Pragma")
            response?.setValue("no-cache,must-revalidate", forAdditionalHeader: "Cache-Control")
            response?.setValue(Date().description, forAdditionalHeader: "Expires")
            return response
        })

        server.registerHandlerForMethod("GET", module: "errors", resource: "NetError.css", handler: { (request) -> GCDWebServerResponse? in
            let path = Bundle(for: self).path(forResource: "NetError", ofType: "css")!
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                log.error("NetError data is nil")
                return GCDWebServerResponse(statusCode: 404)
            }
            
            return GCDWebServerDataResponse(data: data, contentType: "text/css")
        })

        server.registerHandlerForMethod("GET", module: "errors", resource: "CertError.css", handler: { (request) -> GCDWebServerResponse? in
            let path = Bundle(for: self).path(forResource: "CertError", ofType: "css")!
            
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                log.error("CertError data is nil")
                return GCDWebServerResponse(statusCode: 404)
            }
            
            return GCDWebServerDataResponse(data: data, contentType: "text/css")
        })
    }

    func showPage(_ error: NSError, forUrl url: URL, inWebView webView: WKWebView) {
        // Don't show error pages for error pages.
        if url.isErrorPageURL {
            if let previousURL = url.originalURLFromErrorURL {
                // If the previous URL is a local file URL that we know exists,
                // just load it in the web view. This works around an issue
                // where we are unable to redirect to a `file://` URL during
                // session restore.
                if previousURL.isFileURL, FileManager.default.fileExists(atPath: previousURL.path) {
                    webView.loadFileURL(previousURL, allowingReadAccessTo: previousURL)
                    return
                }

                if let index = ErrorPageHelper.redirecting.firstIndex(of: previousURL) {
                    ErrorPageHelper.redirecting.remove(at: index)
                }
            }

            return
        }

        // Add this page to the redirecting list. This will cause the server to actually show the error page
        // (instead of redirecting to the original URL).
        ErrorPageHelper.redirecting.append(url)

        var components = URLComponents(string: WebServer.sharedInstance.base + "/errors/error.html")!
        var queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "code", value: String(error.code)),
            URLQueryItem(name: "domain", value: error.domain),
            URLQueryItem(name: "description", value: error.localizedDescription)
        ]

        // If this is an invalid certificate, show a certificate error allowing the
        // user to go back or continue. The certificate itself is encoded and added as
        // a query parameter to the error page URL; we then read the certificate from
        // the URL if the user wants to continue.
        if ErrorPageHelper.certErrors.contains(error.code),
           let certChain = error.userInfo["NSErrorPeerCertificateChainKey"] as? [SecCertificate],
           let cert = certChain.first,
           let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
           let certErrorCode = underlyingError.userInfo["_kCFStreamErrorCodeKey"] as? Int {
            let encodedCert = (SecCertificateCopyData(cert) as Data).base64EncodedString
            queryItems.append(URLQueryItem(name: "badcert", value: encodedCert))

            let certError = ErrorPageHelper.certErrorCodes[certErrorCode] ?? ""
            queryItems.append(URLQueryItem(name: "certerror", value: String(certError)))
        }

        components.queryItems = queryItems
        webView.load(PrivilegedRequest(url: components.url!) as URLRequest)
    }
    
    public static func certificateError(for url: URL) -> Int {
        if url.isErrorPageURL {
            let query = url.getQuery()
            
            let cfErrors: [CFNetworkErrors] = [
                .cfurlErrorSecureConnectionFailed,
                .cfurlErrorServerCertificateHasBadDate,
                .cfurlErrorServerCertificateUntrusted,
                .cfurlErrorServerCertificateHasUnknownRoot,
                .cfurlErrorServerCertificateNotYetValid,
                .cfurlErrorClientCertificateRejected,
                .cfurlErrorClientCertificateRequired
            ]
            
            guard let code = query["code"], let errCode = Int(code) else {
                return 0
            }
            
            if let code = CFNetworkErrors(rawValue: Int32(errCode)), cfErrors.contains(code) {
                return errCode
            }
            
            if ErrorPageHelper.certErrors.contains(errCode) {
                return errCode
            }
            
            if ErrorPageHelper.certErrorCodes[errCode] != nil {
                return errCode
            }
            return 0
        }
        return 0
    }
}

extension ErrorPageHelper: TabContentScript {
    static func name() -> String {
        return "ErrorPageHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "errorPageHelperMessageManager"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let errorURL = message.frameInfo.request.url, errorURL.isErrorPageURL,
           let res = message.body as? [String: String],
           let originalURL = errorURL.originalURLFromErrorURL,
           let type = res["type"] {

            switch type {
            case ErrorPageHelper.messageOpenInSafari:
                UIApplication.shared.open(originalURL, options: [:])
            case ErrorPageHelper.messageCertVisitOnce:
                if let cert = certFromErrorURL(errorURL),
                   let host = originalURL.host {
                    let origin = "\(host):\(originalURL.port ?? 443)"
                    ErrorPageHelper.certStore?.addCertificate(cert, forOrigin: origin)
                    _ = message.webView?.reload()
                }
            default:
                assertionFailure("Unknown error message")
            }
        }
    }

    fileprivate func certFromErrorURL(_ url: URL) -> SecCertificate? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let encodedCert = components?.queryItems?.filter({ $0.name == "badcert" }).first?.value,
               let certData = Data(base64Encoded: encodedCert, options: []) {
            return SecCertificateCreateWithData(nil, certData as CFData)
        }

        return nil
    }
}
