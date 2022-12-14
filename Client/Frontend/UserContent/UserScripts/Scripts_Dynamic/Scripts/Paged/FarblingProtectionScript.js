// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

"use strict";

//window.__firefox__.execute("FarblingProtection", function($) {
  (function() {
    const args = $<farbling_protection_args>;
    const braveNacl = window.nacl
    delete window.nacl
    
    // 1. Farble audio
    // Adds slight randization when reading data for audio files
    // Randomization is determined by the fudge factor
    const farbleAudio = (fudgeFactor) => {
      const farbleArrayData = (destination) => {
        // Let's fudge the data by our fudge factor.
        for (const index in destination) {
          destination[index] = destination[index] * fudgeFactor
        }
      }

      // Convert an unsinged byte (Uint8) to a hex character
      // Unsigned bytes must be between 0 and 255
      const byteToHex = (unsignedByte) => {
        // convert the possibly signed byte (-128 to 127) to an unsigned byte (0 to 255).
        // if you know, that you only deal with unsigned bytes (Uint8Array), you can omit this line
        // const unsignedByte = byte & 0xff

        // If the number can be represented with only 4 bits (0-15),
        // the hexadecimal representation of this number is only one char (0-9, a-f).
        if (unsignedByte < 16) {
          return '0' + unsignedByte.toString(16)
        } else {
          return unsignedByte.toString(16)
        }
      }

      // Convert an array of unsigned bytes (Uint8Array) to a hex string.
      // Each value in the array must be between 0 and 255,
      // resulting in hex values between 0 to f (i.e. 0 to 15)
      const toHexString = (unsignedBytes) => {
        return Array.from(unsignedBytes)
          .map(byte => byteToHex(byte))
          .join('')
      }

      // Hash an array
      const hashArray = (a) => {
        const byteArray = new Uint8Array(a.buffer)
        const hexArray = braveNacl.hash(byteArray)
        return toHexString(hexArray)
      }

      // 1. Farble `getChannelData`
      // This will also result in a farbled `copyFromChannel`
      const getChannelData = window.AudioBuffer.prototype.getChannelData
      window.AudioBuffer.prototype.getChannelData = function () {
        const channelData = Reflect.apply(getChannelData, this, arguments)
        // TODO: @JS Add more optimized audio farbling.
        // Will be done as a future PR of #5482 here:
        // https://github.com/brave/brave-ios/pull/5485
        return channelData
      }

      // 2. Farble "destination" methods
      const structuresToFarble = [
        [window.AnalyserNode, 'getFloatFrequencyData'],
        [window.AnalyserNode, 'getByteFrequencyData'],
        [window.AnalyserNode, 'getByteTimeDomainData'],
        [window.AnalyserNode, 'getFloatTimeDomainData']
      ]

      for (const [structure, methodName] of structuresToFarble) {
        const origImplementation = structure.prototype[methodName]
        structure.prototype[methodName] = function () {
          Reflect.apply(origImplementation, this, arguments)
          farbleArrayData(arguments[0])
        }
      }
    }

    // 2. Farble plugin data
    // Injects fake plugins with fake mime-types
    // Random plugins are determined by the plugin data
    const farblePlugins = (pluginData) => {
      // Function that create a fake mime-type based on the given fake data
      const makeFakeMimeType = (fakeData) => {
        return Object.create(window.MimeType.prototype, {
          suffixes: { value: fakeData.suffixes },
          type: { value: fakeData.type },
          description: { value: fakeData.description }
        })
      }

      // Create a fake plugin given the plugin data
      const makeFakePlugin = (pluginData) => {
        const newPlugin = Object.create(window.Plugin.prototype, {
          description: { value: pluginData.description },
          name: { value: pluginData.name },
          filename: { value: pluginData.filename },
          length: { value: pluginData.mimeTypes.length }
        })

        // Create mime-types and link them to the new plugin
        for (const [index, mimeType] of pluginData.mimeTypes.entries()) {
          const newMimeType = makeFakeMimeType(mimeType)

          newPlugin[index] = newMimeType
          newPlugin[newMimeType.type] = newMimeType

          Reflect.defineProperty(newMimeType, 'enabledPlugin', {
            value: newPlugin
          })
        }

        // Patch `Plugin.item(index)` function to return the correct item otherwise it
        // throws a `TypeError: Can only call Plugin.item on instances of Plugin`
        newPlugin.item = function (index) {
          return newPlugin[index]
        }
        
        return newPlugin
      }

      if (window.navigator.plugins !== undefined) {
        // We need the original length so we can reference it (as we will change it)
        const plugins = window.navigator.plugins
        const originalPluginsLength = plugins.length

        // Adds a fake plugin for the given index on fakePluginData
        const addPluginAtIndex = (newPlugin, index) => {
          const pluginPosition = originalPluginsLength + index
          window.navigator.plugins[pluginPosition] = newPlugin
          window.navigator.plugins[newPlugin.name] = newPlugin
        }

        for (const [index, pluginData] of fakePluginData.entries()) {
          const newPlugin = makeFakePlugin(pluginData)
          addPluginAtIndex(newPlugin, index)
        }

        // Adjust the length of the original plugin array
        Reflect.defineProperty(window.navigator.plugins, 'length', {
          value: originalPluginsLength + fakePluginData.length
        })

        // Patch `PluginArray.item(index)` function to return the correct item
        // otherwise it returns `undefined`
        const originalItemFunction = plugins.item
        window.PluginArray.prototype.item = function (index) {
          if (index < originalPluginsLength) {
            return Reflect.apply(originalItemFunction, plugins, arguments)
          } else {
            return plugins[index]
          }
        }
      }
    }

    // 3. Farble speech synthesizer
    // Adds a vake voice determined by the fakeVoiceName and randomVoiceIndexScale.
    const farbleVoices = (fakeVoiceName, randomVoiceIndexScale) => {
      const makeFakeVoiceFromVoice = (voice) => {
        const newVoice = Object.create(Object.getPrototypeOf(voice), {
          name: { value: fakeVoiceName },
          voiceURI: { value: voice.voiceURI },
          lang: { value: voice.lang },
          localService: { value: voice.localService },
          default: { value: false }
        })

        return newVoice
      }

      let originalVoice
      let fakeVoice
      let passedFakeVoice

      // We need to override the voice property to allow our fake voice to work
      const descriptor = Reflect.getOwnPropertyDescriptor(SpeechSynthesisUtterance.prototype, 'voice')
      Reflect.defineProperty(SpeechSynthesisUtterance.prototype, 'voice', {
        get () {
          if (!passedFakeVoice) {
            // We didn't set a fake voice
            return Reflect.apply(descriptor.get, this, arguments)
          } else {
            // We set a fake voice, return that instead
            return passedFakeVoice
          }
        },
        set (passedVoice) {
          if (passedVoice === fakeVoice && originalVoice !== undefined) {
            // If we passed a fake voice, ignore it. We need to use the real voice
            // The fake voice will not work.
            passedFakeVoice = passedVoice
            Reflect.apply(descriptor.set, this, [originalVoice])
          } else {
            // Otherwise, if we set a real voice, use a real voice instead.
            passedFakeVoice = undefined
            Reflect.apply(descriptor.set, this, arguments)
          }
        }
      })

      // Patch get voices to return an extra fake voice
      const getVoices = window.speechSynthesis.getVoices
      const getVoicesPrototype = Object.getPrototypeOf(window.speechSynthesis)
      getVoicesPrototype.getVoices = function () {
        const voices = Reflect.apply(getVoices, this, arguments)

        if (fakeVoice === undefined) {
          const randomVoiceIndex = Math.round(randomVoiceIndexScale * voices.length)
          originalVoice = voices[randomVoiceIndex]
          fakeVoice = makeFakeVoiceFromVoice(originalVoice)

          if (fakeVoice !== undefined) {
            voices.push(fakeVoice)
          }
        } else {
          voices.push(fakeVoice)
        }
        return voices
      }
    }

    // 4. Farble hardwareConcurrency
    // Adds a random value between 2 and the original hardware concurrency
    // using the provided `randomHardwareIndexScale` which must be a random value between 0 and 1.
    const farbleHardwareConcurrency = (randomHardwareIndexScale) => {
      const hardwareConcurrency = window.navigator.hardwareConcurrency
      // We only farble amounts greater than 2
      if (hardwareConcurrency <= 2) { return }
      const remaining = hardwareConcurrency - 2
      const newRemaining = Math.round(remaining * randomHardwareIndexScale)

      Reflect.defineProperty(window.navigator, 'hardwareConcurrency', {
        value: newRemaining + 2
      })
    }
    
    // 5. Farble screen APIs such as `window.screenX`, `window.screen.width` and `window.screen.availHeight`
    // R = random number between 0 and 8, seeded by session + domain
    const farbleScreenAPIs = (Rx, Ry) => {
      // NOTE: On iOS we use window.outer{Width,Height} instead of top.inner{Width,Height}
      // as top is not available on cross site frames.
      const originalOuterWidth = Object.getOwnPropertyDescriptor(window, 'outerWidth').get
      const originalOuterHeight = Object.getOwnPropertyDescriptor(window, 'outerHeight').get
      const deltaX = () => { Reflect.apply(originalOuterWidth, window, []) + Rx }
      const deltaY = () => { Reflect.apply(originalOuterHeight, window, []) + Ry }
      
      
      const originalScreenWidth = window.screen.width
      const originalScreenHeight = window.screen.height
      const originalScreenAvailWidth = window.screen.availWidth
      const originalScreenAvailHeight = window.screen.availHeight
      
      const printScreenSizes = () => {
        console.log(`window.outerWidth: ${Reflect.apply(originalOuterWidth, window, [])} -> ${window.outerWidth}`)
        console.log(`window.outerHeight: ${Reflect.apply(originalOuterHeight, window, [])} -> ${window.outerHeight}`)
        console.log(`window.screen.width: ${originalScreenWidth} -> ${window.screen.width}`)
        console.log(`window.screen.height: ${originalScreenHeight} -> ${window.screen.height}`)
        console.log(`window.screen.availWidth: ${originalScreenAvailWidth} -> ${window.screen.availWidth}`)
        console.log(`window.screen.availHeight: ${originalScreenAvailHeight} -> ${window.screen.availHeight}`)
      }
      
      // 1. window.outer{Width,Height}, window.screen{X,Y},
      // window.screen.{width,height,avail{Width,Height,Left,Top}}
      // - window.screen{X,Y} -> R (no need to farble on iOS since this is always 0)
      // - window.outer{Width,Height} -> top.inner{Width, Height} + R
      // - window.screen.{width, height} -> top.inner{Width, Height} + R
      // - window.screen.avail{Width, Height} -> top.inner{Width, Height} + R
      // - window.screen.avail{Top, Left} -> R (no need to farble on iOS since this is always 0)
      // - window.screen.isExtended -> false (not supported safari)
      try {
        Object.defineProperty(window, 'outerWidth', { get () { return Reflect.apply(originalOuterWidth, window, []) + Rx }})
        Object.defineProperty(window, 'outerHeight', { get () { return Reflect.apply(originalOuterHeight, window, []) + Ry }})

        // On iOS the screen width and height does not change depending on rotation.
        // We assume apple will not create a "fat" device where the screen is wider than taller
        // So we take the min/max values here
        Object.defineProperty(window.screen, 'width', { get () { return Math.min(window.outerWidth, window.outerHeight) }})
        Object.defineProperty(window.screen, 'height', { get () { return Math.max(window.outerWidth, window.outerHeight) }})
        Object.defineProperty(window.screen, 'availWidth', { get () { return window.screen.width }})
        Object.defineProperty(window.screen, 'availHeight', { get () { return window.screen.height }})
      } catch(e) {
        console.log(`Error: ${e}`)
      }
      
      // 2. {mouse,drag,pointer,touch}Event.screen{X,Y}
      // Rewrite Event screen coordinates such that
      // - event.screen{X,Y} -> devicePixelRatio * event.client{X,Y} + R
      // Since we don't farble screenX/Y (as it's always 0, 0) we don't need to "farble" this value
      // If we ever do change this, this is what we want to do:
      //Object.defineProperty(window.MouseEvent.prototype, 'screenX', { get () {
      //  return (window.devicePixelRatio * this.clientX) + Rx
      //}})

      //Object.defineProperty(window.MouseEvent.prototype, 'screenY', { get () {
      //  return (window.devicePixelRatio * this.clientY) + Ry
      //}})
      

      // 3. device-{width,height} in media queries
      // When farbling is enabled, media query for device-width
      // matches the same value as window.screen.width (also farbled).
      // Same for device-height.
      // - media query for device-width -> top.screen.width (also farbled)
      // - media query for device-height -> top.screen.height (also farbled)
      // TODO: @JS
      const originalMatchMedia = window.matchMedia
      window.matchMedia = (query) => {
        console.log(query)
        return originalMatchMedia(query)
      }
      

      // 4: make window.open play nice with spoofed screen coords
      // When a web page opens a child window, the position of the child window
      // should be relative to the spoofed screen coordinates, not relative
      // to the real screen coordinates.
      // - window.open coordinates -> relative to top.screen coordinates, regardless of whether opened from top-level document or an iframe
      // TODO: @JS
      
      console.log(`Farbled: ${window.location.href}`)
      printScreenSizes()
    }

    // A value between 0.99 and 1 to fudge the audio data
    // A value between 0.99 to 1 means the values in the destination will
    // always be within the expected range of -1 and 1.
    // This small decrease should not affect affect legitimite users of this api.
    // But will affect fingerprinters by introducing a small random change.
    const fudgeFactor = args['fudgeFactor']
    farbleAudio(fudgeFactor)

    // Fake data that is to be used to construct fake plugins
    const fakePluginData = args['fakePluginData']
    farblePlugins(fakePluginData)

    // A value representing a fake voice name that will be used to add a fake voice
    const fakeVoiceName = args['fakeVoiceName']
    // This value is used to get a random index between 0 and voices.length
    // It's important to have a value between 0 - 1 in order to be within the
    // array bounds
    const randomVoiceIndexScale = args['randomVoiceIndexScale']
    farbleVoices(fakeVoiceName, randomVoiceIndexScale)

    // This value lets us pick a value between 2 and window.navigator.hardwareConcurrency
    // It is a value between 0 and 1. For example 0.5 will give us 3 and
    // thus return 2 + 3 = 5 for hardware concurrency
    const randomHardwareIndexScale = args['randomHardwareIndexScale']
    farbleHardwareConcurrency(randomHardwareIndexScale)
    
    // This farbles certain screen size and position outputs
    const screenPositionRandomNumberX = args['screenPositionRandomNumberX']
    const screenPositionRandomNumberY = args['screenPositionRandomNumberY']
    farbleScreenAPIs(screenPositionRandomNumberX, screenPositionRandomNumberY)
  })();
//});
