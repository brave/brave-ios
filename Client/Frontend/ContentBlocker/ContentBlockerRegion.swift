// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WebKit
import Shared
import Deferred
import Data
import BraveShared

class ContentBlockerRegion: BlocklistName {
    private static let ar = ContentBlockerRegion(localeCode: "ar", filename: "")
    private static let bg = ContentBlockerRegion(localeCode: "bg", filename: "")
    private static let zh = ContentBlockerRegion(localeCode: "zh", filename: "")
    private static let cs = ContentBlockerRegion(localeCode: "cs", filename: "")
    private static let de = ContentBlockerRegion(localeCode: "de", filename: "")
    private static let da = ContentBlockerRegion(localeCode: "da", filename: "")
    private static let et = ContentBlockerRegion(localeCode: "et", filename: "")
    private static let fi = ContentBlockerRegion(localeCode: "fi", filename: "")
    private static let fr = ContentBlockerRegion(localeCode: "fr", filename: "")
    private static let el = ContentBlockerRegion(localeCode: "el", filename: "")
    private static let hu = ContentBlockerRegion(localeCode: "hu", filename: "")
    private static let id = ContentBlockerRegion(localeCode: "id", filename: "")
    private static let hi = ContentBlockerRegion(localeCode: "hi", filename: "")
    private static let fa = ContentBlockerRegion(localeCode: "fa", filename: "")
    private static let `is` = ContentBlockerRegion(localeCode: "is", filename: "")
    private static let he = ContentBlockerRegion(localeCode: "he", filename: "")
    private static let it = ContentBlockerRegion(localeCode: "it", filename: "")
    private static let ja = ContentBlockerRegion(localeCode: "ja", filename: "")
    private static let ko = ContentBlockerRegion(localeCode: "ko", filename: "")
    private static let lt = ContentBlockerRegion(localeCode: "lt", filename: "")
    private static let lv = ContentBlockerRegion(localeCode: "lv", filename: "")
    private static let nl = ContentBlockerRegion(localeCode: "nl", filename: "")
    private static let pl = ContentBlockerRegion(localeCode: "pl", filename: "")
    private static let ru = ContentBlockerRegion(localeCode: "ru", filename: "")
    private static let uk = ContentBlockerRegion(localeCode: "uk", filename: "")
    private static let be = ContentBlockerRegion(localeCode: "be", filename: "")
    private static let es = ContentBlockerRegion(localeCode: "es", filename: "")
    private static let sl = ContentBlockerRegion(localeCode: "sl", filename: "")
    private static let sv = ContentBlockerRegion(localeCode: "sv", filename: "")
    private static let tr = ContentBlockerRegion(localeCode: "tr", filename: "")
    private static let vi = ContentBlockerRegion(localeCode: "vi", filename: "")
    
    /// Get a `ContentBlockerRegion` for a given locale if one exists for that region
    static func with(localeCode: String) -> ContentBlockerRegion? {
        switch localeCode {
        case ContentBlockerRegion.ar.localeCode: return .ar
        case ContentBlockerRegion.bg.localeCode: return .bg
        case ContentBlockerRegion.zh.localeCode: return .zh
        case ContentBlockerRegion.cs.localeCode: return .cs
        case ContentBlockerRegion.de.localeCode: return .de
        case ContentBlockerRegion.da.localeCode: return .da
        case ContentBlockerRegion.et.localeCode: return .et
        case ContentBlockerRegion.fi.localeCode: return .fi
        case ContentBlockerRegion.fr.localeCode: return .fr
        case ContentBlockerRegion.el.localeCode: return .el
        case ContentBlockerRegion.hu.localeCode: return .hu
        case ContentBlockerRegion.id.localeCode: return .id
        case ContentBlockerRegion.hi.localeCode: return .hi
        case ContentBlockerRegion.fa.localeCode: return .fa
        case ContentBlockerRegion.is.localeCode: return .is
        case ContentBlockerRegion.he.localeCode: return .he
        case ContentBlockerRegion.it.localeCode: return .it
        case ContentBlockerRegion.ja.localeCode: return .ja
        case ContentBlockerRegion.ko.localeCode: return .ko
        case ContentBlockerRegion.lt.localeCode: return .lt
        case ContentBlockerRegion.lv.localeCode: return .lv
        case ContentBlockerRegion.nl.localeCode: return .nl
        case ContentBlockerRegion.pl.localeCode: return .pl
        case ContentBlockerRegion.ru.localeCode: return .ru
        case ContentBlockerRegion.uk.localeCode: return .uk
        case ContentBlockerRegion.be.localeCode: return .be
        case ContentBlockerRegion.es.localeCode: return .es
        case ContentBlockerRegion.sl.localeCode: return .sl
        case ContentBlockerRegion.sv.localeCode: return .sv
        case ContentBlockerRegion.tr.localeCode: return .tr
        case ContentBlockerRegion.vi.localeCode: return .vi
        default: return nil
        }
    }
    
    private let localeCode: String
    
    private init(localeCode: String, filename: String) {
        self.localeCode = localeCode
        super.init(filename: filename)
    }
}
