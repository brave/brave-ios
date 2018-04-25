/* Copyright (c) 2016 Sergiy Zhukovs'kyy. Distributed under the MPL2 license.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var CTPParser = require('../build/Release/tp_node_addon').CTPParser;
var fs = require('fs');


// Functions to call to work with the addon
var addon = new CTPParser();
//addon.addTracker('facebook.com');
//console.log(addon.matchesTracker('facebook1.com', 'facebook.com'));
//console.log(addon.matchesTracker('facebook.com', 'facebook.com'));
//console.log(addon.matchesTracker('www.facebook.com', 'facebook.com'));
//console.log(addon.matchesTracker('www.facebook.com', 'www.facebook.com'));
//console.log(addon.matchesTracker('facebook.com', 'www.facebook.com'));
//console.log(addon.matchesTracker('facebook.com', 'facebook1.com'));
//addon.addFirstPartyHosts('facebook.com', 'facebook.fr,facebook.de');
//var thirdPartyHosts = addon.findFirstPartyHosts('facebook.com');
//console.log(thirdPartyHosts);
//thirdPartyHosts = addon.findFirstPartyHosts('facebook1.com');
//console.log(thirdPartyHosts);
//var serializedObject = addon.serialize();
const serializedObject = fs.readFileSync('../data/TrackingProtection.dat');
//console.log('serializedObject == ' + serializedObject);
console.log('size == ' + serializedObject.length);

console.log('deserialize == ' + addon.deserialize(serializedObject));
console.log(addon.matchesTracker('cnet.com', 'tags.tiqcdn.com'));
console.log(addon.matchesTracker('cnet.com', 'tags.tiqcdn.com'));

//console.log(addon.matchesTracker('facebook1.com', 'facebook.com'));
//console.log(addon.matchesTracker('facebook.com', 'facebook.com'));
//console.log(addon.matchesTracker('facebook.com', 'facebook1.com'));


//var buffer = fs.readFileSync('./data/TrackingProtection.dat');

//addon.deserialize(buffer);

// Call that to cleanup memory
addon.cleanup();
