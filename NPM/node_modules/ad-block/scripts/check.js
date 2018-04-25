/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Example invocations:
 * Basic checking a URL:
 *   node scripts/check.js  --host www.cnet.com --location https://s0.2mdn.net/instream/html5/ima3.js
 * Checking with a particular resource type:
 *   node scripts/check.js --host www.scrumpoker.online --location https://www.scrumpoker.online/js/angular-google-analytics.js -O script
 * Checking a URL with discovery:
 *   node scripts/check.js  --host www.cnet.com --location "https://slashdot.org?t=1&ad_box_=2" --discover
 * Checking a URL against a particular adblock list:
 *   node scripts/check.js  --uuid 03F91310-9244-40FA-BCF6-DA31B832F34D --host slashdot.org --location https://s.yimg.jp/images/ds/ult/toppage/rapidjp-1.0.0.js
 * Checking a URL from a loaded DAT file:
 *   node scripts/check.js --dat ./out/SafeBrowsingData.dat --host excellentmovies.net --location https://excellentmovies.net
 * Checking a URL from a list URL:
 *   node scripts/check.js --http https://easylist-downloads.adblockplus.org/easylist.txt --host excellentmovies.net --location http://simple-adblock.com/adblocktest/files/adbanner.gif
 * Checking a list of URLs:
 *   node scripts/check.js  --host www.cnet.com --list ./test/data/sitelist.txt
 * Checking a list of URLS with discovery:
 *  node scripts/check.js  --host www.cnet.com --list ./test/data/sitelist.txt --discover
*/
const commander = require('commander')
const {makeAdBlockClientFromListUUID, makeAdBlockClientFromDATFile, makeAdBlockClientFromListURL, makeAdBlockClientFromString, makeAdBlockClientFromFilePath, readSiteList} = require('../lib/util')
const {FilterOptions} = require('..')

const filterStringToFilterOption = (val) => FilterOptions[val]

commander
  .option('-u, --uuid [uuid]', 'UUID of the list to use')
  .option('-d, --dat [dat]', 'file path of the adblock .dat file')
  .option('-f, --filter [filter]', 'Brave filter rules')
  .option('-F, --filter-path [filterPath]', 'Brave filter rules file path')
  .option('-w, --http [http]', 'Web filter to use')
  .option('-h, --host [host]', 'host of the page that is being loaded')
  .option('-l, --location [location]', 'URL to use for the check')
  .option('-o, --output [output]', 'Optionally saves a DAT file')
  .option('-L --list [list]', 'Filename for list of sites to check')
  .option('-D --discover', 'If speciied does filter discovery for matched filter')
  .option('-C, --cache', 'Optionally cache results and use cached results')
  .option('-O, --filter-option [filterOption]', 'Filter option to use', filterStringToFilterOption, FilterOptions.noFilterOption)
  .parse(process.argv)

let p = Promise.reject('Usage: node check.js --location <location> --host <host> [--uuid <uuid>]')

if (commander.host && (commander.location || commander.list)) {
  p.catch(() => {})
  if (commander.uuid) {
    p = makeAdBlockClientFromListUUID(commander.uuid)
  } else if (commander.dat) {
    p = makeAdBlockClientFromDATFile(commander.dat)
  } else if (commander.http) {
    p = makeAdBlockClientFromListURL(commander.http)
  } else if (commander.filter) {
    p = makeAdBlockClientFromString(commander.filter)
  } else if (commander.filterPath) {
    p = makeAdBlockClientFromFilePath(commander.filterPath)
  } else {
    const defaultLists = require('../').adBlockLists.default
      .map((listObj) => listObj.listURL)
    p = makeAdBlockClientFromListURL(defaultLists)
  }
}

p.then((adBlockClient) => {
  console.log('Parsing stats:', adBlockClient.getParsingStats())
  if (commander.location) {
    console.log('params:', commander.location, commander.filterOption, commander.host)
    if (commander.discover) {
      console.log(adBlockClient.findMatchingFilters(commander.location, commander.filterOption, commander.host))
    } else {
      console.log('Matches: ', adBlockClient.matches(commander.location, commander.filterOption, commander.host))
    }
    console.log(adBlockClient.getMatchingStats())
  } else {
    const siteList = readSiteList(commander.list)
    let matchCount = 0
    let skipCount = 0
    console.time('check')
    if (commander.discover) {
      const m = new Map()
      siteList.forEach((site) => {
        if (commander.cache && m.has(site)) {
          if (m.get(site)) {
            matchCount++
          } else {
            skipCount++
          }
          return
        }
        if (adBlockClient.findMatchingFilters(site, commander.filterOption, commander.host)) {
          matchCount++
          m.set(site, true)
        } else {
          skipCount++
          m.set(site, false)
        }
      })
    } else {
      siteList.forEach((site) => {
        if (adBlockClient.matches(site, commander.filterOption, commander.host)) {
          matchCount++
        } else {
          skipCount++
        }
      })
    }
    console.timeEnd('check')
    console.log(adBlockClient.getMatchingStats())
    console.log('Matching:', matchCount)
    console.log('Skipped:', skipCount)
  }
  if (commander.output) {
    require('fs').writeFileSync(commander.output, adBlockClient.serialize())
  }
}).catch((e) => {
  console.log('Error:', e)
})
