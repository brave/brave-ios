#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Performs all git-svn setup steps necessary for 'git svn dcommit' to work.

Assumes that trunk of the svn remote maps to master of the git remote.

Example:
git clone https://chromium.googlesource.com/chromium/tools/depot_tools
cd depot_tools
git auto-svn
"""

import argparse
import os
import sys
import urlparse

import subprocess2

from git_common import run as run_git
from git_common import run_stream_with_retcode as run_git_stream_with_retcode
from git_common import set_config, root, ROOT, current_branch
from git_common import upstream as get_upstream
from git_footers import get_footer_svn_id


SVN_EXE = ROOT+'\\svn.bat' if sys.platform.startswith('win') else 'svn'


def run_svn(*cmd, **kwargs):
  """Runs an svn command.

  Returns (stdout, stderr) as a pair of strings.

  Raises subprocess2.CalledProcessError on nonzero return code.
  """
  kwargs.setdefault('stdin', subprocess2.PIPE)
  kwargs.setdefault('stdout', subprocess2.PIPE)
  kwargs.setdefault('stderr', subprocess2.PIPE)

  cmd = (SVN_EXE,) + cmd
  proc = subprocess2.Popen(cmd, **kwargs)
  ret, err = proc.communicate()
  retcode = proc.wait()
  if retcode != 0:
    raise subprocess2.CalledProcessError(retcode, cmd, os.getcwd(), ret, err)

  return ret, err


def main(argv):
  # No command line flags. Just use the parser to prevent people from trying
  # to pass flags that don't do anything, and to provide 'usage'.
  parser = argparse.ArgumentParser(
      description='Automatically set up git-svn for a repo mirrored from svn.')
  parser.parse_args(argv)

  upstreams = []
  # Always configure the upstream trunk.
  upstreams.append(root())
  # Optionally configure whatever upstream branch might be currently checked
  # out. This is needed for work on svn-based branches, otherwise git-svn gets
  # very confused and tries to relate branch commits back to trunk, making a big
  # mess of the codereview patches, and generating all kinds of spurious errors
  # about the repo being in some sort of bad state.
  curr_upstream = get_upstream(current_branch())
  # There will be no upstream if the checkout is in detached HEAD.
  if curr_upstream:
    upstreams.append(curr_upstream)
  for upstream in upstreams:
    config_svn(upstream)
  return 0


def config_svn(upstream):
  svn_id = get_footer_svn_id(upstream)
  assert svn_id, 'No valid git-svn-id footer found on %s.' % upstream
  print 'Found git-svn-id footer %s on %s' % (svn_id, upstream)

  parsed_svn = urlparse.urlparse(svn_id)
  path_components = parsed_svn.path.split('/')
  svn_repo = None
  svn_path = None
  for i in xrange(len(path_components)):
    try:
      maybe_repo = '%s://%s%s' % (
          parsed_svn.scheme, parsed_svn.netloc, '/'.join(path_components[:i+1]))
      print 'Checking ', maybe_repo
      run_svn('info', maybe_repo)
      svn_repo = maybe_repo
      svn_path = '/'.join(path_components[i+1:])
      break
    except subprocess2.CalledProcessError, e:
      if 'E170001' in str(e):
        print 'Authentication failed:'
        print e
        print ('Try running "svn ls %s" with the password'
               ' from https://chromium-access.appspot.com' % maybe_repo)
        print
      continue
  assert svn_repo is not None, 'Unable to find svn repo for %s' % svn_id
  print 'Found upstream svn repo %s and path %s' % (svn_repo, svn_path)

  run_git('config', '--local', '--replace-all', 'svn-remote.svn.url', svn_repo)
  run_git('config', '--local', '--replace-all', 'svn-remote.svn.fetch',
          '%s:refs/remotes/%s' % (svn_path, upstream),
          'refs/remotes/%s$' % upstream)
  print 'Configured metadata, running "git svn fetch". This may take some time.'
  with run_git_stream_with_retcode('svn', 'fetch') as stdout:
    for line in stdout.xreadlines():
      print line.strip()


if __name__ == '__main__':
  try:
    sys.exit(main(sys.argv[1:]))
  except KeyboardInterrupt:
    sys.stderr.write('interrupted\n')
    sys.exit(1)
