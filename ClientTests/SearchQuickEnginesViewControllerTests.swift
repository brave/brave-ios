// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SnapshotTesting
import XCTest

@testable import Client

// MARK: SearchQuickEnginesViewControllerTests

class SearchQuickEnginesViewControllerTests: XCTestCase {

    // MARK: Lifecycle
    
    override func setUp() {
        super.setUp()

        isRecording = snapshotRecordMode
    }

    override func tearDown() {
        subject = nil
        profile = nil

        super.tearDown()
    }

    // MARK: Internal
    
    /// This test is demostrating a direct Search Engine List Snapshot
    func testDefaultQuickSearchEngines() {
        profile = MockProfile()

        subject = SearchQuickEnginesViewController(profile: profile)

        verifyViewController(subject)
    }

    /// This test is demostrating a direct Search Engine List Snapshot
    /// Demostrates the when snapshot fails for some aritifical reason that should be ignored with tolerance
    func testDefaultQuickSearchEnginesWithTolerance() {
        profile = MockProfile()

        subject = SearchQuickEnginesViewController(profile: profile)

        verifyViewController(
            subject,
            testDevices: TestDevice.defaultDevices.with(tolerance: .defaultSnapshotTolerance))    }

    /// This test is demostrating a snapshot of  a custom search engines added to the list
    func testSingleCustomQuickSearchEngine() {
        let testEngine = OpenSearchEngine(
            engineID: "ACustomEngine",
            shortName: "Sauron's Eye - SE Example",
            image: #imageLiteral(resourceName: "defaultFavicon"),
            searchTemplate: "http://brave.com/find?q={searchTerm}",
            suggestTemplate: nil,
            isCustomEngine: true)

        profile = MockProfile()

        try! profile.searchEngines.addSearchEngine(testEngine)

        subject = SearchQuickEnginesViewController(profile: profile)

        verifyViewController(subject)

        try! profile.searchEngines.deleteCustomEngine(testEngine)
    }

    /// This test is demostrating a snapshot of list of custom search engines added to the list
    /// Demostrates the condition when content doesnt fit screen and has to scroll down
    /// In order to snapshot entire list we have to use a utility method that supports height multiplier
    func testMultipleCustomQuickSearchEngine() {
        var testEngineList = [OpenSearchEngine]()

        for i in 1...6 {
            testEngineList.append(OpenSearchEngine(
                                    engineID: "ACustomEngine \(i)",
                                    shortName: "Sauron's Eye - SE Example",
                                    image: #imageLiteral(resourceName: "defaultFavicon"),
                                    searchTemplate: "http://brave.com/find?q={searchTerm}",
                                    suggestTemplate: nil,
                                    isCustomEngine: true))
        }

        profile = MockProfile()

        _ = testEngineList.map { testEngine in
            try! profile.searchEngines.addSearchEngine(testEngine)
        }

        subject = SearchQuickEnginesViewController(profile: profile)

        verifyViewController(
            subject,
            testDevices: TestDevice.defaultDevices.with(heightMultipliers: [(.iPhoneSe, 1.2)]))


        _ = testEngineList.map { testEngine in
            try! profile.searchEngines.deleteCustomEngine(testEngine)
        }
    }

    // MARK: Private
    
    private var subject: SearchQuickEnginesViewController!
    private var profile: Profile!
}
