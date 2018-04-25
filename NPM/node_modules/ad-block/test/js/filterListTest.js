/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */
/* global describe, it */

const assert = require('assert')
const {adBlockLists} = require('../..')

describe('adBlockLists', function () {
  describe('default', function () {
    it('contains 4 default lists', function () {
      assert.equal(adBlockLists.default.length, 4)
    })
    it('has uuid property', function () {
      adBlockLists.default.forEach((list) => {
        assert(!!list.uuid)
      })
    })
    it('does not have langs property', function () {
      adBlockLists.default.forEach((list) => {
        assert(!list.langs)
      })
    })
    it('has url property', function () {
      adBlockLists.default.forEach((list) => {
        assert(!!list.listURL)
      })
    })
    it('has title property', function () {
      adBlockLists.default.forEach((list) => {
        assert(!!list.title)
      })
    })
    it('has supportURL property', function () {
      adBlockLists.default.forEach((list) => {
        assert(!!list.supportURL)
      })
    })
  })
  describe('malware', function () {
    it('contains 2 malware lists', function () {
      assert.equal(adBlockLists.malware.length, 2)
    })
    it('does not have langs property', function () {
      adBlockLists.malware.forEach((list) => {
        assert(!list.langs)
      })
    })
    it('has uuid property', function () {
      adBlockLists.malware.forEach((list) => {
        assert(!!list.uuid)
      })
    })
    it('has url property', function () {
      adBlockLists.malware.forEach((list) => {
        assert(!!list.listURL)
      })
    })
    it('has title property', function () {
      adBlockLists.malware.forEach((list) => {
        assert(!!list.title)
      })
    })
    it('has supportURL property', function () {
      adBlockLists.malware.forEach((list) => {
        assert(!!list.supportURL)
      })
    })
  })
  describe('regions', function () {
    it('contains multiple region lists', function () {
      assert(adBlockLists.regions.length > 0)
    })
    it('has uuid property', function () {
      adBlockLists.malware.forEach((list) => {
        assert(!!list.uuid)
      })
    })
    it('has langs array property', function () {
      assert(adBlockLists.regions.some((list) => !!list.langs))
    })
    it('has url property', function () {
      adBlockLists.regions.forEach((list) => {
        assert(!!list.listURL)
      })
    })
    it('has title property', function () {
      adBlockLists.regions.forEach((list) => {
        assert(!!list.title)
      })
    })
    it('has supportURL property', function () {
      adBlockLists.regions.forEach((list) => {
        assert(!!list.supportURL)
      })
    })
  })
})
