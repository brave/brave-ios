// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct ExtensionID {
  
}

struct CRXFileInfo {
  let filePath: String
  let requiredFormat: VerifierFormat
  let extensionId: ExtensionID
  let expectedHash: String
  let expectedVersion: String
}

class CRXInstaller {
  func installCrx(from filePath: String) {
    
  }
  
  func installCrx(from fileInfo: CRXFileInfo) {
    
  }
}
