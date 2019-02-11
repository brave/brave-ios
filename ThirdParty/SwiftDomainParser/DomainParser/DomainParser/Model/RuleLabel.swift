//
//  RuleLabel.swift
//  DomainParser
//
//  Created by Jason Akakpo on 19/07/2018.
//  Copyright © 2018 Dashlane. All rights reserved.
//

import Foundation

enum RuleLabel {
    case text(String)
    /// The wildcard character * (asterisk) matches any valid sequence of characters in a hostname part.
    /// Wildcards are not restricted to appear only in the leftmost position, but they must wildcard an entire label. (I.e. *.*.foo is a valid rule: *bar.foo is not.)
    case wildcard

    init(fromComponent component: String) {
        self = component == Constant.wildcardComponent ? .wildcard : .text(component)
    }

    /// Return true if self matches the given label
    func isMatching(label: String) -> Bool {
        switch self {
        case let .text(text):
            return text == label
        case .wildcard:
            return true
        }
    }
}
