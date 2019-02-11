//
//  RulesParser.swift
//  DomainParser
//
//  Created by Jason Akakpo on 04/09/2018.
//  Copyright © 2018 Dashlane. All rights reserved.
//

import Foundation


class RulesParser {
    
    var exceptions = [Rule]()
    var wildcardRules = [Rule]()
    /// Set of suffixes
    var basicRules = Set<String>()
    
    /// Parse the Data to extract an array of Rules. The array is sorted by importance.
    func parse(raw: Data) throws -> ParsedRules {
        guard let rulesText = String(data: raw, encoding: .utf8) else {
            throw DomainParserError.parsingError(details: nil)
        }
        rulesText
            .components(separatedBy: .newlines)
            .forEach(parseRule)
        return ParsedRules.init(exceptions: exceptions,
                                wildcardRules: wildcardRules,
                                basicRules: basicRules)
    }
    
    private func parseRule(line: String) {
        guard let trimmedLine = line.components(separatedBy: .whitespaces).first,
            !trimmedLine.isComment && !trimmedLine.isEmpty else { return }
        
        /// From `publicsuffix.org/list/` Each line is only read up to the first whitespace; entire lines can also be commented using //.
        if trimmedLine.contains("*") {
            wildcardRules.append(Rule(raw: trimmedLine))
        } else if trimmedLine.starts(with: "!") {
            exceptions.append(Rule(raw: trimmedLine))
        } else {
            basicRules.insert(trimmedLine)
        }
    }
}

private extension String {
    
    /// A line starting by "//" is a comment and should be ignored
    var isComment: Bool {
        return self.starts(with: C.commentMarker)
    }
}
