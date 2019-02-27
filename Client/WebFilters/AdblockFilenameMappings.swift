// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct AdblockFilenameMappings {
    static let generalAdblockName = "latest"
    
    static func localeToFilename(_ locale: String) -> String? {
        var fileName: String?
        
        switch locale {
        case Locales.ar.rawValue: fileName = "9FCEECEC-52B4-4487-8E57-8781E82C91D0-latest"
        case Locales.bg.rawValue: fileName = "FD176DD1-F9A0-4469-B43E-B1764893DD5C-latest"
        case Locales.zh.rawValue: fileName = "11F62B02-9D1F-4263-A7F8-77D2B55D4594-latest"
        case Locales.cs.rawValue: fileName = "7CCB6921-7FDA-4A9B-B70A-12DD0A8F08EA-latest"
        case Locales.de.rawValue: fileName = "E71426E7-E898-401C-A195-177945415F38-latest"
        case Locales.da.rawValue: fileName = "9EF6A21C-5014-4199-95A2-A82491274203-latest"
        case Locales.et.rawValue: fileName = "0783DBFD-B5E0-4982-9B4A-711BDDB925B7-latest"
        case Locales.fi.rawValue: fileName = "1C6D8556-3400-4358-B9AD-72689D7B2C46-latest"
        case Locales.fr.rawValue: fileName = "9852EFC4-99E4-4F2D-A915-9C3196C7A1DE-latest"
        case Locales.el.rawValue: fileName = "6C0F4C7F-969B-48A0-897A-14583015A587-latest"
        case Locales.hu.rawValue: fileName = "EDEEE15A-6FA9-4FAC-8CA8-3565508EAAC3-latest"
        case Locales.id.rawValue: fileName = "93123971-5AE6-47BA-93EA-BE1E4682E2B6-latest"
        case Locales.hi.rawValue: fileName = "4C07DB6B-6377-4347-836D-68702CF1494A-latest"
        case Locales.fa.rawValue: fileName = "C3C2F394-D7BB-4BC2-9793-E0F13B2B5971-latest"
        case Locales.is.rawValue: fileName = "48796273-E783-431E-B864-44D3DCEA66DC-latest"
        case Locales.he.rawValue: fileName = "85F65E06-D7DA-4144-B6A5-E1AA965D1E47-latest"
        case Locales.it.rawValue: fileName = "AB1A661D-E946-4F29-B47F-CA3885F6A9F7-latest"
        case Locales.ja.rawValue: fileName = "03F91310-9244-40FA-BCF6-DA31B832F34D-latest"
        case Locales.ko.rawValue: fileName = "1E6CF01B-AFC4-47D2-AE59-3E32A1ED094F-latest"
        case Locales.lt.rawValue: fileName = "4E8B1A63-DEBE-4B8B-AD78-3811C632B353-latest"
        case Locales.lv.rawValue: fileName = "15B64333-BAF9-4B77-ADC8-935433CD6F4C-latest"
        case Locales.nl.rawValue: fileName = "9D644676-4784-4982-B94D-C9AB19098D2A-latest"
        case Locales.pl.rawValue: fileName = "BF9234EB-4CB7-4CED-9FCB-F1FD31B0666C-latest"
        // ru, uk, be locales have the same file name
        case Locales.ru.rawValue: fileName = "80470EEC-970F-4F2C-BF6B-4810520C72E6-latest"
        case Locales.uk.rawValue: fileName = "80470EEC-970F-4F2C-BF6B-4810520C72E6-latest"
        case Locales.be.rawValue: fileName = "80470EEC-970F-4F2C-BF6B-4810520C72E6-latest"
        case Locales.es.rawValue: fileName = "AE657374-1851-4DC4-892B-9212B13B15A7-latest"
        case Locales.sl.rawValue: fileName = "418D293D-72A8-4A28-8718-A1EE40A45AAF-latest"
        case Locales.sv.rawValue: fileName = "7DC2AC80-5BBC-49B8-B473-A31A1145CAC1-latest"
        case Locales.tr.rawValue: fileName = "1BE19EFD-9191-4560-878E-30ECA72B5B3C-latest"
        case Locales.vi.rawValue: fileName = "6A0209AC-9869-4FD6-A9DF-039B4200D52C-latest"
        default: fileName = nil
        }
        
        return fileName
    }
    
    static func fileNameToLocale(_ name: String) -> String? {
        var locale: String?
        switch locale {
        case FileNames.ar.rawValue: locale = Locales.ar.rawValue
        case FileNames.bg.rawValue: locale = Locales.bg.rawValue
        case FileNames.zh.rawValue: locale = Locales.zh.rawValue
        case FileNames.cs.rawValue: locale = Locales.cs.rawValue
        case FileNames.de.rawValue: locale = Locales.de.rawValue
        case FileNames.da.rawValue: locale = Locales.da.rawValue
        case FileNames.et.rawValue: locale = Locales.et.rawValue
        case FileNames.fi.rawValue: locale = Locales.fi.rawValue
        case FileNames.fr.rawValue: locale = Locales.fr.rawValue
        case FileNames.el.rawValue: locale = Locales.el.rawValue
        case FileNames.hu.rawValue: locale = Locales.hu.rawValue
        case FileNames.id.rawValue: locale = Locales.id.rawValue
        case FileNames.hi.rawValue: locale = Locales.hi.rawValue
        case FileNames.fa.rawValue: locale = Locales.fa.rawValue
        case FileNames.is.rawValue: locale = Locales.is.rawValue
        case FileNames.he.rawValue: locale = Locales.he.rawValue
        case FileNames.it.rawValue: locale = Locales.it.rawValue
        case FileNames.ja.rawValue: locale = Locales.ja.rawValue
        case FileNames.ko.rawValue: locale = Locales.ko.rawValue
        case FileNames.lt.rawValue: locale = Locales.lt.rawValue
        case FileNames.lv.rawValue: locale = Locales.lv.rawValue
        case FileNames.nl.rawValue: locale = Locales.nl.rawValue
        case FileNames.pl.rawValue: locale = Locales.pl.rawValue
        case FileNames.ru.rawValue: locale = Locales.ru.rawValue
        case FileNames.uk.rawValue: locale = Locales.uk.rawValue
        case FileNames.be.rawValue: locale = Locales.be.rawValue
        case FileNames.es.rawValue: locale = Locales.es.rawValue
        case FileNames.sl.rawValue: locale = Locales.sl.rawValue
        case FileNames.sv.rawValue: locale = Locales.sv.rawValue
        case FileNames.tr.rawValue: locale = Locales.tr.rawValue
        case FileNames.vi.rawValue: locale = Locales.vi.rawValue
        default: locale = nil
        }
        
        return locale
    }
}

fileprivate enum FileNames: String {
    case ar = "9FCEECEC-52B4-4487-8E57-8781E82C91D0-latest"
    case bg = "FD176DD1-F9A0-4469-B43E-B1764893DD5C-latest"
    case zh = "11F62B02-9D1F-4263-A7F8-77D2B55D4594-latest"
    case cs = "7CCB6921-7FDA-4A9B-B70A-12DD0A8F08EA-latest"
    case de = "E71426E7-E898-401C-A195-177945415F38-latest"
    case da = "9EF6A21C-5014-4199-95A2-A82491274203-latest"
    case et = "0783DBFD-B5E0-4982-9B4A-711BDDB925B7-latest"
    case fi = "1C6D8556-3400-4358-B9AD-72689D7B2C46-latest"
    case fr = "9852EFC4-99E4-4F2D-A915-9C3196C7A1DE-latest"
    case el = "6C0F4C7F-969B-48A0-897A-14583015A587-latest"
    case hu = "EDEEE15A-6FA9-4FAC-8CA8-3565508EAAC3-latest"
    case id = "93123971-5AE6-47BA-93EA-BE1E4682E2B6-latest"
    case hi = "4C07DB6B-6377-4347-836D-68702CF1494A-latest"
    case fa = "C3C2F394-D7BB-4BC2-9793-E0F13B2B5971-latest"
    case `is` = "48796273-E783-431E-B864-44D3DCEA66DC-latest"
    case he = "85F65E06-D7DA-4144-B6A5-E1AA965D1E47-latest"
    case it = "AB1A661D-E946-4F29-B47F-CA3885F6A9F7-latest"
    case ja = "03F91310-9244-40FA-BCF6-DA31B832F34D-latest"
    case ko = "1E6CF01B-AFC4-47D2-AE59-3E32A1ED094F-latest"
    case lt = "4E8B1A63-DEBE-4B8B-AD78-3811C632B353-latest"
    case lv = "15B64333-BAF9-4B77-ADC8-935433CD6F4C-latest"
    case nl = "9D644676-4784-4982-B94D-C9AB19098D2A-latest"
    case pl = "BF9234EB-4CB7-4CED-9FCB-F1FD31B0666C-latest"
    case ru, uk, be = "80470EEC-970F-4F2C-BF6B-4810520C72E6-latest"
    case es = "AE657374-1851-4DC4-892B-9212B13B15A7-latest"
    case sl = "418D293D-72A8-4A28-8718-A1EE40A45AAF-latest"
    case sv = "7DC2AC80-5BBC-49B8-B473-A31A1145CAC1-latest"
    case tr = "1BE19EFD-9191-4560-878E-30ECA72B5B3C-latest"
    case vi = "6A0209AC-9869-4FD6-A9DF-039B4200D52C-latest"
}

fileprivate enum Locales: String {
    case ar
    case bg
    case zh
    case cs
    case de
    case da
    case et
    case fi
    case fr
    case el
    case hu
    case id
    case hi
    case fa
    case `is`
    case he
    case it
    case ja
    case ko
    case lt
    case lv
    case nl
    case pl
    case ru
    case uk
    case be
    case es
    case sl
    case sv
    case tr
    case vi
}
