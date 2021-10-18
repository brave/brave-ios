// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct WebpagePreviewWidgetData: Codable {
    public var url: URL
    public var offset: CGFloat
    
    public init(url: URL, offset: CGFloat) {
        self.url = url
        self.offset = offset
    }
}

/// The width of a medium or large family style widget based on the current device
public var mediumLargeWidgetWidth: CGFloat {
    // https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/widgets
    let bounds = UIScreen.main.bounds
    if bounds.width == 320 {
        return 292.0
    } else if bounds.width == 375 {
        if bounds.height == 568.0 {
            return 321.0
        }
        return 329
    } else {
        if bounds.height == 736.0 {
            return 348
        }
        return 360
    }
}
