// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

(function() {
  // Secure replacement for Math.random()
  // Float = Mantissa * (2^Exponent)
  function secure_random_float() {
    // Float64 = 8 Bytes in JS.
    let buffer = new ArrayBuffer(8);
    let intView = new Int8Array(buffer);
    crypto.getRandomValues(intView);
    intView[7] = 63; // Sign Bit = 0.
    intView[6] |= 0xF0; //Set exponent to all 1's except the highest bit.
    
    // View buffer as Float64, and minus 1 for the range [0, 1).
    // [0 Inclusive, 1 Exclusive).
    return new DataView(buffer).getFloat64(0, true) - 1;
  }
  
  (function() {
    const magic = String.fromCharCode(Date.now() % 26 + 97) +
    Math.floor(secure_random_float() * 982451653 + 982451653).toString(36);
    let prop = 'navigator.brave';
    let owner = window;
    for (;;) {
      const pos = prop.indexOf('.');
      if ( pos === -1 ) { break; }
      owner = owner[prop.slice(0, pos)];
      if ( owner instanceof Object === false ) { return; }
      prop = prop.slice(pos + 1);
    }
    delete owner[prop];
    Object.defineProperty(owner, prop, {
    configurable: true,
      set: function() {
        throw new ReferenceError(magic);
      }
    });
    const oe = window.onerror;
    window.onerror = function(msg, src, line, col, error) {
      if ( typeof msg === 'string' && msg.indexOf(magic) !== -1 ) {
        return true;
      }
      if ( oe instanceof Function ) {
        return oe(msg, src, line, col, error);
      }
    }.bind();
  })();
  
  (function() {
    const target = 'navigator.brave';
    if ( target === '' || target === '{{1}}' ) { return; }
    const needle = '{{2}}';
    let reText = '.?';
    if ( needle !== '' && needle !== '{{2}}' ) {
      reText = /^\/.+\/$/.test(needle)
      ? needle.slice(1,-1)
      : needle.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }
    const thisScript = document.currentScript;
    const re = new RegExp(reText);
    const chain = target.split('.');
    let owner = window;
    let prop;
    for (;;) {
      prop = chain.shift();
      if ( chain.length === 0 ) { break; }
      owner = owner[prop];
      if ( owner instanceof Object === false ) { return; }
    }
    let value;
    let desc = Object.getOwnPropertyDescriptor(owner, prop);
    if (
        desc instanceof Object === false ||
        desc.get instanceof Function === false
        ) {
          value = owner[prop];
          desc = undefined;
        }
    document.cookie = 'unsupported-browser=; expires=Thu, 01 Jan 1970 00:00:01 GMT';
    const magic = String.fromCharCode(Date.now() % 26 + 97) +
    Math.floor(secure_random_float() * 982451653 + 982451653).toString(36);
    const validate = function() {
      const e = document.currentScript;
      if (
          e instanceof HTMLScriptElement &&
          e.src === '' &&
          e !== thisScript &&
          re.test(e.textContent)
          ) {
            throw new ReferenceError(magic);
          }
    };
    Object.defineProperty(owner, prop, {
      get: function() {
        validate();
        return desc instanceof Object
        ? desc.get()
        : value;
      },
      set: function(a) {
        validate();
        if ( desc instanceof Object ) {
          desc.set(a);
        } else {
          value = a;
        }
      }
    });
    const oe = window.onerror;
    window.onerror = function(msg) {
      if ( typeof msg === 'string' && msg.indexOf(magic) !== -1 ) {
        return true;
      }
      if ( oe instanceof Function ) {
        return oe.apply(this, arguments);
      }
    }.bind();
  })();
  
  (function() {
    const target = 'Object.getPrototypeOf';
    if ( target === '' || target === '{{1}}' ) { return; }
    const needle = 'join';
    let reText = '.?';
    if ( needle !== '' && needle !== '{{2}}' ) {
      reText = /^\/.+\/$/.test(needle)
      ? needle.slice(1,-1)
      : needle.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }
    const thisScript = document.currentScript;
    const re = new RegExp(reText);
    const chain = target.split('.');
    let owner = window;
    let prop;
    for (;;) {
      prop = chain.shift();
      if ( chain.length === 0 ) { break; }
      owner = owner[prop];
      if ( owner instanceof Object === false ) { return; }
    }
    let value;
    let desc = Object.getOwnPropertyDescriptor(owner, prop);
    if (
        desc instanceof Object === false ||
        desc.get instanceof Function === false
        ) {
          value = owner[prop];
          desc = undefined;
        }
    const magic = String.fromCharCode(Date.now() % 26 + 97) +
    Math.floor(secure_random_float() * 982451653 + 982451653).toString(36);
    const validate = function() {
      const e = document.currentScript;
      if (
          e instanceof HTMLScriptElement &&
          e.src === '' &&
          e !== thisScript &&
          re.test(e.textContent)
          ) {
            throw new ReferenceError(magic);
          }
    };
    Object.defineProperty(owner, prop, {
      get: function() {
        validate();
        return desc instanceof Object
        ? desc.get()
        : value;
      },
      set: function(a) {
        validate();
        if ( desc instanceof Object ) {
          desc.set(a);
        } else {
          value = a;
        }
      }
    });
    const oe = window.onerror;
    window.onerror = function(msg) {
      if ( typeof msg === 'string' && msg.indexOf(magic) !== -1 ) {
        return true;
      }
      if ( oe instanceof Function ) {
        return oe.apply(this, arguments);
      }
    }.bind();
  })();
  
  (function() {
    const target = 'document.cookie';
    if ( target === '' || target === '{{1}}' ) { return; }
    const needle = '{{2}}';
    let reText = '.?';
    if ( needle !== '' && needle !== '{{2}}' ) {
      reText = /^\/.+\/$/.test(needle)
      ? needle.slice(1,-1)
      : needle.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }
    const thisScript = document.currentScript;
    const re = new RegExp(reText);
    const chain = target.split('.');
    let owner = window;
    let prop;
    for (;;) {
      prop = chain.shift();
      if ( chain.length === 0 ) { break; }
      owner = owner[prop];
      if ( owner instanceof Object === false ) { return; }
    }
    let value;
    let desc = Object.getOwnPropertyDescriptor(owner, prop);
    if (
        desc instanceof Object === false ||
        desc.get instanceof Function === false
        ) {
          value = owner[prop];
          desc = undefined;
        }
    const magic = String.fromCharCode(Date.now() % 26 + 97) +
    Math.floor(secure_random_float() * 982451653 + 982451653).toString(36);
    const validate = function() {
      const e = document.currentScript;
      if (
          e instanceof HTMLScriptElement &&
          e.src === '' &&
          e !== thisScript &&
          re.test(e.textContent)
          ) {
            throw new ReferenceError(magic);
          }
    };
    Object.defineProperty(owner, prop, {
      get: function() {
        validate();
        return desc instanceof Object
        ? desc.get()
        : value;
      },
      set: function(a) {
        validate();
        if ( desc instanceof Object ) {
          desc.set(a);
        } else {
          value = a;
        }
      }
    });
    const oe = window.onerror;
    window.onerror = function(msg) {
      if ( typeof msg === 'string' && msg.indexOf(magic) !== -1 ) {
        return true;
      }
      if ( oe instanceof Function ) {
        return oe.apply(this, arguments);
      }
    }.bind();
  })();
})();
