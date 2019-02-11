//
//  BasicRuleParser.swift
//  DomainParser
//
//  Created by Jason Akakpo on 04/09/2018.
//  Copyright © 2018 Dashlane. All rights reserved.
//

import Foundation

public struct BasicRulesParser {
    
    let suffixes: Set<String>
    init(suffixes: Set<String>) {
        self.suffixes = suffixes
    }
    public func parse(host: String) -> ParsedHost? {
        let lowercasedHost = host.lowercased()
        let hostComponents = lowercasedHost.components(separatedBy: ".")
        var hostSlices = ArraySlice(hostComponents)
        
        /// A host must have at least two parts else it's a TLD
        guard hostSlices.count > 1 else { return nil }
        
        var candidateSuffix = ""
        
        /// Check if the host ends with a suffix in the set
        /// For instance for : api.dashlane.co.uk
        /// First check if dashlane.co.uk is a known suffix, if not check if co.uk is, etc
        repeat {
            guard !hostSlices.isEmpty else { return nil }
            candidateSuffix = hostSlices.joined(separator: ".")
            hostSlices = hostSlices.dropFirst()
        } while !suffixes.contains(candidateSuffix)
        
        /// The domain is the suffix with one more component
        let domainRange = (hostSlices.startIndex - 2)..<hostComponents.endIndex
        let domain = domainRange.startIndex >= 0 ? hostComponents[domainRange].joined(separator: ".") : nil
        return ParsedHost(publicSuffix: candidateSuffix,
                          domain: domain)
    }
}
