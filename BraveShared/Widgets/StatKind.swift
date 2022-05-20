//
// StatKind.swift
//
// This file was automatically generated and should not be edited.
//

#if canImport(Intents)

import Intents

@available(iOS 12.0, macOS 10.16, watchOS 5.0, *) @available(tvOS, unavailable)
@objc public enum StatKind: Int {
    case `unknown` = 0
    case `adsBlocked` = 1
    case `dataSaved` = 2
    case `timeSaved` = 3
}

@available(iOS 13.0, macOS 10.16, watchOS 6.0, *) @available(tvOS, unavailable)
@objc(StatKindResolutionResult)
public class StatKindResolutionResult: INEnumResolutionResult {

    // This resolution result is for when the app extension wants to tell Siri to proceed, with a given StatKind. The resolvedValue can be different than the original StatKind. This allows app extensions to apply business logic constraints.
    // Use notRequired() to continue with a 'nil' value.
    @objc(successWithResolvedStatKind:)
    public class func success(with resolvedValue: StatKind) -> Self {
        return __success(withResolvedValue: resolvedValue.rawValue)
    }

    // This resolution result is to ask Siri to confirm if this is the value with which the user wants to continue.
    @objc(confirmationRequiredWithStatKindToConfirm:)
    public class func confirmationRequired(with valueToConfirm: StatKind) -> Self {
        return __confirmationRequiredWithValue(toConfirm: valueToConfirm.rawValue)
    }
}

#endif
