/* Copyright (c) 2015 Brian R. Bondy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef LISTS_REGIONS_H_
#define LISTS_REGIONS_H_

#include <vector>
#include "../filter_list.h"

const std::vector<FilterList> region_lists = {
  FilterList({
    "9FCEECEC-52B4-4487-8E57-8781E82C91D0",
    "https://easylist-downloads.adblockplus.org/Liste_AR.txt",
    "ARA: Liste AR",
    {"ar"},
    "https://forums.lanik.us/viewforum.php?f=98"
  }), FilterList({
    "FD176DD1-F9A0-4469-B43E-B1764893DD5C",
    "http://stanev.org/abp/adblock_bg.txt",
    "BGR: Bulgarian Adblock list",
    {"bg"},
    "http://stanev.org/abp/"
  }), FilterList({
    "11F62B02-9D1F-4263-A7F8-77D2B55D4594",
    "https://easylist-downloads.adblockplus.org/easylistchina.txt",
    "CHN: EasyList China (中文)",
    {"zh"},
    "http://abpchina.org/forum/forum.php"
  }), FilterList({
    "CC98E4BA-9257-4386-A1BC-1BBF6980324F",
    "https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt", // NOLINT
    "CHN: CJX's Annoyance List",
    {},
    "https://github.com/cjx82630/cjxlist"
  }), FilterList({
    "92AA0D3B-34AC-4657-9A5C-DBAD339AF8E2",
    "https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjxlist.txt",
    "CHN: CJX's EasyList Lite (main focus on Chinese sites)",
    {},
    "https://github.com/cjx82630/cjxlist"
  }), FilterList({
    "7CCB6921-7FDA-4A9B-B70A-12DD0A8F08EA",
    "https://raw.githubusercontent.com/tomasko126/easylistczechandslovak/master/filters.txt", // NOLINT
    "CZE, SVK: EasyList Czech and Slovak",
    {"cs"},
    "https://github.com/tomasko126/easylistczechandslovak"
  }), FilterList({
    "E71426E7-E898-401C-A195-177945415F38",
    "https://easylist-downloads.adblockplus.org/easylistgermany.txt",
    "DEU: EasyList Germany",
    {"de"},
    "https://forums.lanik.us/viewforum.php?f=90"
  }), FilterList({
    "9EF6A21C-5014-4199-95A2-A82491274203",
    "https://adblock.dk/block.csv",
    "DNK: Schacks Adblock Plus liste",
    {"da"},
    "https://henrik.schack.dk/adblock/"
  }), FilterList({
    "0783DBFD-B5E0-4982-9B4A-711BDDB925B7",
    "http://adblock.ee/list.php",
    "EST: Eesti saitidele kohandatud filter",
    {"et"},
    "http://adblock.ee/"
  }), FilterList({
    "5E5C9C94-0516-45F2-9AFB-800F0EC74FCA",
    "https://raw.githubusercontent.com/liamja/Prebake/master/obtrusive.txt",
    "EU: Prebake - Filter Obtrusive Cookie Notices",
    {},
    "https://github.com/liamja/Prebake"
  }), FilterList({
    "1C6D8556-3400-4358-B9AD-72689D7B2C46",
    "http://adb.juvander.net/Finland_adb.txt",
    "FIN: Finnish Addition to Easylist",
    {"fi"},
    "http://www.juvander.fi/AdblockFinland"
  }), FilterList({
    "9852EFC4-99E4-4F2D-A915-9C3196C7A1DE",
    "https://easylist-downloads.adblockplus.org/liste_fr.txt",
    "FRA: EasyList Liste FR",
    {"fr"},
    "https://forums.lanik.us/viewforum.php?f=91"
  }), FilterList({
    "6C0F4C7F-969B-48A0-897A-14583015A587",
    "https://www.void.gr/kargig/void-gr-filters.txt",
    "GRC: Greek AdBlock Filter",
    {"el"},
    "https://github.com/kargig/greek-adblockplus-filter"
  }), FilterList({
    "EDEEE15A-6FA9-4FAC-8CA8-3565508EAAC3",
    "https://raw.githubusercontent.com/szpeter80/hufilter/master/hufilter.txt",
    "HUN: hufilter",
    {"hu"},
    "https://github.com/szpeter80/hufilter"
  }), FilterList({
    "93123971-5AE6-47BA-93EA-BE1E4682E2B6",
    "https://raw.githubusercontent.com/heradhis/indonesianadblockrules/master/subscriptions/abpindo.txt", //NOLINT
    "IDN: ABPindo",
    {"id"},
    "https://github.com/heradhis/indonesianadblockrules"
  }), FilterList({
    "4C07DB6B-6377-4347-836D-68702CF1494A",
    "https://secure.fanboy.co.nz/fanboy-indian.txt",
    "IN: Fanboy's India Filters",
    {"hi"},
    "https://www.fanboy.co.nz/filters.html"
  }), FilterList({
    "C3C2F394-D7BB-4BC2-9793-E0F13B2B5971",
    "https://raw.githubusercontent.com/farrokhi/adblock-iran/master/filter.txt",
    "IRN: AdBlock Iran Filter",
    {"fa"},
    "https://github.com/farrokhi/adblock-iran"
  }), FilterList({
    "48796273-E783-431E-B864-44D3DCEA66DC",
    "http://adblock.gardar.net/is.abp.txt",
    "ISL: Icelandic ABP List",
    {"is"},
    "http://adblock.gardar.net/"
  }), FilterList({
    "85F65E06-D7DA-4144-B6A5-E1AA965D1E47",
    "https://raw.githubusercontent.com/easylist/EasyListHebrew/master/EasyListHebrew.txt", // NOLINT
    "ISR: EasyList Hebrew",
    {"he"},
    "https://github.com/easylist/EasyListHebrew"
  }), FilterList({
    "A0E9F361-A01F-4C0E-A52D-2977A1AD4BFB",
    "https://raw.githubusercontent.com/gioxx/xfiles/master/filtri.txt",
    "ITA: ABP X Files",
    {},
    "https://xfiles.noads.it/"
  }), FilterList({
    "AB1A661D-E946-4F29-B47F-CA3885F6A9F7",
    "https://easylist-downloads.adblockplus.org/easylistitaly.txt",
    "ITA: EasyList Italy",
    {"it"},
    "https://forums.lanik.us/viewforum.php?f=96"
  }), FilterList({
    "03F91310-9244-40FA-BCF6-DA31B832F34D",
    "https://raw.githubusercontent.com/k2jp/abp-japanese-filters/master/abpjf.txt", // NOLINT
    "JPN: ABP Japanese filters (日本用フィルタ)",
    {"ja"},
    "https://github.com/k2jp/abp-japanese-filters/wiki/Support_Policy"
  }), FilterList({
    "51260D6E-28F8-4EEC-B76D-3046DADC27C9",
    "https://www.fanboy.co.nz/fanboy-korean.txt",
    "KOR: Fanboy's Korean",
    {},
    "https://forums.lanik.us/"
  }), FilterList({
    "1E6CF01B-AFC4-47D2-AE59-3E32A1ED094F",
    "https://raw.githubusercontent.com/gfmaster/adblock-korea-contrib/master/filter.txt", // NOLINT
    "KOR: Korean Adblock List",
    {"ko"},
    "https://github.com/gfmaster/adblock-korea-contrib"
  }), FilterList({
    "45B3ED40-C607-454F-A623-195FDD084637",
    "https://raw.githubusercontent.com/yous/YousList/master/youslist.txt",
    "KOR: YousList",
    {"ko"},
    "https://github.com/yous/YousList"
  }), FilterList({
    "4E8B1A63-DEBE-4B8B-AD78-3811C632B353",
    "http://margevicius.lt/easylistlithuania.txt",
    "LTU: Adblock Plus Lithuania",
    {"lt"},
    "http://margevicius.lt/easylist_lithuania/"
  }), FilterList({
    "15B64333-BAF9-4B77-ADC8-935433CD6F4C",
    "https://notabug.org/latvian-list/adblock-latvian/raw/master/lists/latvian-list.txt", // NOLINT
    "LVA: Latvian List",
    {"lv"},
    "https://notabug.org/latvian-list/adblock-latvian"
  }), FilterList({
    "9D644676-4784-4982-B94D-C9AB19098D2A",
    "https://easylist-downloads.adblockplus.org/easylistdutch.txt",
    "NLD: EasyList Dutch",
    {"nl"},
    "https://forums.lanik.us/viewforum.php?f=100"
  }), FilterList({
    "BF9234EB-4CB7-4CED-9FCB-F1FD31B0666C",
    "https://www.certyficate.it/adblock/adblock.txt",
    "POL: polskie filtry do Adblocka i uBlocka",
    {"pl"},
    "http://www.certyficate.it/adblock-ublock-polish-filters/"
  }), FilterList({
    "1088D292-2369-4D40-9BDF-C7DC03C05966",
    "https://adguard.com/en/filter-rules.html?id=1",
    "RUS: Adguard Russian Filter",
    {},
    "http://forum.adguard.com/forumdisplay.php?69-%D0%A4%D0%B8%D0%BB%D1%8C%D1%82%D1%80%D1%8B-Adguard" // NOLINT
  }), FilterList({
    "DABC6490-70E5-46DD-8BE2-358FB9A37C85",
    "https://easylist-downloads.adblockplus.org/bitblock.txt",
    "RUS: BitBlock List (Дополнительная подписка фильтров)",
    {},
    "https://forums.lanik.us/viewforum.php?f=102"
  }), FilterList({
    "80470EEC-970F-4F2C-BF6B-4810520C72E6",
    "https://easylist-downloads.adblockplus.org/advblock.txt",
    "RUS: RU AdList (Дополнительная региональная подписка)",
    {"ru", "uk", "be"},
    "https://forums.lanik.us/viewforum.php?f=102"
  }), FilterList({
    "AE657374-1851-4DC4-892B-9212B13B15A7",
    "https://easylist-downloads.adblockplus.org/easylistspanish.txt",
    "SPA: EasyList Spanish",
    {"es"},
    "https://forums.lanik.us/viewforum.php?f=103"
  }), FilterList({
    "418D293D-72A8-4A28-8718-A1EE40A45AAF",
    "https://raw.githubusercontent.com/betterwebleon/slovenian-list/master/filters.txt", // NOLINT
    "SVN: Slovenian List",
    {"sl"},
    "https://github.com/betterwebleon/slovenian-list"
  }), FilterList({
    "7DC2AC80-5BBC-49B8-B473-A31A1145CAC1",
    "https://www.fanboy.co.nz/fanboy-swedish.txt",
    "SWE: Fanboy's Swedish",
    {"sv"},
    "https://forums.lanik.us/"
  }), FilterList({
    "1BE19EFD-9191-4560-878E-30ECA72B5B3C",
    "https://adguard.com/filter-rules.html?id=13",
    "TUR: Adguard Turkish Filter",
    {"tr"},
    "http://forum.adguard.com/forumdisplay.php?51-Filter-Rules"
  }), FilterList({
    "6A0209AC-9869-4FD6-A9DF-039B4200D52C",
    "https://www.fanboy.co.nz/fanboy-vietnam.txt",
    "VIE: Fanboy's Vietnamese",
    {"vi"},
    "https://forums.lanik.us/"
  })
};

#endif  // LISTS_REGIONS_H_
