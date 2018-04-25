/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */
/* global describe, before, it */

const assert = require('assert')
const {AdBlockClient} = require('../..')
const {FilterOptions} = require('../..')

describe('matching', function () {
  describe('strange rules', function () {
    it('can start with a slash', function () {
      const client = new AdBlockClient()
      client.parse('/banner1.gif\n')
      assert(client.matches('http://www.brianbondy.com/public/banner1.gif', FilterOptions.image, 'slashdot.org'))
      assert(client.matches('http://www.brianbondy.com/public//banner1.gif', FilterOptions.image, 'slashdot.org'))
      assert(!client.matches('http://www.brianbondy.com/public/abanner1.gif', FilterOptions.image, 'slashdot.org'))
    })

    it('can start with a star', function () {
      const client = new AdBlockClient()
      client.parse('*/b/ss/*&aqe=$image,redirect=1x1-transparent.gif\n')
      assert(!client.matches('https://i.ytimg.com/vi/hxUAntt1z2c/hqdefault.jpg?custom=true&w=320&h=180&stc=true&jpg444=true&jpgq=90&sp=68&sigh=YNApXAOpSSoeEmCpXSLQwjnOdwY', FilterOptions.image, 'slashdot.org'))
      assert(client.matches('https://i.ytimg.com/b/ss/hxUAntt1z2c/hqdefault.jpg?a&aqe=$image,redirect=1x1-transparent.gif&dd', FilterOptions.image, 'slashdot.org'))
      assert(client.matches('https://i.ytimg.com/a/b/ss/hxUAntt1z2c/hqdefault.jpg?a&aqe=$image,redirect=1x1-transparent.gif&dd', FilterOptions.image, 'slashdot.org'))
      assert(!client.matches('https://i.ytimg.com/b/a/ss/hxUAntt1z2c/hqdefault.jpg?a&aqe=$image,redirect=1x1-transparent.gif&dd', FilterOptions.image, 'slashdot.org'))
    })
    it('can start with multiple stars', function () {
      const client = new AdBlockClient()
      client.parse('***/b/ss/*&aqe=$image,redirect=1x1-transparent.gif\n')
      assert(!client.matches('https://i.ytimg.com/vi/hxUAntt1z2c/hqdefault.jpg?custom=true&w=320&h=180&stc=true&jpg444=true&jpgq=90&sp=68&sigh=YNApXAOpSSoeEmCpXSLQwjnOdwY', FilterOptions.image, 'slashdot.org'))
      assert(client.matches('https://i.ytimg.com/b/ss/hxUAntt1z2c/hqdefault.jpg?a&aqe=$image,redirect=1x1-transparent.gif&dd', FilterOptions.image, 'slashdot.org'))
      assert(client.matches('https://i.ytimg.com/a/b/ss/hxUAntt1z2c/hqdefault.jpg?a&aqe=$image,redirect=1x1-transparent.gif&dd', FilterOptions.image, 'slashdot.org'))
      assert(!client.matches('https://i.ytimg.com/b/a/ss/hxUAntt1z2c/hqdefault.jpg?a&aqe=$image,redirect=1x1-transparent.gif&dd', FilterOptions.image, 'slashdot.org'))
    })
    it('can have multiple stars in the middle', function () {
      const client = new AdBlockClient()
      client.parse('a/********b\n')
      assert(client.matches('https://i.ytimg.com/a/d/e/f/b', FilterOptions.noFilterOption, 'slashdot.org'))
      assert(client.matches('https://i.ytimg.com/a/d/e/fb', FilterOptions.noFilterOption, 'slashdot.org'))
      assert(!client.matches('https://i.ytimg.com/a/d/e/fd', FilterOptions.noFilterOption, 'slashdot.org'))
    })
    it('can block everything with a single *', function () {
      const client = new AdBlockClient()
      client.parse('*')
      assert(client.matches('https://brianbondy.com/d', FilterOptions.noFilterOption, 'slashdot.org'))
      assert(client.matches('https://brianbondy.com', FilterOptions.noFilterOption, 'slashdot.org'))
    })
    it('can have no rule data', function () {
      const client = new AdBlockClient()
      client.parse('')
      assert(!client.matches('https://brianbondy.com/d', FilterOptions.noFilterOption, 'slashdot.org'))
      assert(!client.matches('https://brianbondy.com', FilterOptions.noFilterOption, 'slashdot.org'))
    })
    it('can have rule data with just a ^', function () {
      const client = new AdBlockClient()
      client.parse('^')
      assert(!client.matches('https://brianbondy.com', FilterOptions.noFilterOption, 'slashdot.org'))
      assert(!client.matches('https://brianbondy.com', FilterOptions.noFilterOption, 'slashdot.org'))
    })
    describe('host anchored exception with matching first party exception', function () {
      before(function () {
        this.client = new AdBlockClient()
        this.client.parse('-google-analytics.\n@@||www.scrumpoker.online^$~third-party')
      })
      it('does not match', function () {
        assert(!this.client.matches('https://www.scrumpoker.online/js/angular-google-analytics.js', FilterOptions.script, 'www.scrumpoker.online'))
      })
      it('detects as a hash set save', function () {
        assert.equal(this.client.getMatchingStats().numExceptionHashSetSaves, 1)
      })
    })
    describe('host anchored exception with not matching first party exception', function () {
      before(function () {
        this.client = new AdBlockClient()
        this.client.parse('-google-analytics.\n@@||www.scrumpoker.online^$~third-party')
      })
      it('does match', function () {
        assert(this.client.matches('https://www.scrumpoker.online/js/angular-google-analytics.js', FilterOptions.script, 'www.brianbondy.com'))
      })
      it('detects as a hash set save', function () {
        assert.equal(this.client.getMatchingStats().numExceptionHashSetSaves, 1)
      })
    })
  })
})
