/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var CTPParser = require('../build/Release/tp_node_addon').CTPParser;
var fs = require('fs');

var data = fs.readFileSync('../data/disconnect.json');

var addon = new CTPParser();
var mapObjects = new Map();
var values = new Map();
var previousKey = undefined;
var previousValue = undefined;
var addToList = true;
JSON.parse(String(data), function(k, v) {
  // We shouldn't add all section after Advertising, which is Content
  if (k == 'Advertising') {
    addToList = false;
    //console.log(k);
  }
  else if (k == 'Content') {
    addToList = true;
    console.log(k);
  }
  //console.log(k);
  if (k.indexOf('http://') == 0 || k.indexOf('https://') == 0) {
    var existingValues = mapObjects.get(k);
    if (undefined == existingValues) {
      existingValues = values;
    }
    else {
      for (var key of values.keys()) {
        existingValues.set(key);
      }
    }
    if (undefined != existingValues && 0 != existingValues.size) {
      mapObjects.set(k, existingValues);
    }
    values = new Map();
    previousKey = undefined;
    previousValue = undefined;
  } else if (!isNaN(k)) {
    if (!addToList) {
      console.log(v);
      return;
    }
    if (undefined != previousKey && k <= previousKey) {
      values.delete(previousValue);
    }
    values.set(v);
    previousKey = k;
    previousValue = v;
  } else {
    values = new Map();
    previousKey = undefined;
    previousValue = undefined;
  }
});

for (var [key, value] of mapObjects) {
  var keyValues = undefined;
  for (var key1 of value.keys()) {
    if (undefined != keyValues) {
      keyValues += ',';
      keyValues += key1;
    } else {
      keyValues = key1;
    }
    addon.addTracker(key1);
  }
  addon.addFirstPartyHosts(key, keyValues);
  console.log(key + " = " + keyValues);
}

var serializedObject = addon.serialize();
console.log('serializedObject == ' + serializedObject);
console.log('size == ' + serializedObject.length);

fs.writeFileSync('../data/TrackingProtection.dat', serializedObject);
