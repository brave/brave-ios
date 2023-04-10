// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
import BraveCore
import WebKit
@testable import ContentBlocker

final class ContentBlockerTests: XCTestCase {
  private var braveCore: BraveCoreMain = {
    let userAgent = [
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) \\",
      "AppleWebKit/605.1.15 (KHTML, like Gecko) \\",
      "Version/16.1 \\",
      "Safari/605.1.15"
    ].joined()
    
    return BraveCoreMain(userAgent: userAgent, additionalSwitches: [])
  }()
  
  func testContentBlockers() async throws {
    let service = braveCore.adblockService
    let path = await service.getShieldsPath()
    let filterLists = service.regionalFilterLists
    XCTAssertNotNil(filterLists)
    
    guard let servicesKey = ProcessInfo.processInfo.environment["BRAVE_SERVICES_KEY"] else {
      XCTFail("You need to add a `BRAVE_SERVICES_KEY=<Some key>` environment variable to run this test.")
      return
    }
    
    await filterLists?.asyncForEach { filterList in
      do {
        let filterSet = try await ContentBlockerDownloader.shared.downloadContentBlockers(
          for: filterList, servicesKey: servicesKey
        )
        
        let encodedContentBlockerJSON = AdblockEngine.contentBlockerRules(fromFilterSet: filterSet)
        XCTAssertNotNil(encodedContentBlockerJSON)
        
        guard let data = encodedContentBlockerJSON.data(using: .utf8),
              let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
          XCTFail("Could not deserialize encodedContentBlockerJSON")
          return
        }
        
        let ruleStore = try await makeRuleStore(id: filterList.uuid)
        let failedResults = await ruleStore.testBisect(contentRules: jsonArray)
        
        for failedResult in failedResults {
          let error = failedResult.error as NSError
          let errorString = error.helpAnchor ?? "\(error)"
          XCTFail("\(errorString) \(failedResult.rule)")
        }
      } catch {
        XCTFail("Filter list \(filterList.title) (\(filterList.uuid)) failed to download")
      }
    }
  }
  
  @MainActor private func makeRuleStore(id: String) throws -> WKContentRuleListStore {
    let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent("temporary-rule-store-\(id)")
    try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
    return WKContentRuleListStore(url: folderURL)!
  }
}

typealias FailingRule = (rule: [String: Any], error: Error)
extension WKContentRuleListStore {
  func testBisect(contentRules: [[String: Any]]) async -> [FailingRule] {
    var results: [FailingRule] = []
    
    if contentRules.isEmpty {
      return results
    } else if contentRules.count == 1, let contentRule = contentRules.first  {
      do {
        try await compile(contentRuleLists: contentRules, forIdentifier: "test-bisect")
      } catch {
        results.append((contentRule, error))
      }
    } else {
      let splitIndex = Int(contentRules.count / 2)
      let first = Array(contentRules[0..<splitIndex])
      let second = Array(contentRules[splitIndex..<contentRules.count])
      
      // Test the left side
      do {
        try await compile(contentRuleLists: first, forIdentifier: "test-bisect-left")
      } catch {
        let additionalResults = await testBisect(contentRules: first)
        results.append(contentsOf: additionalResults)
      }
      
      // Test the right side
      do {
        try await compile(contentRuleLists: second, forIdentifier: "test-bisect-right")
        return results
      } catch {
        let additionalResults = await testBisect(contentRules: second)
        results.append(contentsOf: additionalResults)
      }
    }
    
    return results
  }
  
  enum RuleListCompileError: Error {
    case failedToEncodeToString
    case emptyRuleList
  }
  
  func encode(contentRuleList: [[String: Any]]) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: contentRuleList)
    
    guard let encodedContentRuleList = String(data: data, encoding: .utf8) else {
      throw RuleListCompileError.emptyRuleList
    }
    
    return encodedContentRuleList
  }
  
  @discardableResult
  @MainActor func compile(contentRuleLists: [[String: Any]], forIdentifier: String) async throws -> WKContentRuleList {
    let encodedContentRuleList = try encode(contentRuleList: contentRuleLists)
    
    if let ruleList = try await compileContentRuleList(
      forIdentifier: "test-identifier",
      encodedContentRuleList: encodedContentRuleList
    ) {
      return ruleList
    } else {
      throw RuleListCompileError.emptyRuleList
    }
  }
}
