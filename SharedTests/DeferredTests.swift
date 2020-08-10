/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Shared
import XCTest

// Trivial test for using Deferred.

class DeferredTests: XCTestCase {
    func testDeferred() {
        let d = Deferred<Int>()
        XCTAssertNil(d.peek(), "Value not yet filled.")

        let expectation = self.expectation(description: "Waiting on value.")
        d.upon({ x in
            expectation.fulfill()
        })

        d.fill(5)
        waitForExpectations(timeout: 10) { (error) in
            XCTAssertNil(error, "\(error.debugDescription)")
        }

        XCTAssertEqual(5, d.peek()!, "Value is filled.")
    }

    func testMultipleUponBlocks() {
        let e1 = self.expectation(description: "First.")
        let e2 = self.expectation(description: "Second.")
        let d = Deferred<Int>()
        d.upon { x in
            XCTAssertEqual(x, 5)
            e1.fulfill()
        }
        d.upon { x in
            XCTAssertEqual(x, 5)
            e2.fulfill()
        }
        d.fill(5)
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testOperators() {
        let e1 = self.expectation(description: "First.")
        let e2 = self.expectation(description: "Second.")

        let f1: () -> Deferred<Maybe<Int>> = {
            return deferMaybe(5)
        }

        let f2: (_ x: Int) -> Deferred<Maybe<String>> = {
            if $0 == 5 {
                e1.fulfill()
            }
            return deferMaybe("Hello!")
        }

        // Type signatures:
        let combined: () -> Deferred<Maybe<String>> = { f1() >>== f2 }
        let result: Deferred<Maybe<String>> = combined()

        result.upon {
            XCTAssertEqual("Hello!", $0.successValue!)
            e2.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testPassAccumulate() {
        let leak = self.expectation(description: "deinit")

        class TestClass {
            let end: XCTestExpectation
            init(e: XCTestExpectation) {
                end = e
                accumulate([self.aSimpleFunction]).upon { _ in

                }
            }

            func aSimpleFunction() -> Success {
                return succeed()
            }
            deinit {
                end.fulfill()
            }
        }

        var myclass: TestClass? = TestClass(e: leak)
        myclass = nil
        waitForExpectations(timeout: 3, handler: nil)
    }


    func testFailAccumulate() {
        let leak = self.expectation(description: "deinit")

        class TestError: MaybeErrorType {
            var description = "Error"
        }

        class TestClass {
            let end: XCTestExpectation
            init(e: XCTestExpectation) {
                end = e
                accumulate([self.aSimpleFunction]).upon { _ in

                }
            }

            func aSimpleFunction() -> Success {
                return Deferred(value: Maybe(failure: TestError()))
            }
            deinit {
                end.fulfill()
            }
        }

        var myclass: TestClass? = TestClass(e: leak)
        myclass = nil
        waitForExpectations(timeout: 3, handler: nil)
    }

}
