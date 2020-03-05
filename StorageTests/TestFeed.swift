/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import XCGLogger

import XCTest

private let log = XCGLogger.default

class TestSQLiteFeed: XCTestCase {
    var db: BrowserDB!
    var feed: SQLiteFeed!

    let login = Login.createWithHostname("hostname1", username: "username1", password: "password1", formSubmitURL: "http://submit.me")

    override func setUp() {
        super.setUp()

        let files = MockFiles()
        self.db = BrowserDB(filename: "testsqlitefeed.db", schema: FeedSchema(), files: files)
        self.feed = SQLiteFeed(db: self.db)

        let expectation = self.expectation(description: "Remove all items.")
        self.removeAllItems().upon({ res in expectation.fulfill() })
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testAddLogin() {
        log.debug("Created \(self.login)")
        let expectation = self.expectation(description: "Add login")

        addLogin(login)
            >>> getLoginsFor(login.protectionSpace, expected: [login])
            >>> done(expectation)

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testRemoveLogins() {
        let loginA = Login.createWithHostname("alphabet.com", username: "username1", password: "password1", formSubmitURL: formSubmitURL)
        let loginB = Login.createWithHostname("alpha.com", username: "username2", password: "password2", formSubmitURL: formSubmitURL)
        let loginC = Login.createWithHostname("berry.com", username: "username3", password: "password3", formSubmitURL: formSubmitURL)
        let loginD = Login.createWithHostname("candle.com", username: "username4", password: "password4", formSubmitURL: formSubmitURL)

        func addLogins() -> Success {
            addLogin(loginA).succeeded()
            addLogin(loginB).succeeded()
            addLogin(loginC).succeeded()
            addLogin(loginD).succeeded()
            return succeed()
        }

        addLogins().succeeded()
        let guids = [loginA.guid, loginB.guid]
        logins.removeLoginsWithGUIDs(guids).succeeded()
        let result = logins.getAllLogins().value.successValue!
        XCTAssertEqual(result.count, 2)
    }
    
    func testRemoveManyLogins() {
        log.debug("Remove a large number of logins at once")
        var guids: [GUID] = []
        for i in 0..<2000 {
            let login = Login.createWithHostname("mozilla.org", username: "Fire", password: "fox", formSubmitURL: formSubmitURL)
            if i <= 1000 {
                guids += [login.guid]
            }
            addLogin(login).succeeded()
        }
        logins.removeLoginsWithGUIDs(guids).succeeded()
        let result = logins.getAllLogins().value.successValue!
        XCTAssertEqual(result.count, 999)
    }

    func testUpdateLogin() {
        let expectation = self.expectation(description: "Update login")
        let updated = Login.createWithHostname("hostname1", username: "username1", password: "password3", formSubmitURL: formSubmitURL)
        updated.guid = self.login.guid

        addLogin(login) >>> { self.updateLogin(updated) } >>>
            getLoginsFor(login.protectionSpace, expected: [updated]) >>>
            done(expectation)

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func done(_ expectation: XCTestExpectation) -> () -> Success {
        return {
            self.removeAllLogins()
               >>> self.getLoginsFor(self.login.protectionSpace, expected: [])
               >>> {
                    expectation.fulfill()
                    return succeed()
                }
        }
    }

    // Note: These functions are all curried so that we pass arguments, but still chain them below
    func addItem(_ login: LoginData) -> Success {
        log.debug("Add \(login)")
        return logins.addLogin(login)
    }

    func updateLogin(_ login: LoginData) -> Success {
        log.debug("Update \(login)")
        return logins.updateLoginByGUID(login.guid, new: login, significant: true)
    }

    func addUseDelayed(_ login: Login, time: UInt32) -> Success {
        sleep(time)
        login.timeLastUsed = Date.nowMicroseconds()
        let res = logins.addUseOfLoginByGUID(login.guid)
        sleep(time)
        return res
    }

    func getLoginsFor(_ protectionSpace: URLProtectionSpace, expected: [LoginData]) -> (() -> Success) {
        return {
            log.debug("Get logins for \(protectionSpace)")
            return self.logins.getLoginsForProtectionSpace(protectionSpace) >>== { results in
                XCTAssertEqual(expected.count, results.count)
                for (index, login) in expected.enumerated() {
                    XCTAssertEqual(results[index]!.username!, login.username!)
                    XCTAssertEqual(results[index]!.hostname, login.hostname)
                    XCTAssertEqual(results[index]!.password, login.password)
                }
                return succeed()
            }
        }
    }

    func removeLogin(_ login: LoginData) -> Success {
        log.debug("Remove \(login)")
        return logins.removeLoginByGUID(login.guid)
    }

    func removeAllItems() -> Success {
        log.debug("Remove All")
        return self.db.run("DELETE FROM items")
    }
}
