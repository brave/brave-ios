// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// In this method we will decrease the weight of the destination value by our fudge factor.
// Our fudge factor is a random value between 0.99 and 1.
// This means the values in the destination will always be within the expected range of -1 and 1.
// This small decrease should not affect affect legitimite users of this api.
// But will affect fingerprinters by introducing a small random change.
(function () {
  const fudgeFactor = $<fudge_factor>
  const farbledChannels = new WeakMap()
  const braveNacl = window.nacl
  delete window.nacl

  function farbleArrayData (destination) {
    // Let's fudge the data by our fudge factor.
    for (const index in destination) {
      destination[index] = destination[index] * fudgeFactor
    }
  }

  // Convert an unsinged byte (Uint8) to a hex character
  // Unsigned bytes must be between 0 and 255
  function byteToHex (unsignedByte) {
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
  function toHexString (unsignedBytes) {
    return Array.from(unsignedBytes)
      .map(byte => byteToHex(byte))
      .join('')
  }

  // Hash an array
  function hashArray (a) {
    const byteArray = new Uint8Array(a.buffer)
    const hexArray = braveNacl.hash(byteArray)
    return toHexString(hexArray)
  }

  // 1. Farble `getChannelData`
  const getChannelData = window.AudioBuffer.prototype.getChannelData
  window.AudioBuffer.prototype.getChannelData = function () {
    const channelData = getChannelData.apply(this, arguments)
    let hashes = farbledChannels.get(channelData)

    // First let's check if we already farbled this set
    if (hashes !== undefined) {
      // We had this data set farbled already.
      // Lets see if it changed it's shape since then.
      const hash = hashArray(channelData)

      if (hashes.has(hash)) {
        // We already farbled this version of the channel data
        // Let's not farble it again
        return channelData
      }
    } else {
      // If we dont have any hashes of farbled data at all for this
      // channel, then we trivially haven't hashed this channel data yet.
      hashes = new Set()
      farbledChannels.set(channelData, hashes)
    }

    // Farble the array and store the hash of this
    // so that we don't farble the same data again.
    farbleArrayData(channelData)
    const hash = hashArray(channelData)
    hashes.add(hash)

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
})()
