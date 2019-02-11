//
//  DomainParser.swift
//  DomainParser
//
//  Created by Jason Akakpo on 19/07/2018.
//  Copyright © 2018 Dashlane. All rights reserved.
//

import Foundation

enum DomainParserError: Error {
    case parsingError(details: Error?)
}

/// Uses the public suffix list
public struct DomainParser {
    
    let parsedRules: ParsedRules
    
    let onlyBasicRules: Bool
    
    let basicRulesParser: BasicRulesParser
    
    /// Parse the `public_suffix_list` file and build the set of Rules
    /// Parameters:
    ///   - QuickParsing: IF true, the `exception` and `wildcard` rules will be ignored
    public init(quickParsing: Bool = false) throws {
        let url = Bundle.current.url(forResource: "public_suffix_list", withExtension: "dat")!
        let data = try Data(contentsOf: url)
        parsedRules = try RulesParser().parse(raw: data)
        basicRulesParser = BasicRulesParser(suffixes: parsedRules.basicRules)
        onlyBasicRules = quickParsing
    }

    public func parse(host: String) -> ParsedHost? {
        if onlyBasicRules {
            return basicRulesParser.parse(host: host)
        } else {
            return parseExceptionsAndWildCardRules(host: host) ??  basicRulesParser.parse(host: host)
        }
     }
    
    func parseExceptionsAndWildCardRules(host: String) -> ParsedHost? {
        let hostComponents = host.components(separatedBy: ".")
        let isMatching: (Rule) -> Bool =  { $0.isMatching(hostLabels: hostComponents) }
        let rule = parsedRules.exceptions.first(where: isMatching) ?? parsedRules.wildcardRules.first(where: isMatching)
        return rule?.parse(hostLabels: hostComponents)
    }
}

private extension Bundle {

    static var current: Bundle {
        class ClassInCurrentBundle {}
        return Bundle.init(for: ClassInCurrentBundle.self)
    }
}

struct ParsedRules {
    let exceptions: [Rule]
    let wildcardRules: [Rule]
    let basicRules: Set<String>
}
