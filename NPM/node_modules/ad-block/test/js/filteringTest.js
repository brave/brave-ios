/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */
/* global describe, it */

const assert = require('assert')
const {sanitizeABPInput} = require('../../lib/filtering')
const filteredOutRule = '*/test'
const predicate = (rule) => !rule.startsWith('*')

describe('filtering', function () {
  describe('filterPredicate', function () {
    it('Filters out rules that start with a *, for now', function () {
      assert(!predicate('*test/ad'))
    })
    it('Does not filter out rules with a *', function () {
      assert(predicate('test/*/ad'))
    })
  })
  describe('sanitizeABPInput', function () {
    it('Rebuilds lists which do not have filtered out rules', function () {
      const I = '&ad_channel=\n&ad_classid=\n&ad_height=\n&ad_keyword='
      assert(sanitizeABPInput(I, predicate) === I)
    })
    it('Rebuilds lists which have filtered out rules at the start', function () {
      const rules = '&ad_channel=\n&ad_classid=\n&ad_height=\n&ad_keyword='
      assert(sanitizeABPInput(`${filteredOutRule}\n${rules}`, predicate) === rules)
    })
    it('Rebuilds lists which have filtered out rules at the end', function () {
      const rules = '&ad_channel=\n&ad_classid=\n&ad_height=\n&ad_keyword='
      assert(sanitizeABPInput(`${rules}\n${filteredOutRule}`, predicate) === rules)
    })
    it('Rebuilds lists which have filtered out rules in the middle', function () {
      const rules = '&ad_channel=\n&ad_classid=\n&ad_height=\n&ad_keyword='
      assert(sanitizeABPInput(`&ad_channel=\n${filteredOutRule}\n&ad_classid=\n&ad_height=\n&ad_keyword=`, predicate) === rules)
    })
    it('Rebuilds lists which have multiple filtered out rules', function () {
      const rules = '&ad_channel=\n&ad_classid=\n&ad_height=\n&ad_keyword='
      assert(sanitizeABPInput(`${filteredOutRule}\n&ad_channel=\n${filteredOutRule}\n&ad_classid=\n&ad_height=\n&ad_keyword=`, predicate) === rules)
    })
  })
})
