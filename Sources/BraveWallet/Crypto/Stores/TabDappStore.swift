// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// This Store will be created for each Tab
public class TabDappStore: ObservableObject {
  /// A set of solana account addresses that are currently connected to the dapp
  @Published public var solConnectedAddresses: Set<String> = .init()
  /// The latest dapp permission request 
  @Published public var latestPermissionRequest: WebpagePermissionRequest?
  
  public init() {}
}
