/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    public var hexDecodedData: Data {
        // Convert to a CString and make sure it has an even number of characters (terminating 0 is included, so we
        // check for uneven!)
        guard let cString = self.cString(using: .ascii), (cString.count % 2) == 1 else {
            return Data()
        }

        var result = Data(capacity: (cString.count - 1) / 2)
        for i in stride(from: 0, to: (cString.count - 1), by: 2) {
            guard let l = hexCharToByte(cString[i]), let r = hexCharToByte(cString[i+1]) else {
                return Data()
            }
            var value: UInt8 = (l << 4) | r
            result.append(&value, count: MemoryLayout.size(ofValue: value))
        }
        return result
    }

    private func hexCharToByte(_ c: CChar) -> UInt8? {
        if c >= 48 && c <= 57 { // 0 - 9
            return UInt8(c - 48)
        }
        if c >= 97 && c <= 102 { // a - f
            return UInt8(10) + UInt8(c - 97)
        }
        if c >= 65 && c <= 70 { // A - F
            return UInt8(10) + UInt8(c - 65)
        }
        return nil
    }
}

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
