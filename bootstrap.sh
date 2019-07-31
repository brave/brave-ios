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
# Use the --ci option to use `npm ci` over `npm install`
#

set -e

missingCommand() {
    echo >&2 "Brave requires the command: \033[1m$1\033[0m\nPlease install it via Homebrew or directly from $2"
    exit 1
}

# First Check to see if they have the neccessary software installed
command -v carthage >/dev/null 2>&1 || { missingCommand "carthage" "https://github.com/Carthage/Carthage/releases"; }
command -v swiftlint >/dev/null 2>&1 || { missingCommand "swiftlint" "https://github.com/realm/SwiftLint/releases"; }
command -v npm >/dev/null 2>&1 || { missingCommand "npm" "https://nodejs.org/en/download/"; }

IS_CI_BUILD=0

for i in "$@"
do
case $i in
    -f|--force)
    rm -rf Carthage/*
    rm -rf ~/Library/Caches/org.carthage.CarthageKit
    shift
    ;;
    --ci)
    IS_CI_BUILD=1
    shift
    ;;
esac
done

# Only enable this on the Xcode Server because it times out if it does not
# get any output for some time while building the dependencies.

CARTHAGE_VERBOSE=""
if [ ! -z "$XCS_BOT_ID"  ]; then
  CARTHAGE_VERBOSE="--verbose"
fi

SWIFT_VERSION=4.2 carthage bootstrap $CARTHAGE_VERBOSE --platform ios --color auto --cache-builds --no-use-binaries

# Install Node.js dependencies and build user scripts

if [ "$IS_CI_BUILD" = 0 ]; then
  npm install
else
  npm ci
fi

npm run build
echo "Building sync"
npm run build:sync
echo "Building adblock library"
npm run build:adblock

# Sets up local configurations from the tracked .template files

# Checking the `Local` Directory
CONFIG_PATH="Client/Configuration"
if [ ! -d "$CONFIG_PATH/Local/" ]; then
  echo "Creating 'Local' directory"

  (cd $CONFIG_PATH && mkdir Local)
fi

# Copying over any necessary files into `Local`
for CONFIG_FILE_NAME in BundleId DevTeam BuildId
do
  CONFIG_FILE=$CONFIG_FILE_NAME.xcconfig
  (cd $CONFIG_PATH \
    && cp -n Local.templates/$CONFIG_FILE Local/$CONFIG_FILE \
  )
done

# Build Yubikit
YUBIKIT_DIR=Carthage/Checkouts/yubikit-ios
YUBIKIT_OUT=ThirdParty/YubiKit
SRCDIR=$PWD

rm -rf $YUBIKIT_DIR
rm -rf $YUBIKIT_OUT

git clone -b master --single-branch https://github.com/YubicoLabs/yubikit-ios/ $YUBIKIT_DIR

mkdir -p $SRCDIR/$YUBIKIT_OUT/include
pushd $YUBIKIT_DIR/YubiKit
sh build.sh > yubikit.log 2>&1
cp -r releases/YubiKit/YubiKit/release_universal/  $SRCDIR/$YUBIKIT_OUT/
cp -r releases/YubiKit/YubiKit/include/  $SRCDIR/$YUBIKIT_OUT/include/
popd
