// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import Foundation

// These are taken from the Places docs
// http://mxr.mozilla.org/mozilla-central/source/toolkit/components/places/nsINavHistoryService.idl#1187
enum VisitType: Int {
    case unknown = 0
    
    /**
     * This transition type means the user followed a link and got a new toplevel
     * window.
     */
    case link = 1
    
    /**
     * This transition type means that the user typed the page's URL in the
     * URL bar or selected it from URL bar autocomplete results, clicked on
     * it from a history query (from the History sidebar, History menu,
     * or history query in the personal toolbar or Places organizer).
     */
    case typed = 2
    
    case bookmark = 3
    case embed = 4
    case permanentRedirect = 5
    case temporaryRedirect = 6
    case download = 7
    case framedLink = 8
}
