const {AdBlockClient, FilterOptions} = require('..')
const path = require('path')
const fs = require('fs')
const request = require('request')
const braveUnbreakPath = './test/data/brave-unbreak.txt'
const {getListBufferFromURL, getListFilterFunction} = require('../lib/util')
const {adBlockLists} = require('..')

let totalExceptionFalsePositives = 0
let totalNumFalsePositives = 0
let totalTime = 0

const generateDataFileFromString = (filterRuleData, outputDATFilename) => {
  const client = new AdBlockClient()
  if (filterRuleData.constructor === Array) {
    filterRuleData.forEach(filterRuleDataItem => client.parse(filterRuleDataItem))
  } else {
    client.parse(filterRuleData)
  }

  console.log('Parsing stats:', client.getParsingStats())
  client.enableBadFingerprintDetection()
  checkSiteList(client, top500URLList20k)
  client.generateBadFingerprintsHeader('bad_fingerprints.h')
  const serializedData = client.serialize()
  if (!fs.existsSync('out')) {
    fs.mkdirSync('./out')
  }
  fs.writeFileSync(path.join('out', outputDATFilename), serializedData)
}

const generateDataFileFromURL = (listURL, outputDATFilename, filter) => {
  return new Promise((resolve, reject) => {
    console.log(`${listURL}...`)
    request.get(listURL, function (error, response, body) {
      if (error) {
        console.error(`Request error: ${error}`)
        reject()
        return
      }
      if (response.statusCode !== 200) {
        console.error(`Error status code ${response.statusCode} returned for URL: ${listURL}`)
        reject()
        return
      }
      const braveUnbreakBody = fs.readFileSync(braveUnbreakPath, 'utf8')
      if (filter) {
        body = filter(body)
      }
      generateDataFileFromString([body, braveUnbreakBody], outputDATFilename)
      resolve()
    })
  })
}

const generateDataFilesForAllRegions = () => {
  let p = Promise.resolve()
  adBlockLists.regions.forEach((region) => {
    p = p.then(generateDataFileFromURL.bind(null, region.listURL, `${region.uuid}.dat`))
  })
  p = p.then(() => {
    console.log(`Total time: ${totalTime / 1000}s ${totalTime % 1000}ms`)
    console.log(`Num false positives: ${totalNumFalsePositives}`)
    console.log(`Num exception false positives: ${totalExceptionFalsePositives}`)
  })
  return p
}

const generateDataFilesForList = (lists, filename) => {
  let promises = []
  lists.forEach((l) => {
    console.log(`${l.listURL}...`)
    const filterFn = getListFilterFunction(l.uuid)
    promises.push(getListBufferFromURL(l.listURL, filterFn))
  })
  let p = Promise.all(promises)
  p = p.then((listBuffers) => {
    generateDataFileFromString(listBuffers, filename)
  }).catch((e) => {
    console.log('Erorr', e)
  })
  return p
}

const generateDataFilesForMalware = generateDataFilesForList.bind(null, adBlockLists.malware, 'SafeBrowsingData.dat')
const generateDataFilesForDefaultAdblock = generateDataFilesForList.bind(null, adBlockLists.default, 'ABPFilterParserData.dat')

const checkSiteList = (client, siteList) => {
  const start = new Date().getTime()
  siteList.forEach(site => {
    // console.log('matches: ', client.matches(site,  FilterOptions.image, 'slashdot.org'))
    client.matches(site, FilterOptions.noFilterOption, 'slashdot.org')
  })
  const stats = client.getMatchingStats()
  console.log('Matching stats:', stats)
  totalNumFalsePositives += stats.numFalsePositives
  totalExceptionFalsePositives += stats.numExceptionFalsePositives
  const end = new Date().getTime()
  const time = end - start
  totalTime += time
  console.log('done, time: ', time, 'ms')
}

const top500URLList20k = fs.readFileSync('./test/data/sitelist.txt', 'utf8').split('\n')
// const shortURLList = fs.readFileSync('./test/data/short-sitelist.txt', 'utf8').split('\n')

generateDataFilesForDefaultAdblock()
  .then(generateDataFilesForMalware)
  .then(generateDataFilesForAllRegions)
  .then(() => {
    console.log('Thank you for updating the data files!')
  })
  .catch(() => {
    console.error('Something went wrong, aborting!')
    process.exit(1)
  })
