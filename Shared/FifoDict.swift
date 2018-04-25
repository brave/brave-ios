/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import Foundation

// TODO: Needs full rewrite, generics, subscripts, etc

// Lookup time is O(maxDicts)
// Very basic implementation of a recent item collection class, stored as groups of items in dictionaries, oldest items are deleted as blocks of items since their entire containing dictionary is deleted.
open class FifoDict {
    var fifoArrayOfDicts: [NSMutableDictionary] = []
    let maxDicts = 5
    let maxItemsPerDict = 50
    
    public init() {}
    
    // the url key is a combination of urls, the main doc url, and the url being checked
    open func addItem(_ key: String, value: AnyObject?) {
        if fifoArrayOfDicts.count > maxItemsPerDict {
            fifoArrayOfDicts.removeFirst()
        }
        
        if fifoArrayOfDicts.last == nil || (fifoArrayOfDicts.last?.count ?? 0) > maxItemsPerDict {
            fifoArrayOfDicts.append(NSMutableDictionary())
        }
        
        if let lastDict = fifoArrayOfDicts.last {
            if value == nil {
                lastDict[key] = NSNull()
            } else {
                lastDict[key] = value
            }
        }
    }
    
    open func getItem(_ key: String) -> AnyObject?? {
        for dict in fifoArrayOfDicts {
            if let item = dict[key] {
                return item as AnyObject
            }
        }
        return nil
    }
}
