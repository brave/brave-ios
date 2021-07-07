/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

/**
 * Test for our own utils.
 */
class UtilsTests: XCTestCase {
    func testMapUtils() {
        let m: [String: Int] = ["foo": 123, "bar": 456]
        let f: (Int) -> Int? = { v in
            return (v > 200) ? 999 : nil
        }

        let o = mapValues(m, f: f)
        XCTAssertEqual(2, o.count)
        XCTAssertTrue(o["foo"]! == nil)
        XCTAssertTrue(o["bar"]! == 999)

        let filtered = optFilter(o)
        XCTAssertEqual(1, filtered.count)
        XCTAssertTrue(filtered["bar"] == 999)
    }

    func testOptFilter() {
        let a: [Int?] = [nil, 1, nil, 2, 3, 4]
        let b = optFilter(a)
        XCTAssertEqual(4, b.count)
        XCTAssertEqual([1, 2, 3, 4], b)
    }

    func testOptArrayEqual() {
        let x: [String] = ["a", "b", "c"]
        let y: [String]? = ["a", "b", "c"]
        let z: [String]? = nil

        XCTAssertTrue(optArrayEqual(x, rhs: y))
        XCTAssertTrue(optArrayEqual(x, rhs: x))
        XCTAssertTrue(optArrayEqual(y, rhs: y))
        XCTAssertTrue(optArrayEqual(z, rhs: z))
        XCTAssertFalse(optArrayEqual(x, rhs: z))
        XCTAssertFalse(optArrayEqual(z, rhs: y))
    }

    func testChunk() {
        let examples: [([Int], Int, [[Int]])] = [
            ([], 2, []),
            ([1, 2], 0, [[1], [2]]),
            ([1, 2], 1, [[1], [2]]),
            ([1, 2, 3], 2, [[1, 2], [3]]),
            ([1, 2], 3, [[1, 2]]),
            ([1, 2, 3], 1, [[1], [2], [3]]),
        ]
        for (arr, by, expected) in examples {
            // Turn the ArraySlices back into Arrays for comparison.
            let actual = chunk(arr as [Int], by: by).map { Array($0) }
            XCTAssertEqual(expected as NSArray, actual as NSArray) //wtf. why is XCTAssert being so weeird
        }
    }

    func testChunkCollection() {
        let examples: [([Int], Int, [[Int]])] = [
            ([], 2, []),
            ([1, 2], 0, [[1], [2]]),
            ([1, 2], 1, [[1], [2]]),
            ([1, 2, 3], 2, [[1, 2], [3]]),
            ([1, 2], 3, [[1, 2]]),
            ([1, 2, 3], 1, [[1], [2], [3]]),
            ]
        for (arr, by, expected) in examples {
            let actual = chunkCollection(arr, by: by) { xs in [xs] }
            XCTAssertEqual(expected as NSArray, actual as NSArray)
        }
    }
}
