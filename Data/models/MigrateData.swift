/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import CoreData

class MigrateData: NSObject {
    
    fileprivate var files: FileAccessor!
    fileprivate var db: OpaquePointer? = nil
    
    enum ProcessOrder: Int {
        case bookmarks = 0
        case history = 1
        case domains = 2
        case favicons = 3
        case tabs = 4
        case delete = 5
    }
    var completedCalls: [ProcessOrder: Bool] = [.bookmarks: false, .history: false, .domains: false, .favicons: false, .tabs: false] {
        didSet {
            checkCompleted()
        }
    }
    var completedCallback: ((_ success: Bool) -> Void)?
    
    required convenience init(completed: ((_ success: Bool) -> Void)?) {
        self.init()
        self.files = ProfileFileAccessor(localName: "profile")
        
        completedCallback = completed
        process()
    }
    
    override init() {
        super.init()
    }
    
    fileprivate func process() {
        if hasOldDb() {
            debugPrint("Found old database...")
            
            migrateDomainData { (success) in
                debugPrint("Migrate domains... \(success ? "Done" : "Failed")")
                self.completedCalls[ProcessOrder.domains] = success
            }
            migrateFavicons { (success) in
                debugPrint("Migrate favicons... \(success ? "Done" : "Failed")")
                self.completedCalls[ProcessOrder.favicons] = success
            }
            migrateHistory { (success) in
                debugPrint("Migrate history... \(success ? "Done" : "Failed")")
                self.completedCalls[ProcessOrder.history] = success
            }
            migrateBookmarks { (success) in
                debugPrint("Migrate bookmarks... \(success ? "Done" : "Failed")")
                self.completedCalls[ProcessOrder.bookmarks] = success
            }
            migrateTabs { (success) in
                debugPrint("Migrate tabs... \(success ? "Done" : "Failed")")
                self.completedCalls[ProcessOrder.tabs] = success
            }
        }
    }
    
    fileprivate func hasOldDb() -> Bool {
        let file = ((try! files.getAndEnsureDirectory()) as NSString).appendingPathComponent("browser.db")
        let status = sqlite3_open_v2(file.cString(using: String.Encoding.utf8)!, &db, SQLITE_OPEN_READONLY, nil)
        if status != SQLITE_OK || status == 0 {
            debugPrint("Error: Opening Database with Flags")
            return false
        }
        return true
    }
    
    internal var domainHash: [Int32: Domain] = [:]
    
    fileprivate func migrateDomainData(_ completed: (_ success: Bool) -> Void) {
        let query: String = "SELECT id, domain, showOnTopSites FROM domains"
        var results: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &results, nil) == SQLITE_OK {
            while sqlite3_step(results) == SQLITE_ROW {
                let id = sqlite3_column_int(results, 0)
                let domain = String(cString: sqlite3_column_text(results, 1))
                let showOnTopSites = sqlite3_column_int(results, 2)
                
                if let d = Domain.getOrCreateForUrl(URL(string: domain)!, context: DataController.shared.workerContext) {
                    d.topsite = (showOnTopSites == 1)
                    domainHash[id] = d
                }
            }
            DataController.saveContext(context: DataController.shared.workerContext)
        }
        
        if sqlite3_finalize(results) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            debugPrint("Error finalizing prepared statement: \(error)")
        }
        results = nil
        completed(true)
    }
    
    fileprivate func migrateHistory(_ completed: (_ success: Bool) -> Void) {
        let query: String = "SELECT url, title FROM history WHERE is_deleted = 0"
        var results: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &results, nil) == SQLITE_OK {
            while sqlite3_step(results) == SQLITE_ROW {
                let url = String(cString: sqlite3_column_text(results, 0))
                let title = String(cString: sqlite3_column_text(results, 1))
                
                History.add(title, url: URL(string: url)!)
            }
        }
        
        if sqlite3_finalize(results) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            debugPrint("Error finalizing prepared statement: \(error)")
        }
        results = nil
        completed(true)
    }
    
    internal var domainFaviconHash: [Int32: Domain] = [:]
    
    fileprivate func buildDomainFaviconHash() {
        let query: String = "SELECT siteID, faviconID FROM favicon_sites"
        var results: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &results, nil) == SQLITE_OK {
            while sqlite3_step(results) == SQLITE_ROW {
                let domainId = sqlite3_column_int(results, 0)
                let faviconId = sqlite3_column_int(results, 1)
                if let domain = domainHash[domainId] {
                    domainFaviconHash[faviconId] = domain
                }
            }
        }
        
        if sqlite3_finalize(results) != SQLITE_OK {
            let error = String(describing: sqlite3_errmsg(db))
            debugPrint("Error finalizing prepared statement: \(error)")
        }
        results = nil
    }
    
    fileprivate func migrateFavicons(_ completed: (_ success: Bool) -> Void) {
        buildDomainFaviconHash()
        
        let query: String = "SELECT id, url, width, height, type FROM favicons"
        var results: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &results, nil) == SQLITE_OK {
            while sqlite3_step(results) == SQLITE_ROW {
                let id = sqlite3_column_int(results, 0)
                let url = String(cString: sqlite3_column_text(results, 1))
                let width = sqlite3_column_int(results, 2)
                let height = sqlite3_column_int(results, 3)
                let type = sqlite3_column_int(results, 4)
                
                let favicon = Favicon(url: url, type: IconType(rawValue: Int(type))!)
                favicon.width = Int(width)
                favicon.height = Int(height)
                
                if let domain = domainFaviconHash[id] {
                    if let url = domain.url {
                        FaviconMO.add(favicon, forSiteUrl: URL(string: url)!)
                    }
                }
            }
        }
        
        if sqlite3_finalize(results) != SQLITE_OK {
            let error = String(describing: sqlite3_errmsg(db))
            debugPrint("Error finalizing prepared statement: \(error)")
        }
        results = nil
        completed(true)
    }
    
    internal var bookmarkOrderHash: [String: Int16] = [:]
    
    fileprivate func buildBookmarkOrderHash() {
        let query: String = "SELECT child, idx FROM bookmarksLocalStructure"
        var results: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &results, nil) == SQLITE_OK {
            while sqlite3_step(results) == SQLITE_ROW {
                let child = String(cString: sqlite3_column_text(results, 0))
                let idx = sqlite3_column_int(results, 1)
                bookmarkOrderHash[child] = Int16(idx)
            }
        }
        
        if sqlite3_finalize(results) != SQLITE_OK {
            let error = String(describing: sqlite3_errmsg(db))
            debugPrint("Error finalizing prepared statement: \(error)")
        }
        results = nil
    }
    
    fileprivate func migrateBookmarks(_ completed: (_ success: Bool) -> Void) {
        buildBookmarkOrderHash()
        
        let query: String = "SELECT guid, type, parentid, title, description, bmkUri, faviconID FROM bookmarksLocal WHERE (id > 4 AND is_deleted = 0) ORDER BY type DESC"
        var results: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &results, nil) == SQLITE_OK {
            var relationshipHash: [String: Bookmark] = [:]
            while sqlite3_step(results) == SQLITE_ROW {
                let guid = String(cString: sqlite3_column_text(results, 0))
                let type = sqlite3_column_int(results, 1)
                let parentid = String(cString: sqlite3_column_text(results, 2))
                let title = String(cString: sqlite3_column_text(results, 3))
                let description = String(cString: sqlite3_column_text(results, 4))
                let url = String(cString: sqlite3_column_text(results, 5))
                
                if let bk = Bookmark.addForMigration(url: url, title: title, customTitle: description, parentFolder: relationshipHash[parentid] ?? nil, isFolder: (type == 2)) {
                    let parent = relationshipHash[parentid]
                    bk.parentFolder = parent
                    bk.syncParentUUID = parent?.syncUUID
                    if let baseUrl = URL(string: url)?.baseURL {
                        bk.domain = Domain.getOrCreateForUrl(baseUrl, context: DataController.shared.workerContext)
                    }
                    
                    if let order = bookmarkOrderHash[guid] {
                        bk.order = order
                        debugPrint("__ order set \(order) for \((type == 2) ? "folder" : "bookmark")")
                    }
                    relationshipHash[guid] = bk
                }
            }
        }
        
        if sqlite3_finalize(results) != SQLITE_OK {
            let error = String(describing: sqlite3_errmsg(db))
            debugPrint("Error finalizing prepared statement: \(error)")
        }
        results = nil
        completed(true)
    }
    
    fileprivate func migrateTabs(_ completed: (_ success: Bool) -> Void) {
        let query: String = "SELECT url, title, history FROM tabs ORDER BY last_used"
        var results: OpaquePointer? = nil
        let context = DataController.shared.mainThreadContext
        
        if sqlite3_prepare_v2(db, query, -1, &results, nil) == SQLITE_OK {
            var order: Int16 = 0
            while sqlite3_step(results) == SQLITE_ROW {
                let url = String(cString: sqlite3_column_text(results, 0))
                let title = String(cString: sqlite3_column_text(results, 1))
                let history = String(cString: sqlite3_column_text(results, 2))
                let historyData = history.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "\\", with: "")
                let historyList: [String] = historyData.characters.split{$0 == ","}.map(String.init)
                
                guard let tabId = TabMO.freshTab().syncUUID else { continue }
                let tab = SavedTab(id: tabId, title: title, url: url, isSelected: false, order: order, screenshot: nil, history: historyList, historyIndex: Int16(historyList.count-1))
                
                debugPrint("History restored [\(historyList)]")
                
                TabMO.add(tab, context: context)
                order = order + 1
            }
            DataController.saveContext(context: context)
        }
        
        if sqlite3_finalize(results) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            debugPrint("Error finalizing prepared statement: \(error)")
        }
        results = nil
        completed(true)
    }
    
    fileprivate func removeOldDb(_ completed: (_ success: Bool) -> Void) {
        do {
            let documentDirectory = URL(fileURLWithPath: self.files.rootPath as String)
            let originPath = documentDirectory.appendingPathComponent("browser.db")
            let destinationPath = documentDirectory.appendingPathComponent("old-browser.db")
            try FileManager.default.moveItem(at: originPath, to: destinationPath)
            completed(true)
        } catch let error as NSError {
            debugPrint("Cannot clear profile data: \(error)")
            completed(false)
        }
    }
    
    fileprivate func checkCompleted() {
        var completedAllCalls = true
        for (_, value) in completedCalls {
            if value == false {
                completedAllCalls = false
                break
            }
        }
        
        // All migrations completed, delete the db.
        if completedAllCalls {
            removeOldDb { (success) in
                debugPrint("Delete old database... \(success ? "Done" : "Failed")")
                if let callback = self.completedCallback {
                    callback(success)
                }
            }
        }
    }
}
