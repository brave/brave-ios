/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper

/// Displayed to the user when setting up a passcode.
class SetupPasscodeViewController: PagingPasscodeViewController, PasscodeInputViewDelegate {
    fileprivate var confirmCode: String?

    override init() {
        super.init()
        self.title = Strings.authenticationSetPasscode
        self.panes = [
            PasscodePane(title: Strings.authenticationEnterAPasscode, passcodeSize: 6),
            PasscodePane(title: Strings.authenticationReenterPasscode, passcodeSize: 6),
        ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        panes.forEach { $0.codeInputView.delegate = self }

        // Don't show the keyboard or allow typing if we're locked out. Also display the error.
        if authenticationInfo?.isLocked() ?? false {
            displayLockoutError()
            panes.first?.codeInputView.isUserInteractionEnabled = false
        } else {
            panes.first?.codeInputView.becomeFirstResponder()
        }
    }

    func passcodeInputView(_ inputView: PasscodeInputView, didFinishEnteringCode code: String) {
        switch currentPaneIndex {
        case 0:
            confirmCode = code
            scrollToNextAndSelect()
        case 1:
            // Constraint: The first and confirmation codes must match.
            if confirmCode != code {
                failMismatchPasscode()
                resetAllInputFields()
                scrollToPreviousAndSelect()
                confirmCode = nil
                return
            }

            createPasscodeWithCode(code)
            dismissAnimated()
        default:
            break
        }
    }

    fileprivate func createPasscodeWithCode(_ code: String) {
        KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(AuthenticationKeychainInfo(passcode: code))

        NotificationCenter.default.post(name: .passcodeDidCreate, object: nil)
    }
}
