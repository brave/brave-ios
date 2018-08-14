// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import CoreData
@testable import Data

class CoreDataTestCase: XCTestCase {
    
    // Always call super.setUp() in your subclasses to reset the database.
    override func setUp() {
        DataController.resetDatabase()
        
        NotificationCenter.default.addObserver(self, selector: #selector(contextSaved), 
                                               name: NSNotification.Name.NSManagedObjectContextDidSave, 
                                               object: nil)
        super.setUp()
    }
    
    override func tearDown() {
        NotificationCenter.default.removeObserver(self)
        contextSaveCompletionHandler = nil
        saveExpectation = nil
        // Device.clearSharedDevice()
        DataController.workerThreadContext.reset()
        DataController.mainThreadContext.reset()
        super.tearDown()
    }
    
    // MARK: - Handling background context reads/writes

    var contextSaveCompletionHandler: (()->())?
    var saveExpectation: XCTestExpectation?
    
    @objc func contextSaved() {
        contextSaveCompletionHandler?()
    }
    
    /// This expecation can be used on most tests.
    /// For more complex multi thread tests, expectations need to be written manually.
    func contextSaveExpectation() {
        let uuid = UUID().uuidString
        saveExpectation = expectation(description: uuid)
        
        contextSaveCompletionHandler = { [weak self] in
            self?.saveExpectation?.fulfill()
            self?.saveExpectation = nil
            self?.contextSaveCompletionHandler = nil
        }
    }
    
    /// Waits for core data context save notification. Use this for single background context saves if you want to wait
    /// for view context to update itself. Unfortunately there is no notification after changes are merged into context.
    func backgroundSaveAndWaitForExpectation(code: () -> ()) {        
        contextSaveExpectation()
        code()
        waitForExpectations(timeout: 2, handler: nil)
    }
}
