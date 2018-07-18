/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import SwiftKeychainWrapper

enum AuthenticationState {
    case notAuthenticating
    case presenting
}

/// A global flag indicating whether or not the user has validated their session already
private var isSessionValidated = false

class SensitiveViewController: UIViewController {
    var promptingForTouchID = false
    var backgroundedBlur: UIImageView?
    var authState: AuthenticationState = .notAuthenticating
    var isPasscodeEntryCancellable = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(checkIfUserRequiresValidation), name: .UIApplicationWillEnterForeground, object: nil)
        notificationCenter.addObserver(self, selector: #selector(checkIfUserRequiresValidation), name: .UIApplicationDidBecomeActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(blurContents), name: .UIApplicationWillResignActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationBackgrounded), name: .UIApplicationDidEnterBackground, object: nil)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc func checkIfUserRequiresValidation() {
        if isSessionValidated {
            removeBackgroundedBlur()
            return
        }
        
        if authState == .presenting {
            return
        }
        
        presentedViewController?.dismiss(animated: false, completion: nil)
        guard let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo() else {
            return
        }

        promptingForTouchID = true
        AppAuthenticator.presentAuthenticationUsingInfo(authInfo,
            touchIDReason: AuthenticationStrings.loginsTouchReason,
            success: {
                self.promptingForTouchID = false
                self.authState = .notAuthenticating
                self.removeBackgroundedBlur()
                isSessionValidated = true
            },
            cancel: {
                self.promptingForTouchID = false
                self.authState = .notAuthenticating
                _ = self.navigationController?.popToRootViewController(animated: true)
            },
            fallback: {
                self.promptingForTouchID = false
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController, delegate: self, isCancellable: self.isPasscodeEntryCancellable)
            }
        )
        authState = .presenting
    }

    @objc func applicationBackgrounded() {
        if let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo(), authInfo.isPasscodeRequiredImmediately {
            isSessionValidated = false
        }
    }

    @objc func blurContents() {
        if KeychainWrapper.sharedAppContainerKeychain.authenticationInfo() == nil {
            return
        }
        
        if backgroundedBlur == nil {
            backgroundedBlur = addBlurredContent()
        }
    }

    func removeBackgroundedBlur() {
        if !promptingForTouchID {
            backgroundedBlur?.removeFromSuperview()
            backgroundedBlur = nil
        }
    }

    fileprivate func addBlurredContent() -> UIImageView? {
        guard let snapshot = view.screenshot() else {
            return nil
        }

        let blurredSnapshot = snapshot.applyBlur(withRadius: 10, blurType: BOXFILTER, tintColor: UIColor(white: 1, alpha: 0.3), saturationDeltaFactor: 1.8, maskImage: nil)
        let blurView = UIImageView(image: blurredSnapshot)
        view.addSubview(blurView)
        blurView.snp.makeConstraints { $0.edges.equalTo(self.view) }
        view.layoutIfNeeded()

        return blurView
    }
}

// MARK: - PasscodeEntryDelegate
extension SensitiveViewController: PasscodeEntryDelegate {
    func passcodeValidationDidSucceed() {
        removeBackgroundedBlur()
        isSessionValidated = true
      
        self.navigationController?.dismiss(animated: true, completion: nil)
        self.authState = .notAuthenticating
    }

    func userDidCancelValidation() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        self.authState = .notAuthenticating
    }
}

