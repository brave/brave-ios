// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WebKit
import Shared
import Deferred
import Data
import BraveShared

class ContentBlockerRegion: BlocklistName {
    private static let ar = ContentBlockerRegion(localeCode: "ar", filename: "9FCEECEC-52B4-4487-8E57-8781E82C91D0-latest")
    private static let bg = ContentBlockerRegion(localeCode: "bg", filename: "FD176DD1-F9A0-4469-B43E-B1764893DD5C-latest")
    private static let zh = ContentBlockerRegion(localeCode: "zh", filename: "11F62B02-9D1F-4263-A7F8-77D2B55D4594-latest")
    private static let cs = ContentBlockerRegion(localeCode: "cs", filename: "7CCB6921-7FDA-4A9B-B70A-12DD0A8F08EA-latest")
    private static let de = ContentBlockerRegion(localeCode: "de", filename: "E71426E7-E898-401C-A195-177945415F38-latest")
    private static let da = ContentBlockerRegion(localeCode: "da", filename: "9EF6A21C-5014-4199-95A2-A82491274203-latest")
    private static let et = ContentBlockerRegion(localeCode: "et", filename: "0783DBFD-B5E0-4982-9B4A-711BDDB925B7-latest")
    private static let fi = ContentBlockerRegion(localeCode: "fi", filename: "1C6D8556-3400-4358-B9AD-72689D7B2C46-latest")
    private static let fr = ContentBlockerRegion(localeCode: "fr", filename: "9852EFC4-99E4-4F2D-A915-9C3196C7A1DE-latest")
    private static let el = ContentBlockerRegion(localeCode: "el", filename: "6C0F4C7F-969B-48A0-897A-14583015A587-latest")
    private static let hu = ContentBlockerRegion(localeCode: "hu", filename: "EDEEE15A-6FA9-4FAC-8CA8-3565508EAAC3-latest")
    private static let id = ContentBlockerRegion(localeCode: "id", filename: "93123971-5AE6-47BA-93EA-BE1E4682E2B6-latest")
    private static let hi = ContentBlockerRegion(localeCode: "hi", filename: "4C07DB6B-6377-4347-836D-68702CF1494A-latest")
    private static let fa = ContentBlockerRegion(localeCode: "fa", filename: "C3C2F394-D7BB-4BC2-9793-E0F13B2B5971-latest")
    private static let `is` = ContentBlockerRegion(localeCode: "is", filename: "48796273-E783-431E-B864-44D3DCEA66DC-latest")
    private static let he = ContentBlockerRegion(localeCode: "he", filename: "85F65E06-D7DA-4144-B6A5-E1AA965D1E47-latest")
    private static let it = ContentBlockerRegion(localeCode: "it", filename: "AB1A661D-E946-4F29-B47F-CA3885F6A9F7-latest")
    private static let ja = ContentBlockerRegion(localeCode: "ja", filename: "03F91310-9244-40FA-BCF6-DA31B832F34D-latest")
    private static let ko = ContentBlockerRegion(localeCode: "ko", filename: "1E6CF01B-AFC4-47D2-AE59-3E32A1ED094F-latest")
    private static let lt = ContentBlockerRegion(localeCode: "lt", filename: "4E8B1A63-DEBE-4B8B-AD78-3811C632B353-latest")
    private static let lv = ContentBlockerRegion(localeCode: "lv", filename: "15B64333-BAF9-4B77-ADC8-935433CD6F4C-latest")
    private static let nl = ContentBlockerRegion(localeCode: "nl", filename: "9D644676-4784-4982-B94D-C9AB19098D2A-latest")
    private static let pl = ContentBlockerRegion(localeCode: "pl", filename: "BF9234EB-4CB7-4CED-9FCB-F1FD31B0666C-latest")
    private static let ru = ContentBlockerRegion(localeCode: "ru", filename: "80470EEC-970F-4F2C-BF6B-4810520C72E6-latest")
    private static let uk = ContentBlockerRegion(localeCode: "uk", filename: "80470EEC-970F-4F2C-BF6B-4810520C72E6-latest")
    private static let be = ContentBlockerRegion(localeCode: "be", filename: "80470EEC-970F-4F2C-BF6B-4810520C72E6-latest")
    private static let es = ContentBlockerRegion(localeCode: "es", filename: "AE657374-1851-4DC4-892B-9212B13B15A7-latest")
    private static let sl = ContentBlockerRegion(localeCode: "sl", filename: "418D293D-72A8-4A28-8718-A1EE40A45AAF-latest")
    private static let sv = ContentBlockerRegion(localeCode: "sv", filename: "7DC2AC80-5BBC-49B8-B473-A31A1145CAC1-latest")
    private static let tr = ContentBlockerRegion(localeCode: "tr", filename: "1BE19EFD-9191-4560-878E-30ECA72B5B3C-latest")
    private static let vi = ContentBlockerRegion(localeCode: "vi", filename: "6A0209AC-9869-4FD6-A9DF-039B4200D52C-latest")
    
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
