// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import AuthenticationServices
import SwiftUI
import Security
import BraveCore
import CredentialProviderUI

class CredentialProviderViewController: ASCredentialProviderViewController {
  let model = CredentialListModel()
  var identifiers: [ASCredentialServiceIdentifier]?
  lazy var credentialStore = CredentialProviderAPI.credentialStore()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .red
    
    model.actionHandler = { [unowned self] action in
      switch action {
      case .selectedCredential(let credential):
        self.userSelected(item: credential)
      case .cancelled:
        self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let identifiers {
      let hostingController = UIHostingController(rootView: CredentialListView(model: model))
      addChild(hostingController)
      view.addSubview(hostingController.view)
      hostingController.didMove(toParent: self)
      hostingController.view.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
        hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
      
      model.populateFromStore(credentialStore, identifiers: identifiers)
    }
  }
  
  func userSelected(item: any Credential) {
    guard let password = model.passwordWithIdentifier(item.keychainIdentifier) else {
      self.extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
      return
    }
    let credential = ASPasswordCredential(user: item.user, password: password)
    self.extensionContext.completeRequest(withSelectedCredential: credential)
  }
  
  /*
   Prepare your UI to list available credentials for the user to choose from. The items in
   'serviceIdentifiers' describe the service the user is logging in to, so your extension can
   prioritize the most relevant credentials in the list.
   */
  override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    self.identifiers = serviceIdentifiers
  }
  
  //  @available(iOSApplicationExtension 17.0, *)
  //  override func provideCredentialWithoutUserInteraction(for credentialRequest: ASCredentialRequest) {
  //    if credentialRequest.type != .password {
  //      extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userInteractionRequired.rawValue))
  //      return
  //    }
  //    provideCredentialWithoutUserInteraction(identity: credentialRequest.credentialIdentity as ASPasswordCredentialIdentity)
  //  }
  //
  override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
    // TODO: Check auth
    guard let credential = credentialStore.credential(withRecordIdentifier: credentialIdentity.recordIdentifier) else {
      extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userInteractionRequired.rawValue))
      return
    }
    userSelected(item: credential)
  }
  
  override func prepareInterfaceForExtensionConfiguration() {
    super.prepareInterfaceForExtensionConfiguration()
    
    let hostingController = UIHostingController(rootView: CredentialProviderOnboardingView(action: {
      self.extensionContext.completeExtensionConfigurationRequest()
    }))
    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
  
  /*
   Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
   ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
   UI and call this method. Show appropriate UI for authenticating the user then provide the password
   by completing the extension request with the associated ASPasswordCredential.
   */
  override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
  }
}
