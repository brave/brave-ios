/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */
/* global describe, it, before */

const assert = require('assert')
const fs = require('fs')
const {makeAdBlockClientFromString} = require('../../lib/util')
const {FilterOptions} = require('../..')

describe('parsing', function () {
  describe('newlines', function () {
    before(function () {
      const data = fs.readFileSync('./test/data/easylist.txt', 'utf8')
      this.rawData = data.replace(/\r/g, '').split('\n').slice(0, 100).join('\n')
      this.matchArgs = ['http://www.brianbondy.com/public/ad/adbanner.gif&ad_box_=1&ad_type=3', FilterOptions.image, 'slashdot.org']
    })

    it('\\r newline is handled the same as \\n', function (cb) {
      Promise.all([
        makeAdBlockClientFromString(this.rawData.replace(/\n/g, '\r')),
        makeAdBlockClientFromString(this.rawData)
      ]).then(([client1, client2]) => {
        const buffer1 = client1.serialize()
        const buffer2 = client2.serialize()
        assert.equal(buffer1.length, buffer2.length)
        assert(buffer2.toString() === buffer1.toString().replace(/\n/g, '\r'))
        assert(client1.matches(...this.matchArgs))
        assert(client2.matches(...this.matchArgs))
        cb()
      }).catch((e) => {
        console.log(e)
        assert(false)
      })
    })

    it('\\r\\n newline is handled the same as \\n', function (cb) {
      Promise.all([
        makeAdBlockClientFromString(this.rawData.replace(/\n/g, '\r\n')),
        makeAdBlockClientFromString(this.rawData)
      ]).then(([client1, client2]) => {
        const buffer1 = client1.serialize()
        const buffer2 = client2.serialize()
        assert.equal(buffer1.length, buffer2.length)
        assert(buffer2.toString() === buffer1.toString().replace(/\n/g, '\r'))
        assert(client1.matches(...this.matchArgs))
        assert(client2.matches(...this.matchArgs))
        cb()
      }).catch((e) => {
        console.log(e)
        assert(false)
      })
    })
  })
  describe('single chararacters', function () {
    it('with \'/\'', function (cb) {
      makeAdBlockClientFromString('/').then((client) => {
        assert(client.matches('http://www.brianbondy.com/a', FilterOptions.image, 'slashdot.org'))
        cb()
      })
    })

    it('with normal char \'a\'', function (cb) {
      makeAdBlockClientFromString('a').then((client) => {
        assert(client.matches('http://www.brianbondy.com/', FilterOptions.image, 'slashdot.org'))
        assert(!client.matches('http://www.zzz.com/', FilterOptions.image, 'slashdot.org'))
        cb()
      })
    })

    it('does not crash with unfinshed rules', function (cb) {
      Promise.all([
        makeAdBlockClientFromString('a'),
        makeAdBlockClientFromString('\r'),
        makeAdBlockClientFromString('\n'),
        makeAdBlockClientFromString('\t'),
        makeAdBlockClientFromString(' '),
        makeAdBlockClientFromString('|'),
        makeAdBlockClientFromString('@'),
        makeAdBlockClientFromString('!'),
        makeAdBlockClientFromString('['),
        makeAdBlockClientFromString('$'),
        makeAdBlockClientFromString('#'),
        makeAdBlockClientFromString('/'),
        makeAdBlockClientFromString('.'),
        makeAdBlockClientFromString('^')
      ]).then(() => {
        cb()
      })
    })
  })
})
