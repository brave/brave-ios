/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */
/* global describe, it */

const {makeAdBlockClientFromListUUID} = require('../../lib/util')

const err = new Error()
describe('utilTest', function () {
  this.timeout(0)
  describe('makeAdBlockClientFromListUUID', function () {
    it('throws an error for an invalid uuid which does not exist', function (cb) {
      makeAdBlockClientFromListUUID().then(() => {
        cb(err)
      }).catch((e) => {
        cb()
      })
    })
    it('can obtain list from default lists by uuid', function (cb) {
      makeAdBlockClientFromListUUID('67F880F5-7602-4042-8A3D-01481FD7437A').then(() => {
        cb()
      }).catch((e) => {
        cb(err)
      })
    })
    it('can obtain list from regions list by uuid', function (cb) {
      makeAdBlockClientFromListUUID('9FCEECEC-52B4-4487-8E57-8781E82C91D0').then(() => {
        cb()
      }).catch((e) => {
        cb(err)
      })
    })
    it('can obtain list from malware list by uuid', function (cb) {
      makeAdBlockClientFromListUUID('AE08317A-778F-4B95-BC12-7E78C1FB26A3').then(() => {
        cb()
      }).catch((e) => {
        cb(err)
      })
    })
  })
})
