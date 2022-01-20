/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared
import Storage
import XCGLogger
import WebKit
import SwiftyJSON

private let log = Logger.browserLogger

class LoginsHelper: TabContentScript {
    fileprivate weak var tab: Tab?
    fileprivate let profile: Profile
    fileprivate var snackBar: SnackBar?

    // Exposed for mocking purposes
    var logins: BrowserLogins {
        return profile.logins
    }

    class func name() -> String {
        return "LoginsHelper"
    }

    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile
    }

    func scriptMessageHandlerName() -> String? {
        return "loginsManagerMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let body = message.body as? [String: AnyObject] else {
            return
        }
        
        if UserScriptManager.isMessageHandlerTokenMissing(in: body) {
            log.debug("Missing required security token.")
            return
        }

        guard var res = body["data"] as? [String: AnyObject] else { return }
        guard let type = res["type"] as? String else { return }

        // Check to see that we're in the foreground before trying to check the logins. We want to
        // make sure we don't try accessing the logins database while we're backgrounded to avoid
        // the system from terminating our app due to background disk access.
        //
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1307822 for details.
        guard UIApplication.shared.applicationState == .active && !profile.isShutdown else {
            return 
        }

        // We don't use the WKWebView's URL since the page can spoof the URL by using document.location
        // right before requesting login data. See bug 1194567 for more context.
        if let url = message.frameInfo.request.url {
            // Since responses go to the main frame, make sure we only listen for main frame requests
            // to avoid XSS attacks.
            if type == "request" {
                res["username"] = "" as AnyObject?
                res["password"] = "" as AnyObject?
                if let login = Login.fromScript(url, script: res),
                   let requestId = res["requestId"] as? String {
                    requestLogins(login, requestId: requestId, frameInfo: message.frameInfo)
                }
            } else if type == "submit" {
                if Preferences.General.saveLogins.value {
                    if let login = Login.fromScript(url, script: res) {
                        setCredentials(login)
                    }
                }
            }
        }
    }

    func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>> {
        return profile.logins.getLoginsForProtectionSpace(protectionSpace)
    }

    func updateLoginByGUID(_ guid: GUID, new: LoginData, significant: Bool) -> Success {
        return profile.logins.updateLoginByGUID(guid, new: new, significant: significant)
    }

    func setCredentials(_ login: LoginData) {
        if login.password.isEmpty {
            log.debug("Empty password")
            return
        }

        profile.logins
               .getLoginsForProtectionSpace(login.protectionSpace, withUsername: login.username)
               .uponQueue(.main) { res in
            if let data = res.successValue {
                log.debug("Found \(data.count) logins.")
                for saved in data {
                    if let saved = saved {
                        if saved.password == login.password {
                            self.profile.logins.addUseOfLoginByGUID(saved.guid)
                            return
                        }

                        self.promptUpdateFromLogin(login: saved, toLogin: login)
                        return
                    }
                }
            }

            self.promptSave(login)
        }
    }

    fileprivate func promptSave(_ login: LoginData) {
        guard login.isValid.isSuccess else {
            return
        }

        let promptMessage: String
        if let username = login.username {
            promptMessage = String(format: Strings.saveLoginUsernamePrompt, username, login.hostname)
        } else {
            promptMessage = String(format: Strings.saveLoginPrompt, login.hostname)
        }

        if let existingPrompt = self.snackBar {
            tab?.removeSnackbar(existingPrompt)
        }

        snackBar = TimerSnackBar(text: promptMessage, img: #imageLiteral(resourceName: "shields-menu-icon"))
        let dontSave = SnackButton(title: Strings.loginsHelperDontSaveButtonTitle, accessibilityIdentifier: "SaveLoginPrompt.dontSaveButton") { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            return
        }
        let save = SnackButton(title: Strings.loginsHelperSaveLoginButtonTitle, accessibilityIdentifier: "SaveLoginPrompt.saveLoginButton") { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            self.profile.logins.addLogin(login)
        }
        snackBar?.addButton(dontSave)
        snackBar?.addButton(save)
        tab?.addSnackbar(snackBar!)
    }

    fileprivate func promptUpdateFromLogin(login old: LoginData, toLogin new: LoginData) {
        guard new.isValid.isSuccess else {
            return
        }

        let guid = old.guid

        let formatted: String
        if let username = new.username {
            formatted = String(format: Strings.updateLoginUsernamePrompt, username, new.hostname)
        } else {
            formatted = String(format: Strings.updateLoginPrompt, new.hostname)
        }

        if let existingPrompt = self.snackBar {
            tab?.removeSnackbar(existingPrompt)
        }

        snackBar = TimerSnackBar(text: formatted, img: #imageLiteral(resourceName: "key"))
        let dontSave = SnackButton(title: Strings.loginsHelperDontUpdateButtonTitle, accessibilityIdentifier: "UpdateLoginPrompt.donttUpdateButton") { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            return
        }
        let update = SnackButton(title: Strings.loginsHelperUpdateButtonTitle, accessibilityIdentifier: "UpdateLoginPrompt.updateButton") { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            self.profile.logins.updateLoginByGUID(guid, new: new, significant: new.isSignificantlyDifferentFrom(old))
        }
        snackBar?.addButton(dontSave)
        snackBar?.addButton(update)
        tab?.addSnackbar(snackBar!)
    }

    fileprivate func requestLogins(_ login: LoginData, requestId: String, frameInfo: WKFrameInfo) {
        let currentHost = tab?.webView?.url?.host
        let frameHost = frameInfo.securityOrigin.host
        
        profile.logins.getLoginsForProtectionSpace(login.protectionSpace).uponQueue(.main) { res in
            var jsonObj = [String: Any]()
            if let cursor = res.successValue {
                log.debug("Found \(cursor.count) logins.")
                jsonObj["requestId"] = requestId
                jsonObj["name"] = "RemoteLogins:loginsFound"
                jsonObj["logins"] = cursor.compactMap { loginData -> [String: String]? in
                    if frameInfo.isMainFrame {
                        return loginData?.toDict()
                    }
                    
                    // The frame must belong to the same security origin
                    if let currentHost = currentHost,
                       !currentHost.isEmpty,
                       currentHost == frameHost {
                        // Prevent XSS on non main frame
                        // If it is not the main frame, return username only, but no password!
                        // Chromium does the same on iOS.
                        // Firefox does NOT support third-party frames or iFrames.
                        loginData?.update(password: "", username: loginData?.username ?? "")
                        return loginData?.toDict()
                    }
                    
                    return nil
                }
            }

            let json = JSON(jsonObj)
            guard let jsonString = json.stringValue() else {
                return
            }
            
            self.tab?.webView?.evaluateSafeJavaScript(functionName: "window.__firefox__.logins.inject", args: [jsonString], contentWorld: .page, escapeArgs: false) { (obj, err) -> Void in
                if err != nil {
                    log.debug(err)
                }
            }
        }
    }
}
