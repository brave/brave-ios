// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

'use strict'

window.braveFarble = (args) => {
  // 1. Farble audio
  // Adds slight randization when reading data for audio files
  // Randomization is determined by the fudge factor and the
  // indexes farbled are determined by farbleSeed
  const farbleAudio = (fudgeFactor, farbleSeed) => {
    const mapValues = (value, inMin, inMax, outMin, outMax) => {
      return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
    }
    
    const farbleChannelData = (destination) => {
      const seedIndex = farbleSeed % destination.length
      let farbleIndex = Math.round(mapValues(destination[seedIndex], -1, 1, 0, destination.length))
      let numIndexesFarbled = 0
      const numIndexesToFarble = 500
      
      while (numIndexesFarbled < numIndexesToFarble) {
        destination[farbleIndex] = destination[farbleIndex] * fudgeFactor
        farbleIndex = (farbleIndex + Math.round(destination.length / numIndexesToFarble)) % destination.length
        numIndexesFarbled += 1
      }
    }

    const farbleArrayData = (destination) => {
      // Let's fudge the data by our fudge factor.
      for (const index in destination) {
        destination[index] = destination[index] * fudgeFactor
      }
    }

    // 1. Farble `getChannelData`
    // This will also result in a farbled `copyFromChannel`
    const getChannelData = window.AudioBuffer.prototype.getChannelData
    window.AudioBuffer.prototype.getChannelData = function () {
      const channelData = Reflect.apply(getChannelData, this, arguments)
      // Farble the array and store the hash of this
      // so that we don't farble the same data again.
      farbleChannelData(channelData)
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
  const farblePlugins = (fakePluginsData) => {
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

      for (const [index, pluginData] of fakePluginsData.entries()) {
        const newPlugin = makeFakePlugin(pluginData)
        addPluginAtIndex(newPlugin, index)
      }

      // Adjust the length of the original plugin array
      Reflect.defineProperty(window.navigator.plugins, 'length', {
        value: originalPluginsLength + fakePluginsData.length
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

  // A value between 0.99 and 1 to fudge the audio data
  // A value between 0.99 to 1 means the values in the destination will 
  // always be within the expected range of -1 and 1.
  // This small decrease should not affect affect legitimite users of this api.
  // But will affect fingerprinters by introducing a small random change.
  const fudgeFactor = args.fudgeFactor
  const farbleSeed = args.farbleSeed
  farbleAudio(fudgeFactor, farbleSeed)

  // Fake data that is to be used to construct fake plugins
  const fakePluginsData = args.fakePluginsData
  farblePlugins(fakePluginsData)

  // A value representing a fake voice name that will be used to add a fake voice
  const fakeVoiceName = args.fakeVoiceName
  // This value is used to get a random index between 0 and voices.length
  // It's important to have a value between 0 - 1 in order to be within the 
  // array bounds
  const randomVoiceIndexScale = args.randomVoiceIndexScale
  farbleVoices(fakeVoiceName, randomVoiceIndexScale)

  // This value lets us pick a value between 2 and window.navigator.hardwareConcurrency
  // It is a value between 0 and 1. For example 0.5 will give us 3 and 
  // thus return 2 + 3 = 5 for hardware concurrency
  const randomHardwareIndexScale = args.randomHardwareIndexScale
  farbleHardwareConcurrency(randomHardwareIndexScale)
}

// Invoke window.braveFarble then delete the function
