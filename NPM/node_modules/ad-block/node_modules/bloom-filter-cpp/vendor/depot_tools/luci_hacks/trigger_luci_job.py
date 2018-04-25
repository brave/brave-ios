#!/usr/bin/env python
# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


"""Tool to send a recipe job to run on Swarming."""


import argparse
import base64
import json
import os
import re
import subprocess
import sys
import zlib


SWARMING_URL = 'https://chromium.googlesource.com/external/swarming.client.git'
CLIENT_LOCATION = os.path.expanduser('~/.swarming_client')
THIS_DIR = os.path.dirname(os.path.abspath(__file__))
ISOLATE = os.path.join(THIS_DIR, 'luci_recipe_run.isolate')

# This is put in place in order to not need to parse this information from
# master.cfg.  In the LUCI future this would all be stored in a luci.cfg
# file alongside the repo.
RECIPE_MAPPING = {
    'Infra Linux Trusty 64 Tester':
        ('tryserver.infra', 'infra/infra_repo_trybot', 'Ubuntu-14.04'),
    'Infra Linux Precise 32 Tester':
        ('tryserver.infra', 'infra/infra_repo_trybot', 'Ubuntu-12.04'),
    'Infra Mac Tester':
        ('tryserver.infra', 'infra/infra_repo_trybot', 'Mac'),
    'Infra Win Tester':
        ('tryserver.infra', 'infra/infra_repo_trybot', 'Win'),
    'Infra Windows Tester':
        ('tryserver.infra', 'infra/infra_repo_trybot', 'Win'),
    'Infra Presubmit':
        ('tryserver.infra', 'run_presubmit', 'Linux')
}


def parse_args(args):
  # Once Clank switches to bot_update, bot_update would no longer require
  # master/builder detection, and we can remove the master/builder from the args
  parser = argparse.ArgumentParser()
  parser.add_argument('--builder', required=True)
  parser.add_argument('--issue',required=True)
  parser.add_argument('--patchset', required=True)
  parser.add_argument('--revision', default='HEAD')
  parser.add_argument('--patch_project')

  return parser.parse_args(args)


def ensure_swarming_client():
  if not os.path.exists(CLIENT_LOCATION):
    parent, target = os.path.split(CLIENT_LOCATION)
    subprocess.check_call(['git', 'clone', SWARMING_URL, target], cwd=parent)
  else:
    subprocess.check_call(['git', 'pull'], cwd=CLIENT_LOCATION)


def archive_isolate(isolate):
  isolate_py = os.path.join(CLIENT_LOCATION, 'isolate.py')
  cmd = [
      sys.executable, isolate_py, 'archive',
      '--isolated=%sd' % isolate,
      '--isolate-server', 'https://isolateserver.appspot.com',
      '--isolate=%s' % isolate]
  out = subprocess.check_output(cmd)
  return out.split()[0].strip()


def trigger_swarm(isolated, platform, build_props, factory_props):
  # TODO: Make this trigger DM instead.
  swarm_py = os.path.join(CLIENT_LOCATION, 'swarming.py')
  build_props_gz = base64.b64encode(zlib.compress(json.dumps(build_props)))
  fac_props_gz = base64.b64encode(zlib.compress(json.dumps(factory_props)))
  cmd = [
      sys.executable, swarm_py, 'trigger', isolated,
      '--isolate-server', 'isolateserver.appspot.com',
      '--swarming', 'chromium-swarm-dev.appspot.com',
      '-d', 'os', platform,
      '--',
      '--factory-properties-gz=%s' % fac_props_gz,
      '--build-properties-gz=%s' % build_props_gz
  ]
  out = subprocess.check_output(cmd)
  m = re.search(
      r'https://chromium-swarm-dev.appspot.com/user/task/(.*)', out)
  return m.group(1)


def trigger(builder, revision, issue, patchset, project):
  """Constructs/uploads an isolated file and send the job to swarming."""
  master, recipe, platform = RECIPE_MAPPING[builder]
  build_props = {
    'buildnumber': 1,
    'buildername': builder,
    'recipe': recipe,
    'mastername': master,
    'slavename': 'fakeslave',
    'revision': revision,
    'patch_project': project,
  }
  if issue:
    build_props['issue'] = issue
  if patchset:
    build_props['patchset'] = patchset
  factory_props = {
    'recipe': recipe
  }
  ensure_swarming_client()
  arun_isolated = archive_isolate(ISOLATE)
  task = trigger_swarm(arun_isolated, platform, build_props, factory_props)
  print 'https://luci-milo.appspot.com/swarming/%s' % task


def main(args):
  args = parse_args(args)
  trigger(args.builder, args.revision, args.issue,
          args.patchset, args.patch_project)


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
