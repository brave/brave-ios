/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper
import LocalAuthentication

class AppAuthenticator {
    static func presentAuthenticationUsingInfo(_ authenticationInfo: AuthenticationKeychainInfo, touchIDReason: String, success: (() -> Void)?, cancel: (() -> Void)?, fallback: (() -> Void)?) {
        if authenticationInfo.useTouchID {
            let localAuthContext = LAContext()
            localAuthContext.localizedFallbackTitle = AuthenticationStrings.enterPasscode
            localAuthContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: touchIDReason) { didSucceed, error in
                if didSucceed {
                    // Update our authentication info's last validation timestamp so we don't ask again based
                    // on the set required interval
                    authenticationInfo.recordValidation()
                    KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authenticationInfo)
                    DispatchQueue.main.async {
                        success?()
                    }
                    return
                }
                
                guard let authError = error,
                          let code = LAError.Code(rawValue: authError._code) else {
                    return
                }

                DispatchQueue.main.async {
                    switch code {
                    case .userFallback, .touchIDNotEnrolled, .touchIDNotAvailable, .touchIDLockout:
                        fallback?()
                    case .userCancel:
                        cancel?()
                    default:
                        cancel?()
                    }
                }
            }
        } else {
            fallback?()
        }
    }

    static func presentPasscodeAuthentication(_ presentingNavController: UINavigationController?, delegate: PasscodeEntryDelegate?, isCancellable: Bool) {
        let passcodeVC = PasscodeEntryViewController()
        passcodeVC.isCancellable = isCancellable
        passcodeVC.delegate = delegate
        let navController = UINavigationController(rootViewController: passcodeVC)
        navController.modalPresentationStyle = .formSheet
        presentingNavController?.present(navController, animated: true, completion: nil)
    }
}
