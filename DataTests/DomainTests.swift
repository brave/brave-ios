// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreData
import BraveShared
@testable import Data

class DomainTests: CoreDataTestCase {
    let fetchRequest = NSFetchRequest<Domain>(entityName: String(describing: Domain.self))
    
    // Should match but with different schemes
    let url = URL(string: "http://example.com")!
    let urlHTTPS = URL(string: "https://example.com")!
    
    let url2 = URL(string: "http://brave.com")!
    let url2HTTPS = URL(string: "https://brave.com")!
    
    private func entity(for context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: String(describing: Domain.self), in: context)!
    }
    
    func testGetOrCreate() {
        XCTAssertNotNil(Domain.getOrCreate(forUrl: url))
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        
        // Try to add the same domain again, verify no new object is created
        XCTAssertNotNil(Domain.getOrCreate(forUrl: url))
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 1)
        
        // Add another domain, verify that second object is created
        XCTAssertNotNil(Domain.getOrCreate(forUrl: url2))
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 2)
    }
    
    func testGetOrCreateURLs() {
        // This also validates that the schemes are being correctly saved
        XCTAssertEqual(url.absoluteString, Domain.getOrCreate(forUrl: url).url)
        XCTAssertEqual(url2.absoluteString, Domain.getOrCreate(forUrl: url2).url)
        
        let url3 = URL(string: "https://brave.com")!
        let url4 = URL(string: "data://brave.com")!
        XCTAssertEqual(url3.absoluteString, Domain.getOrCreate(forUrl: url3).url)
        XCTAssertEqual(url4.absoluteString, Domain.getOrCreate(forUrl: url4).url)
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 4)
    }
    
    func testDefaultShieldSettings() {
        
        let domain = Domain.getOrCreate(forUrl: url)
        XCTAssertTrue(domain.isShieldExpected(BraveShield.AdblockAndTp, isPrivateBrowsing: true))
        XCTAssertTrue(domain.isShieldExpected(BraveShield.HTTPSE, isPrivateBrowsing: true))
        XCTAssertTrue(domain.isShieldExpected(BraveShield.SafeBrowsing, isPrivateBrowsing: true))
        XCTAssertFalse(domain.isShieldExpected(BraveShield.AllOff, isPrivateBrowsing: true))
        XCTAssertFalse(domain.isShieldExpected(BraveShield.NoScript, isPrivateBrowsing: true))
        XCTAssertFalse(domain.isShieldExpected(BraveShield.FpProtection, isPrivateBrowsing: true))
        
        XCTAssertEqual(domain.bookmarks?.count, 0)
        XCTAssertEqual(domain.historyItems?.count, 0)
        XCTAssertEqual(domain.url, url.domainURL.absoluteString)
    }
    
    /// Tests non-HTTPSE shields
    func testNormalShieldSettings() {
        let domain = Domain.getOrCreate(forUrl: url2HTTPS)
        backgroundSaveAndWaitForExpectation {
            Domain.setBraveShield(forUrl: url2HTTPS, shield: .SafeBrowsing, isOn: true, isPrivateBrowsing: false)
        }
        
        backgroundSaveAndWaitForExpectation {
            Domain.setBraveShield(forUrl: url2HTTPS, shield: .AdblockAndTp, isOn: false, isPrivateBrowsing: false)
        }
        
        XCTAssertTrue(domain.isShieldExpected(BraveShield.SafeBrowsing, isPrivateBrowsing: false))
        // Not testing via isSheildExpected, since that adds default checks
        XCTAssertFalse(domain.shield_adblockAndTp == 0)
        
        // These should be the same in this situation
        XCTAssertTrue(domain.isShieldExpected(BraveShield.SafeBrowsing, isPrivateBrowsing: true))
        // Not testing via isSheildExpected, since that adds default checks
        XCTAssertFalse(domain.shield_adblockAndTp == 0)
        
        // Setting to "new" values
        // Setting to same value
        backgroundSaveAndWaitForExpectation {
            Domain.setBraveShield(forUrl: url2HTTPS, shield: .SafeBrowsing, isOn: true, isPrivateBrowsing: false)
        }
        
        backgroundSaveAndWaitForExpectation {
            Domain.setBraveShield(forUrl: url2HTTPS, shield: .AdblockAndTp, isOn: true, isPrivateBrowsing: false)
        }
        
        XCTAssertTrue(domain.isShieldExpected(BraveShield.SafeBrowsing, isPrivateBrowsing: false))
        XCTAssertTrue(domain.isShieldExpected(BraveShield.AdblockAndTp, isPrivateBrowsing: false))
        
        // These should be the same in this situation
        XCTAssertTrue(domain.isShieldExpected(BraveShield.SafeBrowsing, isPrivateBrowsing: true))
        XCTAssertTrue(domain.isShieldExpected(BraveShield.AdblockAndTp, isPrivateBrowsing: true))
    }
    
    /// Testing HTTPSE
    /// if setting an HTTP scheme, that HTTPS is also set
    func testHTTPSEforHTTPsetter() {
        backgroundSaveAndWaitForExpectation {
            Domain.setBraveShield(forUrl: url, shield: .HTTPSE, isOn: true, isPrivateBrowsing: false)
        }
        
        // Should be one for HTTP and one for HTTPS schemes
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 2)
        
        let domainRefetch1 = Domain.getOrCreate(forUrl: url)
        XCTAssertEqual(domainRefetch1.isShieldExpected(.HTTPSE, isPrivateBrowsing: false), true)
        
        let domainRefetch2 = Domain.getOrCreate(forUrl: urlHTTPS)
        XCTAssertEqual(domainRefetch2.isShieldExpected(.HTTPSE, isPrivateBrowsing: false), true)
    }
    
    /// Testing HTTPSE
    /// if setting an HTTPS scheme, that HTTP is also set
    func testHTTPSEforHTTPSsetter() {
        backgroundSaveAndWaitForExpectation {
            Domain.setBraveShield(forUrl: url2HTTPS, shield: .HTTPSE, isOn: true, isPrivateBrowsing: false)
        }

        // Should be one for HTTP and one for HTTPS schemes
        XCTAssertEqual(try! DataController.viewContext.count(for: fetchRequest), 2)
        
        let domainRefetch1 = Domain.getOrCreate(forUrl: url2)
        XCTAssertEqual(domainRefetch1.isShieldExpected(.HTTPSE, isPrivateBrowsing: false), true)
        
        let domainRefetch2 = Domain.getOrCreate(forUrl: url2HTTPS)
        XCTAssertEqual(domainRefetch2.isShieldExpected(.HTTPSE, isPrivateBrowsing: false), true)
    }
}
