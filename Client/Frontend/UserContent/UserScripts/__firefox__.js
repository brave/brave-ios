// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

"use strict";

if (!window.__firefox__) {
  let $isExtensible = Object.isExtensible;
  let $call = Function.prototype.call;
  let $apply = Function.prototype.apply;
  
  /*
   *  Secures an object's attributes
   */
  let $ = function(value) {
    if ($isExtensible(value)) {
      if (typeof value === 'function') {
        value.call = $call;
        value.apply = $apply;
        
        value.toString = function() {
          return "function() {\n\t[native code]\n}";
        }
        
        value.toString.call = $call;
        value.toString.apply = $apply;
      } else {
        value.toString = function() {
          return "[object Object]";
        }
        
        value.toString.call = $call;
        value.toString.apply = $apply;
      }
    }
    return value;
  }
  
  $.toString = function() {
    return "function() {\n\t[native code]\n}";
  }
  
  $.toString.call = $call;
  $.toString.apply = $apply;
  Object.freeze($);
  
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
        keys = keys.concat(Reflect.keys(target));
        keys = keys.concat(Reflect.getOwnPropertyNames(target));
        return keys;
      }
    });
  });
  
  /*
   *  Creates window.__firefox__ with a `Proxy` object as defined above
   */
  Object.defineProperty(window, "__firefox__", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: ($(function() {
      'use strict';
      
      let userScripts = $({});
      let values = $({});
      let includeOnce = $(function(name, fn) {
        if (!userScripts[name]) {
          userScripts[name] = true;
          if (typeof fn === 'function') {
            $(fn)($);
          }
          return false;
        }

        return true;
      });
    
      let execute = $(function(userScript, fn) {
        if (typeof fn === 'function') {
          $(fn)($);
          return true;
        }
        return false;
      });
    
      return createProxy({'includeOnce': includeOnce, 'execute': execute});
    }))()
  });
  
  let postNativeMessage = $(function(message) {
    delete this.postMessage;
    this.postMessage(message);
  });
  
  Object.defineProperty(UserMessageHandler.prototype, 'postNativeMessage', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: postNativeMessage
  });
}
