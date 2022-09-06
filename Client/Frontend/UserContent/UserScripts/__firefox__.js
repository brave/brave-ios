// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

"use strict";

if (!window.__firefox__) {
  let $defineProperty = Object.defineProperty;
  let $freeze = Object.freeze;
  let $isExtensible = Object.isExtensible;
  let $entries = Object.entries;
  let $call = Function.prototype.call;
  let $apply = Function.prototype.apply;
  let $bind = Function.prototype.bind;
  let $toString = Function.prototype.toString;
  
  /*
   *  Secures an object's attributes
   */
  let $ = function(value) {
    if ($isExtensible(value)) {
      const description = (typeof value === 'function') ?
                          `function () {\n\t[native code]\n}` :
                          '[object Object]';
      
      const toString = function() {
        return description;
      };
      
      const overrides = {
        'toString': toString
      };
      
      if (typeof value === 'function') {
        const functionOverrides = {
          'call': $call,
          'apply': $apply,
          'bind': $bind
        };
        
        for (const [key, value] of $entries(functionOverrides)) {
          overrides[key] = value;
        }
      }
      
      for (const [name, property] of $entries(overrides)) {
        toString[name] = property;

        $defineProperty(toString, name, {
          enumerable: false,
          configurable: false,
          writable: false,
          value: property
        });
        
        if (name !== 'toString') {
          $.deepFreeze(toString[name]);
        }
      }

      $.deepFreeze(toString);

      for (const [name, property] of $entries(overrides)) {
        value[name] = property;

        $defineProperty(value, name, {
          enumerable: false,
          configurable: false,
          writable: false,
          value: property
        });

        $.deepFreeze(value[name]);
      }
    }
    return value;
  };
  
  $.deepFreeze = function(value) {
    $freeze(value);
    $freeze(value.prototype);
    return value;
  };
  
  $($.deepFreeze);
  $($);

  $.deepFreeze($.deepFreeze);
  $.deepFreeze($);
  
  /*
   *  Creates a Proxy object that does the following to all objects using it:
   *  - Symbols are not printable or accessible via `toString`
   *  - Symbols are not enumerable
   *  - Symbols are read-only
   *  - Symbols are not configurable
   *  - Symbols can be completely hidden via `hiddenProperties`
   *  - All child properties and objects follow the above rules as well
   */
  let createProxy = $(function(hiddenProperties) {
    let values = $({});
    return new Proxy({}, {
      get(target, property, receiver) {
        const descriptor = Reflect.getOwnPropertyDescriptor(target, property);
        if (descriptor && !descriptor.configurable && !descriptor.writable) {
          return Reflect.get(target, property, receiver);
        }
      
        if (hiddenProperties && hiddenProperties[property]) {
          return hiddenProperties[property];
        }
        
        return Reflect.get(values, property, receiver);
      },
      
      set(target, name, value, receiver) {
        if (hiddenProperties && hiddenProperties[name]) {
          return false;
        }
        
        const descriptor = getOwnPropertyDescriptor(target, property);
        if (descriptor && !descriptor.configurable && !descriptor.writable) {
          return false;
        }
      
        if (value) {
          value = $(value);
        }
        
        return Reflect.set(values, name, value, receiver);
      },
      
      defineProperty(target, property, descriptor) {
        if (descriptor && !descriptor.configurable) {
          if (descriptor.set && !descriptor.get) {
            return false;
          }
        
          if (descriptor.value) {
            descriptor.value = $(descriptor.value);
          }

          if (!descriptor.writable) {
            return Reflect.defineProperty(target, property, descriptor);
          }
        }
      
        if (descriptor.value) {
          descriptor.value = $(descriptor.value);
        }

        return Reflect.defineProperty(values, property, descriptor);
      },
      
      getOwnPropertyDescriptor(target, property) {
        const descriptor = Reflect.getOwnPropertyDescriptor(target, property);
        if (descriptor && !descriptor.configurable && !descriptor.writable) {
          return descriptor;
        }
        
        return Reflect.getOwnPropertyDescriptor(values, property);
      },
      
      ownKeys(target) {
        var keys = [];
        /*keys = keys.concat(Object.keys(target));
        keys = keys.concat(Object.getOwnPropertyNames(target));*/
        keys = keys.concat(Reflect.ownKeys(target));
        return keys;
      }
    });
  });
  
  /*
   *  Creates window.__firefox__ with a `Proxy` object as defined above
   */
  $defineProperty(window, "__firefox__", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: ($(function() {
      'use strict';
      
      let userScripts = $({});
      let includeOnce = $(function(name, fn) {
        if (!userScripts[name]) {
          userScripts[name] = true;
          if (typeof fn === 'function') {
            $(fn)($);
          }
          return true;
        }

        return false;
      });
    
      let execute = $(function(fn) {
        if (typeof fn === 'function') {
          $(fn)($);
          return true;
        }
        return false;
      });
    
      return createProxy({'includeOnce': $.deepFreeze(includeOnce), 'execute': $.deepFreeze(execute)});
    }))()
  });
  
  let postNativeMessage = $(function(message) {
    delete this.postMessage;
    this.postMessage(message);
  });
  
  $defineProperty(UserMessageHandler.prototype, 'postNativeMessage', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: $.deepFreeze(postNativeMessage)
  });
}
