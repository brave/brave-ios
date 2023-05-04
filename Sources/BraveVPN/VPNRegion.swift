// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import GuardianConnect
import BraveUI
import SwiftUI

extension GRDRegion {
  
  /// The title used in menu while chaging region
  public var settingTitle: String {
    var title = "Current Setting: "
    
    if BraveVPN.isAutomaticRegion {
      title.append("Automatic")
    } else {
      title.append(displayName)
    }
    
    return title
  }
  
  /// Flag of the region as an image
  public var regionFlag: Image? {
    // Root Unicode flags index
    let rootIndex: UInt32 = 127397
    var unicodeScalarView = ""
    
    for scalar in countryISOCode.unicodeScalars {
      // Shift the letter index to the flags index
      if let appendedScalar = UnicodeScalar(rootIndex + scalar.value) {
        // Append symbol to the Unicode string
        unicodeScalarView.unicodeScalars.append(appendedScalar)
      }
    }
    
    return Image(uiImage: unicodeScalarView.image())
  }
}
