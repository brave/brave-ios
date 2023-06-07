// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// A helper class that helps us clean urls for "clean copy" feature
class CleanURLService {
  /// Object representing an item in the `clean-urls.json` file found here:
  /// https://github.com/brave/adblock-lists/blob/master/brave-lists/clean-urls.json
  struct MatcherRule: Decodable, MatcherRuleProtocol {
    private enum CodingKeys: String, CodingKey {
      case include, exclude, params
    }

    /// A set of patterns that are include in this rule
    let include: Set<String>
    /// A set of patterns that are excluded from this rule
    let exclude: Set<String>?
    /// The query params that need to be extracted
    let params: Set<String>
    
    /// The param that we can match this rule by in case we have a match-all pattern
    var matchAllParam: String? {
      // Our params are not used for matching but stripping
      return nil
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.include = try container.decode(Set<String>.self, forKey: .include)
      self.exclude = try container.decodeIfPresent(Set<String>.self, forKey: .exclude)
      self.params = try container.decode(Set<String>.self, forKey: .params)
    }
  }
  
  public static let shared = CleanURLService()
  private(set) var matcher: URLMatcher<MatcherRule>?
  
  /// Initialize this instance with a network manager
  init() {}

  /// Setup this downloader with rule `JSON` data.
  ///
  /// - Note: Decoded values that have unknown types are filtered out
  func setup(withRulesJSON ruleData: Data) throws {
    // Decode the data and store it for later user
    let jsonDecoder = JSONDecoder()
    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    let rules = try jsonDecoder.decode([Result<MatcherRule, Error>].self, from: ruleData)
    self.matcher = URLMatcher(rules: rules)
  }
  
  /// Cleanup the url using the stored matcher
  func cleanup(url: URL) -> URL {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
    guard components.queryItems?.isEmpty == false else { return url }
    guard let rules = matcher?.allMatchingRules(for: url) else { return url }
    
    for rule in rules {
      components.queryItems = components.queryItems?.filter({ !rule.params.contains($0.name) })
    }
    
    if components.queryItems?.isEmpty == true {
      components.queryItems = nil
    }
    
    return components.url ?? url
  }
}
