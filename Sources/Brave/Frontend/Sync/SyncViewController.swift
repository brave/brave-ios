/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import BraveShared
import Data
import LocalAuthentication
import Combine

class SyncViewController: AuthenticationController {

  private let isModallyPresented: Bool
  private var localAuthObservers = Set<AnyCancellable>()

  // MARK: Lifecycle

  init(windowProtection: WindowProtection? = nil,
       requiresAuthentication: Bool = false,
       isAuthenticationCancellable: Bool = true,
       isModallyPresented: Bool = false) {
    self.isModallyPresented = isModallyPresented
    
    super.init(windowProtection: windowProtection, requiresAuthentication: requiresAuthentication)
    
    windowProtection?.isCancellable = isAuthenticationCancellable
    
    windowProtection?.cancelPressed
      .sink { [weak self] _ in
        self?.dismissSyncController()
      }.store(in: &localAuthObservers)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    view.backgroundColor = .secondaryBraveBackground
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if requiresAuthentication {
      askForAuthentication() { [weak self] success, error in
        guard let self else { return }
        
        if !success, error != .userCancel {
          self.dismissSyncController()
        }
      }
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
  
  private func dismissSyncController() {
    if isModallyPresented {
      self.dismiss(animated: true)
    } else {
      self.navigationController?.popViewController(animated: true)
    }
  }
}
