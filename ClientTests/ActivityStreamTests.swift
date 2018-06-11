/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
@testable import Client
import Shared
import Storage
import Deferred

class ActivityStreamTests: XCTestCase {
    var profile: MockProfile!
    var panel: ActivityStreamPanel!
    var mockPingClient: MockPingClient!
    var telemetry: ActivityStreamTracker!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        self.telemetry = ActivityStreamTracker(eventsTracker: MockPingClient(), sessionsTracker: MockPingClient())
        self.panel = ActivityStreamPanel(profile: profile, telemetry: self.telemetry)
    }

    override func tearDown() {
        mockPingClient = nil
    }

    func testDeletionOfSingleSuggestedSite() {
        let siteToDelete = panel.defaultTopSites()[0]

        panel.hideURLFromTopSites(siteToDelete)
        let newSites = panel.defaultTopSites()

        XCTAssertFalse(newSites.contains(siteToDelete, f: { (a, b) -> Bool in
            return a.url == b.url
        }))
    }

    func testDeletionOfAllDefaultSites() {
        let defaultSites = panel.defaultTopSites()
        defaultSites.forEach({
            panel.hideURLFromTopSites($0)
        })

        let newSites = panel.defaultTopSites()
        XCTAssertTrue(newSites.isEmpty)
    }
}

// MARK: Telemetry Tests
extension ActivityStreamTests {
    fileprivate func expectedPayloadForEvent(_ event: String, source: String, position: Int) -> [String: Any] {
        return [
            "event": event,
            "page": "NEW_TAB",
            "source": source,
            "action_position": position,
            "app_version": AppInfo.appVersion,
            "build": AppInfo.buildNumber,
            "locale": Locale.current.identifier,
            "release_channel": AppConstants.BuildChannel.rawValue
        ]
    }

    fileprivate func expectedBadStatePayload(state: String, source: String) -> [String: Any] {
        return [
            "event": state,
            "page": "NEW_TAB",
            "source": source,
            "app_version": AppInfo.appVersion,
            "build": AppInfo.buildNumber,
            "locale": Locale.current.identifier,
            "release_channel": AppConstants.BuildChannel.rawValue
        ]
    }

    fileprivate func assertPayload(_ actual: [String: Any], matches: [String: Any]) {
        XCTAssertTrue(actual.count == matches.count)
        actual.enumerated().forEach { index, element in
            if let actualValue = element.1 as? Int,
               let matchesValue = matches[element.0] as? Int {
                XCTAssertTrue(actualValue == matchesValue)
            }

            if let actualValue = element.1 as? String,
               let matchesValue = matches[element.0] as? String {
                XCTAssertTrue(actualValue == matchesValue)
            }
        }
    }
    
    func testHighlightEmitsEventOnTap() {
        let mockSite = Site(url: "http://mozilla.org", title: "Mozilla")
        panel.highlights = [mockSite]
        panel.selectItemAtIndex(0, inSection: .highlights)

        let pingsSent = (telemetry.eventsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 1)
        let eventPing = pingsSent[0]
        assertPayload(eventPing, matches: expectedPayloadForEvent("CLICK", source: "HIGHLIGHTS", position: 0))
    }

    func testContextMenuOnTopSiteEmitsRemoveEvent() {
        let mockSite = Site(url: "http://mozilla.org", title: "Mozilla")
        let topSitesContextMenu = panel.contextMenu(for: mockSite, with: IndexPath(item: 0, section: ActivityStreamPanel.Section.topSites.rawValue))

        let removeAction = topSitesContextMenu?.actions[0].find { $0.title == Strings.RemoveContextMenuTitle }
        removeAction?.handler?(removeAction!)

        let pingsSent = (telemetry.eventsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 1)
        let removePing = pingsSent[0]
        assertPayload(removePing, matches: expectedPayloadForEvent("REMOVE", source: "TOP_SITES", position: 0))
    }

    func testContextMenuOnHighlightsEmitsRemoveDismissEvents() {
        let mockSite = Site(url: "http://mozilla.org", title: "Mozilla")
        let highlightsContextMenu = panel.contextMenu(for: mockSite, with: IndexPath(row: 0, section: ActivityStreamPanel.Section.highlights.rawValue))

        let dismiss = highlightsContextMenu?.actions[0].find { $0.title == Strings.RemoveContextMenuTitle }
        let delete = highlightsContextMenu?.actions[0].find { $0.title == Strings.DeleteFromHistoryContextMenuTitle }

        dismiss?.handler?(dismiss!)
        delete?.handler?(delete!)

        // Check to see that they emitted telemetry events
        let pingsSent = (telemetry.eventsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 2)

        let dismissPing = pingsSent[0]
        assertPayload(dismissPing, matches: expectedPayloadForEvent("DISMISS", source: "HIGHLIGHTS", position: 0))

        let deletePing = pingsSent[1]
        assertPayload(deletePing, matches: expectedPayloadForEvent("DELETE", source: "HIGHLIGHTS", position: 0))
    }

    func testSessionReportedWhenViewAppearsAndDisappears() {
        // Simulate the panel opening and closing with a second in between for some session_duration
        panel.viewWillAppear(false)
        var pingsSent = (telemetry.sessionsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 0)

        wait(1)
        panel.viewDidDisappear(false)

        pingsSent = (telemetry.sessionsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 1)

        let eventPing = pingsSent[0]
        XCTAssertNotNil(eventPing["session_duration"])
    }

    func testBadStateEventsForHighlights() {
        let goodSite = Site(url: "http://mozilla.org", title: "Mozilla")
        goodSite.icon = Favicon(url: "http://image", date: Date())
        goodSite.metadata = PageMetadata(id: nil,
                                         siteURL: "http://mozilla.org",
                                         mediaURL: "http://image",
                                         title: "Mozilla",
                                         description: "Web",
                                         type: nil,
                                         providerName: nil)
        let badSite = Site(url: "http://mozilla.org", title: "Mozilla")
        profile.recommendations = MockRecommender(highlights: [goodSite, badSite])

        // Since invalidateHighlights calls back into the main thread, we can't
        // simply call .value on this to block since the app will dead lock when
        // trying to call back onto a blocked main thread.
        let expect = XCTestExpectation(description: "Sent bad highlight pings")
        panel.getHighlights() >>> {
            expect.fulfill()
        }

        wait(for: [expect], timeout: 3)
        let pingsSent = (self.telemetry.eventsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 2)
        assertPayload(pingsSent[0],
                      matches: expectedBadStatePayload(state: "MISSING_METADATA_IMAGE", source: "HIGHLIGHTS"))
        assertPayload(pingsSent[1],
                      matches: expectedBadStatePayload(state: "MISSING_FAVICON", source: "HIGHLIGHTS"))
    }

    func testBadStateEventsForTopSites() {
        let goodSite = Site(url: "http://mozilla.org", title: "Mozilla")
        goodSite.icon = Favicon(url: "http://image", date: Date())
        goodSite.metadata = PageMetadata(id: nil,
                                         siteURL: "http://mozilla.org",
                                         mediaURL: "http://image",
                                         title: "Mozilla",
                                         description: "Web",
                                         type: nil,
                                         providerName: nil)
        let badSite = Site(url: "http://mozilla.org", title: "Mozilla")
        profile.history = MockTopSitesHistory(sites: [goodSite, badSite])

        // Since invalidateHighlights calls back into the main thread, we can't
        // simply call .value on this to block since the app will dead lock when
        // trying to call back onto a blocked main thread.
        let expect = XCTestExpectation(description: "Sent bad top site pings")
        panel.getTopSites() >>> {
            expect.fulfill()
        }

        wait(for: [expect], timeout: 3)
        let pingsSent = (self.telemetry.eventsTracker as! MockPingClient).pingsReceived
        XCTAssertEqual(pingsSent.count, 2)
        assertPayload(pingsSent[0],
                      matches: expectedBadStatePayload(state: "MISSING_METADATA_IMAGE", source: "TOP_SITES"))
        assertPayload(pingsSent[1],
                      matches: expectedBadStatePayload(state: "MISSING_FAVICON", source: "TOP_SITES"))
    }
}

class MockPingClient: PingCentreClient {

    var pingsReceived: [[String: Any]] = []

    public func sendPing(_ data: [String : Any], validate: Bool) -> Success {
        pingsReceived.append(data)
        return succeed()
    }

    public func sendBatch(_ data: [[String : Any]], validate: Bool) -> Success {
        pingsReceived += data
        return succeed()
    }
}

fileprivate class MockRecommender: HistoryRecommendations {
    func repopulateHighlights() -> Success {
        return succeed()
    }

    var highlights: [Site]

    init(highlights: [Site]) {
        self.highlights = highlights
    }

    func getHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        return deferMaybe(ArrayCursor(data: highlights))
    }

    func getRecentBookmarks(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        return deferMaybe(ArrayCursor(data: []))
    }
    
    func repopulate(invalidateTopSites shouldInvalidateTopSites: Bool, invalidateHighlights shouldInvalidateHighlights: Bool) -> Success {
        return succeed()
    }

    func removeHighlightForURL(_ url: String) -> Success {
        guard let foundSite = highlights.filter({ $0.url == url }).first else {
            return succeed()
        }
        let foundIndex = highlights.index(of: foundSite)!
        highlights.remove(at: foundIndex)
        return succeed()
    }
}

fileprivate class MockTopSitesHistory: MockableHistory {
    let mockTopSites: [Site]

    init(sites: [Site]) {
        mockTopSites = sites
    }

    override func getTopSitesWithLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        return deferMaybe(ArrayCursor(data: mockTopSites))
    }

    override func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>> {
        return deferMaybe(ArrayCursor(data: []))
    }

    override func updateTopSitesCacheIfInvalidated() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }
}
