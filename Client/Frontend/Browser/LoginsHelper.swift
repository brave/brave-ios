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
import BraveCore

private let log = Logger.browserLogger

class LoginsHelper: TabContentScript {
    private weak var tab: Tab?
    private let profile: Profile
    private let passwordAPI: BravePasswordAPI
    
    private var snackBar: SnackBar?

    // Used while handling authentication challenge
    var logins: BrowserLogins {
        return profile.logins
    }

    class func name() -> String {
        return "LoginsHelper"
    }

    required init(tab: Tab, profile: Profile, passwordAPI: BravePasswordAPI) {
        self.tab = tab
        self.profile = profile
        self.passwordAPI = passwordAPI
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

        guard let res = body["data"] as? [String: AnyObject] else { return }
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
                passwordAPI.getSavedLogins(for: url, formScheme: .typeHtml) { [weak self] logins in
                    guard let self = self else { return }

                    if let requestId = res["requestId"] as? String {
                        self.autoFillRequestedCredentials(
                            formSubmitURL: res["formSubmitURL"] as? String ?? "",
                            logins: logins,
                            requestId: requestId,
                            frameInfo: message.frameInfo)
                    }
                }
            } else if type == "submit" {
                if Preferences.General.saveLogins.value {
                    updateORSaveCredentials(for: url, script: res)
                }
            }
        }
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

    private func promptUpdateFromLogin(login old: LoginData, toLogin new: LoginData) {
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
    
    private func updateORSaveCredentials(for url: URL, script: [String: Any]) {
        guard let scriptCredentials = passwordAPI.fetchFromScript(url, script: script),
              let username = scriptCredentials.usernameValue,
              scriptCredentials.usernameElement != nil,
              let password = scriptCredentials.passwordValue,
              scriptCredentials.passwordElement != nil else {
            log.debug("Missing Credentials from script")
            return
        }
        
        if password.isEmpty {
            log.debug("Empty Password")
            return
        }
        
        passwordAPI.getSavedLogins(for: url, formScheme: .typeHtml) { [weak self] logins in
            guard let self = self else { return }
            
            for login in logins {
                if (login.usernameValue ?? "").caseInsensitivelyEqual(to: username) {
                    guard password == login.passwordValue else {
                        return
                    }
                    
                    self.showUpdatePrompt(from: login, to: scriptCredentials)
                    return
                } else {
                    self.showAddPrompt(for: scriptCredentials)
                    return
                }
            }
            
            self.showAddPrompt(for: scriptCredentials)
        }
    }
    
    private func showAddPrompt(for login: PasswordForm) {
        addSnackBarForPrompt(for: login, isUpdating: false) { [unowned self] in
            DispatchQueue.main.async {
                print("LOGIN URL \(login.url)")
                print("LOGIN REALM \(login.signOnRealm)")
                self.passwordAPI.addLogin(login)
            }
        }
    }
    
    private func showUpdatePrompt(from old: PasswordForm, to new: PasswordForm) {
        addSnackBarForPrompt(for: new, isUpdating: true) { [unowned self] in
            self.passwordAPI.updateLogin(new, oldPasswordForm: old)
        }
    }
    
    private func addSnackBarForPrompt(for login: PasswordForm, isUpdating: Bool, _ completion: @escaping () -> Void) {
        guard let username = login.usernameValue else {
            return
        }
        
        // Remove the existing prompt
        if let existingPrompt = self.snackBar {
            tab?.removeSnackbar(existingPrompt)
        }
        
        let promptMessage = String(
            format: isUpdating ? Strings.updateLoginUsernamePrompt: Strings.saveLoginUsernamePrompt, username,
            login.url.getURLStringOrigin() ?? login.signOnRealm)

        snackBar = TimerSnackBar(
            text: promptMessage,
            img: isUpdating ? #imageLiteral(resourceName: "key") : #imageLiteral(resourceName: "shields-menu-icon"))
        
        let dontSaveORUpdate = SnackButton(
            title: isUpdating ? Strings.loginsHelperDontUpdateButtonTitle : Strings.loginsHelperDontSaveButtonTitle,
            accessibilityIdentifier: "UpdateLoginPrompt.dontSaveUpdateButton") { [unowned self] bar in
                self.tab?.removeSnackbar(bar)
                self.snackBar = nil
                return
        }
        
        let saveORUpdate = SnackButton(
            title: isUpdating ?  Strings.loginsHelperUpdateButtonTitle : Strings.loginsHelperSaveLoginButtonTitle,
            accessibilityIdentifier: "UpdateLoginPrompt.saveUpdateButton") { [unowned self] bar in
                self.tab?.removeSnackbar(bar)
                self.snackBar = nil
                
                completion()
        }
        
        snackBar?.addButton(dontSaveORUpdate)
        snackBar?.addButton(saveORUpdate)
        
        tab?.addSnackbar(snackBar)
    }
    
    private func autoFillRequestedCredentials(formSubmitURL: String, logins: [PasswordForm], requestId: String, frameInfo: WKFrameInfo) {
        let currentHost = tab?.webView?.url?.host
        let frameHost = frameInfo.securityOrigin.host
        
        var jsonObj = [String: Any]()
        jsonObj["requestId"] = requestId
        jsonObj["name"] = "RemoteLogins:loginsFound"
        jsonObj["logins"] = logins.compactMap { loginData -> [String: String]? in
            if frameInfo.isMainFrame {
                return loginData.toDict(formSubmitURL: formSubmitURL)
            }
            
            // The frame must belong to the same security origin
            if let currentHost = currentHost,
               !currentHost.isEmpty,
               currentHost == frameHost {
                // Prevent XSS on non main frame
                // If it is not the main frame, return username only, but no password!
                // Chromium does the same on iOS.
                // Firefox does NOT support third-party frames or iFrames.
                
                if let updatedLogin = loginData.copy() as? PasswordForm {
                    updatedLogin.update(loginData.usernameValue, passwordValue: "")
                    
                    return updatedLogin.toDict(formSubmitURL: formSubmitURL)
                }
            }
            
            return nil
        }
        
        let json = JSON(jsonObj)
        guard let jsonString = json.stringValue() else {
            return
        }
        
        self.tab?.webView?.evaluateSafeJavaScript(
            functionName: "window.__firefox__.logins.inject",
            args: [jsonString],
            contentWorld: .defaultClient,
            escapeArgs: false) { (obj, err) -> Void in
            if err != nil {
                log.debug(err)
            }
        }
    }
}

extension URL {
    
    /// Retrieving the the origin from url
    /// This method will be used to fetch singOnRealm from url while saving credentials
    /// - Parameter allowJS: Boolean determining if scheme javascript allowed
    /// - Returns: Origin of the url
    func getURLStringOrigin(allowJS: Bool = false) -> String? {
        var realm: String?
        if let scheme = self.scheme, !scheme.isEmpty,
           let host = self.host {
            if allowJS && scheme == "javascript" {
                return "javascript:"
            }

            realm = "\(scheme)://\(host)/"

            // If the URI explicitly specified a port, only include it when
            // it's not the default. (We never want "http://foo.com:80")
            if let port = self.port {
                realm? += ":\(port)"
            }
        } else {
            log.debug("Couldn't parse origin for \(self)")
            realm = nil
        }
        
        return realm
    }
}
