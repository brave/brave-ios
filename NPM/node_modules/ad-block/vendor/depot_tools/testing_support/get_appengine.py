#!/usr/bin/env python
# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""This script is copied from
https://chromium.googlesource.com/infra/infra.git/+/master/bootstrap
"""

import datetime
import logging
import optparse
import os
import re
import shutil
import sys
import time
import tempfile
import urllib2
import zipfile

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def get_gae_sdk_version(gae_path):
  """Returns the installed GAE SDK version or None."""
  version_path = os.path.join(gae_path, 'VERSION')
  if os.path.isfile(version_path):
    values = dict(
        map(lambda x: x.strip(), l.split(':'))
        for l in open(version_path) if ':' in l)
    if 'release' in values:
      return values['release'].strip('"')


def get_latest_gae_sdk_url(name):
  """Returns the url to get the latest GAE SDK and its version."""
  url = 'https://cloud.google.com/appengine/downloads.html'
  logging.debug('%s', url)
  content = urllib2.urlopen(url).read()
  regexp = (
      r'(https\:\/\/storage.googleapis.com\/appengine-sdks\/featured\/'
      + re.escape(name) + r'[0-9\.]+?\.zip)')
  m = re.search(regexp, content)
  url = m.group(1)
  # Calculate the version from the url.
  new_version = re.search(re.escape(name) + r'(.+?).zip', url).group(1)
  # Upgrade to https
  return url.replace('http://', 'https://'), new_version


def extract_zip(z, root_path):
  """Extracts files in a zipfile but keep the executable bits."""
  count = 0
  for f in z.infolist():
    perm = (f.external_attr >> 16L) & 0777
    mtime = time.mktime(datetime.datetime(*f.date_time).timetuple())
    filepath = os.path.join(root_path, f.filename)
    logging.debug('Extracting %s', f.filename)
    if f.filename.endswith('/'):
      os.mkdir(filepath, perm)
    else:
      z.extract(f, root_path)
      os.chmod(filepath, perm)
      count += 1
    os.utime(filepath, (mtime, mtime))
  print('Extracted %d files' % count)


def install_latest_gae_sdk(root_path, fetch_go, dry_run):
  if fetch_go:
    rootdir = 'go_appengine'
    if sys.platform == 'darwin':
      name = 'go_appengine_sdk_darwin_amd64-'
    else:
      # Add other platforms as needed.
      name = 'go_appengine_sdk_linux_amd64-'
  else:
    rootdir = 'google_appengine'
    name = 'google_appengine_'

  # The zip file already contains 'google_appengine' (for python) or
  # 'go_appengine' (for go) in its path so it's a bit
  # awkward to unzip otherwise. Hard code the path in for now.
  gae_path = os.path.join(root_path, rootdir)
  print('Looking up path %s' % gae_path)
  version = get_gae_sdk_version(gae_path)
  if version:
    print('Found installed version %s' % version)
  else:
    print('Didn\'t find an SDK')

  url, new_version = get_latest_gae_sdk_url(name)
  print('New version is %s' % new_version)
  if version == new_version:
    return 0

  if os.path.isdir(gae_path):
    print('Removing previous version')
    if not dry_run:
      shutil.rmtree(gae_path)

  print('Fetching %s' % url)
  if not dry_run:
    u = urllib2.urlopen(url)
    with tempfile.NamedTemporaryFile() as f:
      while True:
        chunk = u.read(2 ** 20)
        if not chunk:
          break
        f.write(chunk)
      # Assuming we're extracting there. In fact, we have no idea.
      print('Extracting into %s' % gae_path)
      z = zipfile.ZipFile(f, 'r')
      try:
        extract_zip(z, root_path)
      finally:
        z.close()
  return 0


def main():
  parser = optparse.OptionParser(prog='python -m %s' % __package__)
  parser.add_option('-v', '--verbose', action='store_true')
  parser.add_option(
      '-g', '--go', action='store_true', help='Defaults to python SDK')
  parser.add_option(
      '-d', '--dest', default=os.path.dirname(BASE_DIR), help='Output')
  parser.add_option('--dry-run', action='store_true', help='Do not download')
  options, args = parser.parse_args()
  if args:
    parser.error('Unsupported args: %s' % ' '.join(args))
  logging.basicConfig(level=logging.DEBUG if options.verbose else logging.ERROR)
  return install_latest_gae_sdk(
      os.path.abspath(options.dest), options.go, options.dry_run)


if __name__ == '__main__':
  sys.exit(main())
