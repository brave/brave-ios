//
// WidgetShortcut.swift
//
// This file was automatically generated and should not be edited.
//

#if canImport(Intents)

import Intents

@available(iOS 12.0, macOS 10.16, watchOS 5.0, *) @available(tvOS, unavailable)
@objc public enum WidgetShortcut: Int {
    case `unknown` = 0
    case `newTab` = 1
    case `newPrivateTab` = 2
    case `bookmarks` = 3
    case `history` = 4
    case `downloads` = 5
    case `playlist` = 6
}

@available(iOS 13.0, macOS 10.16, watchOS 6.0, *) @available(tvOS, unavailable)
@objc(WidgetShortcutResolutionResult)
public class WidgetShortcutResolutionResult: INEnumResolutionResult {

    // This resolution result is for when the app extension wants to tell Siri to proceed, with a given WidgetShortcut. The resolvedValue can be different than the original WidgetShortcut. This allows app extensions to apply business logic constraints.
    // Use notRequired() to continue with a 'nil' value.
    @objc(successWithResolvedWidgetShortcut:)
    public class func success(with resolvedValue: WidgetShortcut) -> Self {
        return __success(withResolvedValue: resolvedValue.rawValue)
    }

    // This resolution result is to ask Siri to confirm if this is the value with which the user wants to continue.
    @objc(confirmationRequiredWithWidgetShortcutToConfirm:)
    public class func confirmationRequired(with valueToConfirm: WidgetShortcut) -> Self {
        return __confirmationRequiredWithValue(toConfirm: valueToConfirm.rawValue)
    }
}

#endif
