# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys

import config_util  # pylint: disable=F0401


# This class doesn't need an __init__ method, so we disable the warning
# pylint: disable=W0232
class Mojo(config_util.Config):
  """Basic Config class for Mojo."""

  @staticmethod
  def fetch_spec(props):
    url = 'https://github.com/domokit/mojo.git'
    solution = {
      'name'   :'src',
      'url'    : url,
      'deps_file': 'DEPS',
      'managed'   : False,
      'custom_deps': {},
      'safesync_url': '',
    }
    spec = {
      'solutions': [solution],
    }
    if props.get('target_os'):
      spec['target_os'] = props['target_os'].split(',')
    return {
      'type': 'gclient_git',
      'gclient_git_spec': spec,
    }

  @staticmethod
  def expected_root(_props):
    return 'src'


def main(argv=None):
  return Mojo().handle_args(argv)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
