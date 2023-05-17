/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import BraveShared
import Data

class SyncViewController: UIViewController {

  private let windowProtection: WindowProtection?
  private let requiresAuthentication: Bool

  // MARK: Lifecycle

  init(windowProtection: WindowProtection? = nil, requiresAuthentication: Bool = false) {
    self.windowProtection = windowProtection
    self.requiresAuthentication = requiresAuthentication
    
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    view.backgroundColor = .secondaryBraveBackground

    if requiresAuthentication {
      askForAuthentication()
    }
  }

  /// Perform a block of code only if user has a network connection, shows an error alert otherwise.
  /// Most of sync initialization methods require an internet connection.
  func doIfConnected(code: () -> Void) {
    if !DeviceInfo.hasConnectivity() {
      present(SyncAlerts.noConnection, animated: true)
      return
    }

    code()
  }
  
  /// A method to ask biometric authentication to user
  /// - Parameter completion: block returning authentication status
  func askForAuthentication(completion: ((Bool) -> Void)? = nil) {
    guard let windowProtection = windowProtection else {
      completion?(false)
      return
    }

    if !windowProtection.isPassCodeAvailable {
      showSetPasscodeError() {
        completion?(false)
      }
    } else {
      windowProtection.presentAuthenticationForViewController(
        determineLockWithPasscode: false) { status in
          completion?(status)
      }
    }
  }
  
  /// An alert presenter for passcode error to warn user to setup passcode to use feature
  /// - Parameter completion: block after Ok button is pressed
  private func showSetPasscodeError(completion: @escaping (() -> Void)) {
    let alert = UIAlertController(
      title: "Set a Passcode",
      message: "To setup sync hain or see settings, you must first set a passcode on your device.",
      preferredStyle: .alert)

    alert.addAction(
      UIAlertAction(title: Strings.OKString, style: .default, handler: { _ in
          completion()
      })
    )
    
    present(alert, animated: true, completion: nil)
  }
}
