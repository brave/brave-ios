/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Strings used in multiple areas within the Authentication Manager
struct AuthenticationStrings {
    static let passcode =
        NSLocalizedString("PasscodeForLogins", value: "Passcode For Logins", comment: "Label for the Passcode item in Settings")

    static let touchIDPasscodeSetting =
        NSLocalizedString("TouchIDPasscode", value: "Touch ID & Passcode", comment: "Label for the Touch ID/Passcode item in Settings")

    static let faceIDPasscodeSetting =
        NSLocalizedString("FaceIDPasscode", value: "Face ID & Passcode", comment: "Label for the Face ID/Passcode item in Settings")

    static let requirePasscode =
        NSLocalizedString("RequirePasscode", value: "Require Passcode", comment: "Text displayed in the 'Interval' section, followed by the current interval setting, e.g. 'Immediately'")

    static let enterAPasscode =
        NSLocalizedString("EnterAPasscode", value: "Enter a passcode", comment: "Text displayed above the input field when entering a new passcode")

    static let enterPasscodeTitle =
        NSLocalizedString("EnterPasscode", value: "Enter Passcode", comment: "Title of the dialog used to request the passcode")

    static let enterPasscode =
        NSLocalizedString("EnterPasscode", value: "Enter passcode", comment: "Text displayed above the input field when changing the existing passcode")

    static let reenterPasscode =
        NSLocalizedString("ReEnterPasscode", value: "Re-enter passcode", comment: "Text displayed above the input field when confirming a passcode")

    static let setPasscode =
        NSLocalizedString("SetPasscode", value: "Set Passcode", comment: "Title of the dialog used to set a passcode")

    static let turnOffPasscode =
        NSLocalizedString("TurnPasscodeOff", value: "Turn Passcode Off", comment: "Label used as a setting item to turn off passcode")

    static let turnOnPasscode =
        NSLocalizedString("TurnPasscodeOn", value: "Turn Passcode On", comment: "Label used as a setting item to turn on passcode")

    static let changePasscode =
        NSLocalizedString("ChangePasscode", value: "Change Passcode", comment: "Label used as a setting item and title of the following screen to change the current passcode")

    static let enterNewPasscode =
        NSLocalizedString("EnterANewPasscode", value: "Enter a new passcode", comment: "Text displayed above the input field when changing the existing passcode")

    static let immediately =
        NSLocalizedString("Immediately", value: "Immediately", comment: "Immediately' interval item for selecting when to require passcode")

    static let oneMinute =
        NSLocalizedString("After1Minute", value: "After 1 minute", comment: "After 1 minute' interval item for selecting when to require passcode")

    static let fiveMinutes =
        NSLocalizedString("After5Minutes", value: "After 5 minutes", comment: "After 5 minutes' interval item for selecting when to require passcode")

    static let tenMinutes =
        NSLocalizedString("After10Minutes", value: "After 10 minutes", comment: "After 10 minutes' interval item for selecting when to require passcode")

    static let fifteenMinutes =
        NSLocalizedString("After15Minutes", value: "After 15 minutes", comment: "After 15 minutes' interval item for selecting when to require passcode")

    static let oneHour =
        NSLocalizedString("After1Hour", value: "After 1 hour", comment: "After 1 hour' interval item for selecting when to require passcode")

    static let loginsTouchReason =
        NSLocalizedString("UseYourFingerprintToAccessLoginsNow", value: "Use your fingerprint to access Logins now.", comment: "Touch ID prompt subtitle when accessing logins")

    static let requirePasscodeTouchReason =
        NSLocalizedString("TouchidRequirePasscodeReasonLabel", value: "Use your fingerprint to access configuring your required passcode interval.", comment: "Touch ID prompt subtitle when accessing the require passcode setting")

    static let disableTouchReason =
        NSLocalizedString("TouchidDisableReasonLabel", value: "Use your fingerprint to disable Touch ID.", comment: "Touch ID prompt subtitle when disabling Touch ID")

    static let wrongPasscodeError =
        NSLocalizedString("IncorrectPasscodeTryAgain", value: "Incorrect passcode. Try again.", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app")

    static let incorrectAttemptsRemaining =
        NSLocalizedString("IncorrectPasscodeTryAgainAttemptsRemainingd", value: "Incorrect passcode. Try again (Attempts remaining: %d).", comment: "Error message displayed when user enters incorrect passcode when trying to enter a protected section of the app with attempts remaining")

    static let maximumAttemptsReached =
        NSLocalizedString("MaximumAttemptsReachedPleaseTryAgainInAnHour", value: "Maximum attempts reached. Please try again in an hour.", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.")

    static let maximumAttemptsReachedNoTime =
        NSLocalizedString("MaximumAttemptsReachedPleaseTryAgainLater", value: "Maximum attempts reached. Please try again later.", comment: "Error message displayed when user enters incorrect passcode and has reached the maximum number of attempts.")
}
