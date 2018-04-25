#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Upload a cherry pick CL to rietveld."""

import md5
import optparse
import subprocess2
import sys

import auth

from git_cl import Changelist
from git_common import config, run
from third_party.upload import EncodeMultipartFormData, GitVCS
from rietveld import Rietveld


def cherry_pick(target_branch, commit, auth_config):
  """Attempt to upload a cherry pick CL to rietveld.

  Args:
    target_branch: The branch to cherry pick onto.
    commit: The git hash of the commit to cherry pick.
    auth_config: auth.AuthConfig object with authentication configuration.
  """
  author = config('user.email')

  description = '%s\n\n(cherry picked from commit %s)\n' % (
      run('show', '--pretty=%B', '--quiet', commit), commit)

  parent = run('show', '--pretty=%P', '--quiet', commit)
  print 'Found parent revision:', parent

  class Options(object):
    def __init__(self):
      self.emulate_svn_auto_props = False

  content_type, payload = EncodeMultipartFormData([
      ('base', '%s@%s' % (Changelist().GetRemoteUrl(), target_branch)),
      ('cc', config('rietveld.cc')),
      ('content_upload', '1'),
      ('description', description),
      ('project', '%s@%s' % (config('rietveld.project'), target_branch)),
      ('subject', description.splitlines()[0]),
      ('user', author),
  ], [
      ('data', 'data.diff', GitVCS(Options()).PostProcessDiff(
          run('diff', parent, commit))),
  ])

  rietveld = Rietveld(config('rietveld.server'), auth_config, author)
  # pylint: disable=W0212
  output = rietveld._send(
    '/upload',
    payload=payload,
    content_type=content_type,
  ).splitlines()

  # If successful, output will look like:
  # Issue created. URL: https://codereview.chromium.org/1234567890
  # 1
  # 10001 some/path/first.file
  # 10002 some/path/second.file
  # 10003 some/path/third.file

  if output[0].startswith('Issue created. URL: '):
    print output[0]
    issue = output[0].rsplit('/', 1)[-1]
    patchset = output[1]
    files = output[2:]

    for f in files:
      file_id, filename = f.split()
      mode = 'M'

      try:
        content = run('show', '%s:%s' % (parent, filename))
      except subprocess2.CalledProcessError:
        # File didn't exist in the parent revision.
        content = ''
        mode = 'A'

      content_type, payload = EncodeMultipartFormData([
        ('checksum', md5.md5(content).hexdigest()),
        ('filename', filename),
        ('is_current', 'False'),
        ('status', mode),
      ], [
        ('data', filename, content),
      ])

      # pylint: disable=W0212
      print '  Uploading base file for %s:' % filename, rietveld._send(
        '/%s/upload_content/%s/%s' % (issue, patchset, file_id),
        payload=payload,
        content_type=content_type,
      )

      try:
        content = run('show', '%s:%s' % (commit, filename))
      except subprocess2.CalledProcessError:
        # File no longer exists in the new commit.
        content = ''
        mode = 'D'

      content_type, payload = EncodeMultipartFormData([
        ('checksum', md5.md5(content).hexdigest()),
        ('filename', filename),
        ('is_current', 'True'),
        ('status', mode),
      ], [
        ('data', filename, content),
      ])

      # pylint: disable=W0212
      print '  Uploading %s:' % filename, rietveld._send(
        '/%s/upload_content/%s/%s' % (issue, patchset, file_id),
        payload=payload,
        content_type=content_type,
      )

    # pylint: disable=W0212
    print 'Finalizing upload:', rietveld._send('/%s/upload_complete/1' % issue)


def main():
  parser = optparse.OptionParser(
      usage='usage: %prog --branch <branch> <commit>')
  parser.add_option(
      '--branch',
      '-b',
      help='The upstream branch to cherry pick to.',
      metavar='<branch>')
  auth.add_auth_options(parser)
  options, args = parser.parse_args()
  auth_config = auth.extract_auth_config_from_options

  if not options.branch:
    parser.error('--branch is required')
  if len(args) != 1:
    parser.error('Expecting single argument <commit>')

  cherry_pick(options.branch, args[0], auth_config)
  return 0


if __name__ == '__main__':
  try:
    sys.exit(main())
  except KeyboardInterrupt:
    sys.stderr.write('interrupted\n')
    sys.exit(1)
