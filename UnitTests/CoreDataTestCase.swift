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
        contextSaveCompletionsArray.removeAll()
        DataController.workerThreadContext.reset()
        DataController.mainThreadContext.reset()
        Device.clearSharedDevice()
        super.tearDown()
    }
    
    // MARK: - Handling background context reads/writes

    var contextSaveCompletionsArray: [() -> ()] = []
    
    @objc func contextSaved() {
        contextSaveCompletionsArray.forEach { $0() }
        
        // Clear array after all completions are triggered.
        contextSaveCompletionsArray.removeAll()
    }
    
    /// Waits for core data context save notification. Use this for single background context saves if you want to wait
    /// for view context to update itself. Unfortunately there is no notification after changes are merged into context.
    func backgroundSaveAndWaitForExpectation(code: () -> ()) {
        // We do not care about expectation name as long as it is unique.
        let uuid = UUID().uuidString
        let saveExpectation = expectation(description: uuid)
        
        contextSaveCompletionsArray.append {
            saveExpectation.fulfill()
        }
        
        code()
        
        wait(for: [saveExpectation], timeout: 2)
    }
}
