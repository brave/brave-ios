// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import Foundation

extension DataProtocol {
  public var hexEncodedString: String {
    let hexDigits = ["0", "1", "2", "3",
                     "4", "5", "6", "7",
                     "8", "9", "A", "B",
                     "C", "D", "E", "F"]

    var result = String()
    result.reserveCapacity(count * 2)
    for byte in self {
      result.append(hexDigits[Int((byte & 0xF0) >> 4)])
      result.append(hexDigits[Int(byte & 0x0F)])
    }

    return String(result)
  }
}
