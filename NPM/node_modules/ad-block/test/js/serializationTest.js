/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */
/* global describe, it, before */

const assert = require('assert')
const {makeAdBlockClientFromString} = require('../../lib/util')
const {AdBlockClient, FilterOptions} = require('../..')

describe('serialization', function () {
  before(function (cb) {
    const ruleData = `
      [Adblock Plus 2.0]
      &video_ads_
      &videoadid=
      &view=ad&
      +advertorial.
      +adverts/
      -2/ads/
      -2011ad_
      -300x100ad2.
      -ad-001-
      -ad-180x150px.
      -ad-200x200-
      ! comment here
    `
    makeAdBlockClientFromString(ruleData).then((client) => {
      this.client = client
      this.data = this.client.serialize()
      this.client2 = new AdBlockClient()
      this.client2.deserialize(this.data)
      cb()
    })
  })

  it('blocks things the same when created from serialized', function () {
    assert(this.client.matches('http://www.brianbondy.com?c=a&view=ad&b=2', FilterOptions.image, 'slashdot.org'))
    assert(!this.client.matches('http://www.brianbondy.com?c=a&view1=ad&b=2', FilterOptions.image, 'slashdot.org'))
    assert(this.client2.matches('http://www.brianbondy.com?c=a&view=ad&b=2', FilterOptions.image, 'slashdot.org'))
    assert(!this.client2.matches('http://www.brianbondy.com?c=a&view1=ad&b=2', FilterOptions.image, 'slashdot.org'))
  })
  it('deserialized client serializes the same', function () {
    this.client2.deserialize(this.data)
    const data2 = this.client2.serialize()
    assert(this.data.equals(data2))
  })
  it('deserializes with the same number of filters', function () {
    const nonComentFilterCount = 11
    assert.equal(this.client.getParsingStats().numFilters, nonComentFilterCount)
    assert.equal(this.client2.getParsingStats().numFilters, nonComentFilterCount)
  })
  it('serialized data does not include comment data', function () {
    assert(!this.data.toString().includes('comment'))
    assert(!this.data.toString().includes('Adblock Plus'))
  })
})
