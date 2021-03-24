// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared

private let log = Logger.browserLogger

// MARK: - BlockingSummary

struct BlockingSummary: Codable {

    // MARK: CodingKeys

    enum CodingKeys: String, CodingKey {
        case site
        case savings
        case childpages = "numofchildpages"
        case childsavings = "avgchildsavings"
        case sitesavings = "avgsitesavings"
    }

    // MARK: Internal

    let site: String
    let savings: Int
    let childpages: Double
    let childsavings: Double
    let sitesavings: Double

}

// MARK: - BlockingSummaryDataSource

class BlockingSummaryDataSource {

    // MARK: Internal
    
    let blockingSummaryFilePath = "blocking-summary"
    
    // MARK: Lifecycle
    
    init() {
        blockingSummaryList = fetchBlockingSummaryObjects()
    }
    
    // MARK: Private
    
    /// The list containing details related with blocking values of sites fetched from the JSON file
    private var blockingSummaryList = [BlockingSummary]()

    /// The function which uses the Data from Local JSON file to fetch list of objects
    private func fetchBlockingSummaryObjects() -> [BlockingSummary] {
        var blockingSummaryList = [BlockingSummary]()
        
        guard let blockSummaryData = createJSONDataFrom(file: blockingSummaryFilePath) else {
            return blockingSummaryList
        }

        do {
            blockingSummaryList = try JSONDecoder().decode([BlockingSummary].self, from: blockSummaryData)
        } catch {
            log.error("Failed to decode blockign summary object from json Data \(error)")
        }
        
        return blockingSummaryList
    }
    
    /// The helper function with created the Data from parametrized file path
    private func createJSONDataFrom(file: String) -> Data? {
        guard let filePath = Bundle.main.path(forResource: file, ofType: "json") else {
            return nil
        }
        
        do {
            return try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            log.error("Failed to get bundle path for \(file)")
        }
        
        return nil
    }

}
