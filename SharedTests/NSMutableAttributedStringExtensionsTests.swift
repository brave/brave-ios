/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
@testable import Shared

class NSMutableAttributedStringExtensionsTests: XCTestCase {
    fileprivate func checkCharacterAtPosition(_ position: Int, isColored color: UIColor, inString string: NSAttributedString) -> Bool {
        let attributes = string.attributes(at: position, effectiveRange: nil)
        if let foregroundColor = attributes[NSForegroundColorAttributeName] as? UIColor {
            if foregroundColor == color {
                return true
            }
        }
        return false
    }

    func testColorsSubstring() {
        let substring = "bc"
        let example = NSMutableAttributedString(string: "abcd")
        example.colorSubstring(substring, withColor: UIColor.red)

        XCTAssertFalse(checkCharacterAtPosition(0, isColored: UIColor.red, inString: example))
        for position in 1..<3 {
            XCTAssertTrue(checkCharacterAtPosition(position, isColored: UIColor.red, inString: example))
        }
        XCTAssertFalse(checkCharacterAtPosition(3, isColored: UIColor.red, inString: example))
    }

    func testDoesNothingWithEmptySubstring() {
        let substring = ""
        let example = NSMutableAttributedString(string: "abcd")
        example.colorSubstring(substring, withColor: UIColor.red)
        for position in 0..<example.string.count {
            XCTAssertFalse(checkCharacterAtPosition(position, isColored: UIColor.red, inString: example))
        }
    }

    func testDoesNothingWhenSubstringNotFound() {
        let substring = "yyz"
        let example = NSMutableAttributedString(string: "abcd")
        example.colorSubstring(substring, withColor: UIColor.red)
        for position in 0..<example.string.count {
            XCTAssertFalse(checkCharacterAtPosition(position, isColored: UIColor.red, inString: example))
        }
    }
}
