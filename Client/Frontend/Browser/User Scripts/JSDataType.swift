// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// An object representing simple JS object syntax used to generate Javascript code.
/// This object avoids needless casting and helps to avoid syntax mistakes
/// and is able to represent any combination of a javascript dictionaries, arrays and strings.
///
///
/// ```
/// let dataType = JSDataType.string("Hellow world!")
/// let script = "const values = \(String(describing: dataType))"
/// ```
enum JSDataType: CustomStringConvertible {
    case string(String)
    case object([String: JSDataType])
    case array([JSDataType])

    /// Return a string representation of this object.
    /// The result of this string is ready to be plugged into a javascript variable:
    ///
    /// - Note: Should not be called directly but by invoking `String(describing:)`.
    var description: String {
        switch self {
        case .array(let jsArray):
            let string = jsArray.map { value in
                String(describing: value)
            }.joined(separator: ", ")

            return "[\(string)]"

        case .object(let jsObject):
            let string = jsObject.sorted(by: { $0.key < $1.key }).map { key, value in
                "\(key): \(String(describing: value))"
            }.joined(separator: ", ")

            return "{\(string)}"

        case .string(let value):
            return "\"\(value)\""
        }
    }
}
