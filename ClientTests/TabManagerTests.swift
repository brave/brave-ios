/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Shared
import Storage
import UIKit
import WebKit
import Deferred

import XCTest

open class TabManagerMockProfile: MockProfile {
    var numberOfTabsStored = 0
    override public func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        numberOfTabsStored = tabs.count
        return deferMaybe(tabs.count)
    }
}

open class MockTabManagerStateDelegate: TabManagerStateDelegate {
    var numberOfTabsStored = 0
    public func tabManagerWillStoreTabs(_ tabs: [Tab]) {
        numberOfTabsStored = tabs.count
    }
}

struct MethodSpy {
    let functionName: String
    let method: ((_ tabs: [Tab?]) -> Void)?

    init(functionName: String) {
        self.functionName = functionName
        self.method = nil
    }

    init(functionName: String, method: ((_ tabs: [Tab?]) -> Void)?) {
        self.functionName = functionName
        self.method = method
    }
}

open class MockTabManagerDelegate: TabManagerDelegate {

    //this array represents the order in which delegate methods should be called.
    //each delegate method will pop the first struct from the array. If the method name doesn't match the struct then the order is incorrect
    //Then it evaluates the method closure which will return true/false depending on if the tabs are correct
    var methodCatchers: [MethodSpy] = []

    func expect(_ methods: [MethodSpy]) {
        self.methodCatchers = methods
    }

    func verify(_ message: String) {
        XCTAssertTrue(methodCatchers.isEmpty, message)
    }

    func testDelegateMethodWithName(_ name: String, tabs: [Tab?]) {
        guard let spy = self.methodCatchers.first else {
            XCTAssert(false, "No method was availible in the queue. For the delegate method \(name) to use")
            return
        }
        XCTAssertEqual(spy.functionName, name)
        if let methodCheck = spy.method {
            methodCheck(tabs)
        }
        methodCatchers.removeFirst()
    }

    public func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
        testDelegateMethodWithName(#function, tabs: [selected, previous])
    }

    public func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        testDelegateMethodWithName(#function, tabs: [tab])
    }

    public func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
        testDelegateMethodWithName(#function, tabs: [tab])
    }

    public func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        testDelegateMethodWithName(#function, tabs: [])
    }

    public func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {
        testDelegateMethodWithName(#function, tabs: [tab])
    }

    public func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {
        testDelegateMethodWithName(#function, tabs: [tab])
    }

    public func tabManagerDidAddTabs(_ tabManager: TabManager) {
        testDelegateMethodWithName(#function, tabs: [])
    }

    public func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        testDelegateMethodWithName(#function, tabs: [])
    }
}

class TabManagerTests: XCTestCase {

    let willRemove = MethodSpy(functionName: "tabManager(_:willRemoveTab:)")
    let didRemove = MethodSpy(functionName: "tabManager(_:didRemoveTab:)")
    let willAdd = MethodSpy(functionName: "tabManager(_:willAddTab:)")
    let didAdd = MethodSpy(functionName: "tabManager(_:didAddTab:)")

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // BRAVE TODO: We no longer "store tabs", happens async from CoreData, so this test has to reflect CD instead
    /*
    func testTabManagerCallsTabManagerStateDelegateOnStoreChangesWithNormalTabs() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let stateDelegate = MockTabManagerStateDelegate()
        manager.stateDelegate = stateDelegate
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()

        // test that non-private tabs are saved to the db
        // add some non-private tabs to the tab manager
        for _ in 0..<3 {
            let tab = Tab(configuration: configuration)
            tab.url = URL(string: "http://yahoo.com")!
            manager.configureTab(tab, request: URLRequest(url: tab.url!), flushToDisk: false, zombie: false)
        }
        
        XCTAssertEqual(stateDelegate.numberOfTabsStored, 3, "Expected state delegate to have been called with 3 tabs, but called with \(stateDelegate.numberOfTabsStored)")
    }
     */

    func testTabManagerDoesNotCallTabManagerStateDelegateOnStoreChangesWithPrivateTabs() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let stateDelegate = MockTabManagerStateDelegate()
        manager.stateDelegate = stateDelegate
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()

        // test that non-private tabs are saved to the db
        // add some non-private tabs to the tab manager
        for _ in 0..<3 {
            let tab = Tab(configuration: configuration, isPrivate: true)
            tab.url = URL(string: "http://yahoo.com")!
            manager.configureTab(tab, request: URLRequest(url: tab.url!), flushToDisk: false, zombie: false)
        }

        XCTAssertEqual(stateDelegate.numberOfTabsStored, 0, "Expected state delegate to have been called with 3 tabs, but called with \(stateDelegate.numberOfTabsStored)")
    }

    func testAddTab() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()
        manager.addDelegate(delegate)

        delegate.expect([willAdd, didAdd])
        manager.addTab()
        delegate.verify("Not all delegate methods were called")
    }

    func testDidDeleteLastTab() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()

        //create the tab before adding the mock delegate. So we don't have to check delegate calls we dont care about
        let tab = manager.addTab()
        manager.selectTab(tab)
        manager.addDelegate(delegate)

        let didSelect = MethodSpy(functionName: "tabManager(_:didSelectedTabChange:previous:)") { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertTrue(previous != next)
            XCTAssertTrue(previous == tab)
            XCTAssertFalse(next.isPrivate)
        }
        delegate.expect([willRemove, didRemove, willAdd, didAdd, didSelect])
        manager.removeTab(tab)
        delegate.verify("Not all delegate methods were called")
    }

    func testDidDeleteLastPrivateTab() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()

        //create the tab before adding the mock delegate. So we don't have to check delegate calls we dont care about
        let tab = manager.addTab()
        manager.selectTab(tab)
        let privateTab = manager.addTab(isPrivate: true)
        manager.selectTab(privateTab)
        manager.addDelegate(delegate)

        let didSelect = MethodSpy(functionName: "tabManager(_:didSelectedTabChange:previous:)") { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertTrue(previous != next)
            XCTAssertTrue(previous == privateTab)
            XCTAssertTrue(next == tab)
            XCTAssertTrue(previous.isPrivate)
            XCTAssertTrue(manager.selectedTab == next)
        }
        delegate.expect([willRemove, didRemove, didSelect])
        manager.removeTab(privateTab)
        delegate.verify("Not all delegate methods were called")
    }

    func testDeletePrivateTabsOnExit() {
        //setup
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        profile.prefs.setBool(true, forKey: "settings.closePrivateTabs")

        // create one private and one normal tab
        let tab = manager.addTab()
        manager.selectTab(tab)
        manager.selectTab(manager.addTab(isPrivate: true))

        XCTAssertEqual(manager.selectedTab?.isPrivate, true, "The selected tab should be the private tab")
        XCTAssertEqual(manager.privateTabs.count, 1, "There should only be one private tab")

        manager.selectTab(tab)
        XCTAssertEqual(manager.privateTabs.count, 0, "If the normal tab is selected the private tab should have been deleted")
        XCTAssertEqual(manager.normalTabs.count, 1, "The regular tab should stil be around")

        manager.selectTab(manager.addTab(isPrivate: true))
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be one new private tab")
        manager.willSwitchTabMode(leavingPBM: true)
        XCTAssertEqual(manager.privateTabs.count, 0, "After willSwitchTabMode there should be no more private tabs")

        manager.selectTab(manager.addTab(isPrivate: true))
        manager.selectTab(manager.addTab(isPrivate: true))
        XCTAssertEqual(manager.privateTabs.count, 2, "Private tabs should not be deleted when another one is added")
        manager.selectTab(manager.addTab())
        XCTAssertEqual(manager.privateTabs.count, 0, "But once we add a normal tab we've switched out of private mode. Private tabs should be deleted")
        XCTAssertEqual(manager.normalTabs.count, 2, "The original normal tab and the new one should both still exist")

        profile.prefs.setBool(false, forKey: "settings.closePrivateTabs")
        manager.selectTab(manager.addTab(isPrivate: true))
        manager.selectTab(tab)
        XCTAssertEqual(manager.selectedTab?.isPrivate, false, "The selected tab should not be private")
        XCTAssertEqual(manager.privateTabs.count, 1, "If the flag is false then private tabs should still exist")
    }

    func testTogglePBMDelete() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        profile.prefs.setBool(true, forKey: "settings.closePrivateTabs")

        let tab = manager.addTab()
        manager.selectTab(tab)
        manager.selectTab(manager.addTab())
        manager.selectTab(manager.addTab(isPrivate: true))

        manager.willSwitchTabMode(leavingPBM: false)
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be 1 private tab")
        manager.willSwitchTabMode(leavingPBM: true)
        XCTAssertEqual(manager.privateTabs.count, 0, "There should be 0 private tab")
        manager.removeTab(tab)
        XCTAssertEqual(manager.normalTabs.count, 1, "There should be 1 normal tab")
    }

    func testDeleteNonSelectedTab() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()

        //create the tab before adding the mock delegate. So we don't have to check delegate calls we dont care about
        let tab = manager.addTab()
        manager.selectTab(tab)
        manager.addTab()
        let deleteTab = manager.addTab()
        manager.addDelegate(delegate)

        delegate.expect([willRemove, didRemove])
        manager.removeTab(deleteTab)

        delegate.verify("Not all delegate methods were called")
    }

    func testDeleteSelectedTab() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()

        func addTab(_ visit: Bool) -> Tab {
            let tab = manager.addTab()
            if visit {
                tab.lastExecutedTime = Date.now()
            }
            return tab
        }

        let tab0 = addTab(false) // not visited
        let tab1 = addTab(true)
        let tab2 = addTab(true)
        let tab3 = addTab(true)
        let tab4 = addTab(false) // not visited

        // starting at tab1, we should be selecting
        // [ tab3, tab4, tab2, tab0 ]

        manager.selectTab(tab1)
        tab1.parent = tab3
        manager.removeTab(manager.selectedTab!)
        // Rule: parent tab if it was the most recently visited
        XCTAssertEqual(manager.selectedTab, tab3)

        manager.removeTab(manager.selectedTab!)
        // Rule: next to the right.
        XCTAssertEqual(manager.selectedTab, tab4)

        manager.removeTab(manager.selectedTab!)
        // Rule: next to the left, when none to the right
        XCTAssertEqual(manager.selectedTab, tab2)

        manager.removeTab(manager.selectedTab!)
        // Rule: last one left.
        XCTAssertEqual(manager.selectedTab, tab0)
    }

    func testDeleteLastTab() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()

        //create the tab before adding the mock delegate. So we don't have to check delegate calls we dont care about
        (0..<10).forEach {_ in manager.addTab() }
        manager.selectTab(manager.tabs.last)
        let deleteTab = manager.tabs.last
        let newSelectedTab = manager.tabs[8]
        manager.addDelegate(delegate)

        let didSelect = MethodSpy(functionName: "tabManager(_:didSelectedTabChange:previous:)") { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertEqual(deleteTab, previous)
            XCTAssertEqual(next, newSelectedTab)
        }
        delegate.expect([willRemove, didRemove, didSelect])
        manager.removeTab(manager.tabs.last!)

        delegate.verify("Not all delegate methods were called")
    }

    func testDelegatesCalledWhenRemovingPrivateTabs() {
        //setup
        let profile = TabManagerMockProfile()
        let delegate = MockTabManagerDelegate()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        profile.prefs.setBool(true, forKey: "settings.closePrivateTabs")

        // create one private and one normal tab
        let tab = manager.addTab()
        let newTab = manager.addTab()
        manager.selectTab(tab)
        manager.selectTab(manager.addTab(isPrivate: true))
        manager.addDelegate(delegate)

        // Double check a few things
        XCTAssertEqual(manager.selectedTab?.isPrivate, true, "The selected tab should be the private tab")
        XCTAssertEqual(manager.privateTabs.count, 1, "There should only be one private tab")

        // switch to normal mode. Which should delete the private tabs
        manager.willSwitchTabMode(leavingPBM: true)

        //make sure tabs are cleared properly and indexes are reset
        XCTAssertEqual(manager.privateTabs.count, 0, "Private tab should have been deleted")
        XCTAssertEqual(manager.selectedIndex, -1, "The selected index should have been reset")

        // didSelect should still be called when switching between a nil tab
        let didSelect = MethodSpy(functionName: "tabManager(_:didSelectedTabChange:previous:)") { tabs in
            XCTAssertNil(tabs[1], "there should be no previous tab")
            let next = tabs[0]!
            XCTAssertFalse(next.isPrivate)
        }

        // make sure delegate method is actually called
        delegate.expect([didSelect])

        // select the new tab to trigger the delegate methods
        manager.selectTab(newTab)

        // check
        delegate.verify("Not all delegate methods were called")
    }

    func testDeleteFirstTab() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()

        //create the tab before adding the mock delegate. So we don't have to check delegate calls we dont care about
        (0..<10).forEach {_ in manager.addTab() }
        manager.selectTab(manager.tabs.first)
        let deleteTab = manager.tabs.first
        let newSelectedTab = manager.tabs[1]
        manager.addDelegate(delegate)

        let didSelect = MethodSpy(functionName: "tabManager(_:didSelectedTabChange:previous:)") { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertEqual(deleteTab, previous)
            XCTAssertEqual(next, newSelectedTab)
        }
        delegate.expect([willRemove, didRemove, didSelect])
        manager.removeTab(manager.tabs.first!)
        delegate.verify("Not all delegate methods were called")
    }

    // Private tabs and regular tabs are in the same tabs array.
    // Make sure that when a private tab is added inbetween regular tabs it isnt accidently selected when removing a regular tab
    func testTabsIndex() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()

        // We add 2 tabs. Then a private one before adding another normal tab and selecting it.
        // Make sure that when the last one is deleted we dont switch to the private tab
        manager.addTab()
        let newSelected = manager.addTab()
        manager.addTab(isPrivate: true)
        let deleted = manager.addTab()
        manager.selectTab(manager.tabs.last)
        manager.addDelegate(delegate)

        let didSelect = MethodSpy(functionName: "tabManager(_:didSelectedTabChange:previous:)") { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertEqual(deleted, previous)
            XCTAssertEqual(next, newSelected)
        }
        delegate.expect([willRemove, didRemove, didSelect])
        manager.removeTab(manager.tabs.last!)

        delegate.verify("Not all delegate methods were called")
    }

    func testTabsIndexClosingFirst() {
        let profile = TabManagerMockProfile()
        let manager = TabManager(prefs: profile.prefs, imageStore: nil)
        let delegate = MockTabManagerDelegate()

        // We add 2 tabs. Then a private one before adding another normal tab and selecting the first.
        // Make sure that when the last one is deleted we dont switch to the private tab
        let deleted = manager.addTab()
        let newSelected = manager.addTab()
        manager.addTab(isPrivate: true)
        manager.addTab()
        manager.selectTab(manager.tabs.first)
        manager.addDelegate(delegate)

        let didSelect = MethodSpy(functionName: "tabManager(_:didSelectedTabChange:previous:)") { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertEqual(deleted, previous)
            XCTAssertEqual(next, newSelected)
        }
        delegate.expect([willRemove, didRemove, didSelect])
        manager.removeTab(manager.tabs.first!)
        delegate.verify("Not all delegate methods were called")
    }

}
