#!/usr/bin/env python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


"""Download recipe prerequisites and run a single recipe."""


import base64
import json
import os
import subprocess
import sys
import tarfile
import urllib2
import zlib


def download(source, dest):
  u = urllib2.urlopen(source)  # TODO: Verify certificate?
  with open(dest, 'wb') as f:
    while True:
      buf = u.read(8192)
      if not buf:
        break
      f.write(buf)


def unzip(source, dest):
  with tarfile.open(source, 'r') as z:
    z.extractall(dest)


def get_infra(dt_dir, root_dir):
  fetch = os.path.join(dt_dir, 'fetch.py')
  subprocess.check_call([sys.executable, fetch, 'infra'], cwd=root_dir)


def seed_properties(args):
  # Assumes args[0] is factory properties and args[1] is build properties.
  fact_prop_str = args[0][len('--factory-properties-gz='):]
  build_prop_str = args[1][len('--build-properties-gz='):]
  fact_prop = json.loads(zlib.decompress(base64.b64decode(fact_prop_str)))
  build_prop = json.loads(zlib.decompress(base64.b64decode(build_prop_str)))
  for k, v in fact_prop.iteritems():
    print '@@@SET_BUILD_PROPERTY@%s@%s@@@' % (k, v)
  for k, v in build_prop.iteritems():
    print '@@@SET_BUILD_PROPERTY@%s@%s@@@' % (k, v)


def main(args):
  cwd = os.getcwd()

  # Bootstrap depot tools (required for fetching build/infra)
  dt_url = 'https://storage.googleapis.com/dumbtest/depot_tools.tar.gz'
  dt_dir = os.path.join(cwd, 'staging')
  os.makedirs(dt_dir)
  dt_zip = os.path.join(dt_dir, 'depot_tools.tar.gz')
  download(dt_url, os.path.join(dt_zip))
  unzip(dt_zip, dt_dir)
  dt_path = os.path.join(dt_dir, 'depot_tools')
  os.environ['PATH'] = '%s:%s' % (dt_path, os.environ['PATH'])

  # Fetch infra (which comes with build, which comes with recipes)
  root_dir = os.path.join(cwd, 'b')
  os.makedirs(root_dir)
  get_infra(dt_path, root_dir)
  work_dir = os.path.join(root_dir, 'build', 'slave', 'bot', 'build')
  os.makedirs(work_dir)

  # Emit annotations that encapsulates build properties.
  seed_properties(args)

  # JUST DO IT.
  cmd = [sys.executable, '-u', '../../../scripts/slave/annotated_run.py']
  cmd.extend(args)
  subprocess.check_call(cmd, cwd=work_dir)

if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
