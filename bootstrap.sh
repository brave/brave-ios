#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#
# Bootstrap the Carthage dependencies. If the Carthage directory
# already exists then nothing is done. This speeds up builds on
# CI services where the Carthage directory can be cached.
#
# Use the --force option to force a rebuild of the dependencies.
#

if [ "$1" == "--force" ]; then
    rm -rf Carthage/*
    rm -rf ~/Library/Caches/org.carthage.CarthageKit
fi

# Only enable this on the Xcode Server because it times out if it does not
# get any output for some time while building the dependencies.

CARTHAGE_VERBOSE=""
if [ ! -z "$XCS_BOT_ID"  ]; then
  CARTHAGE_VERBOSE="--verbose"
fi

carthage bootstrap $CARTHAGE_VERBOSE --platform ios --color auto --cache-builds 

git update-index --assume-unchanged Client/Configuration/Local.xcconfig