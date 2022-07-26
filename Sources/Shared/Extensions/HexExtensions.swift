/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let HexDigits: [String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]

extension Data {
  public var hexEncodedString: String {
    var result = String()
    result.reserveCapacity(count * 2)
    withUnsafeBytes {
      for i in 0..<count {
        result.append(HexDigits[Int(($0[i] & 0xf0) >> 4)])
        result.append(HexDigits[Int($0[i] & 0x0f)])
      }
    }

    return String(result)
  }
}

extension Data {
  public var base64EncodedString: String {
    return self.base64EncodedString(options: [])
  }
}
