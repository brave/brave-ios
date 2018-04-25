#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import re
import sys

from collections import defaultdict

import git_common as git


FOOTER_PATTERN = re.compile(r'^\s*([\w-]+): (.*)$')
CHROME_COMMIT_POSITION_PATTERN = re.compile(r'^([\w/-]+)@{#(\d+)}$')
GIT_SVN_ID_PATTERN = re.compile('^([^\s@]+)@(\d+)')


def normalize_name(header):
  return '-'.join([ word.title() for word in header.strip().split('-') ])


def parse_footer(line):
  match = FOOTER_PATTERN.match(line)
  if match:
    return (match.group(1), match.group(2))
  else:
    return None


def parse_footers(message):
  """Parses a git commit message into a multimap of footers."""
  footer_lines = []
  for line in reversed(message.splitlines()):
    if line == '' or line.isspace():
      break
    footer_lines.append(line)

  footers = map(parse_footer, footer_lines)
  if not all(footers):
    return defaultdict(list)

  footer_map = defaultdict(list)
  for (k, v) in footers:
    footer_map[normalize_name(k)].append(v.strip())

  return footer_map


def get_footer_svn_id(branch=None):
  if not branch:
    branch = git.root()
  svn_id = None
  message = git.run('log', '-1', '--format=%B', branch)
  footers = parse_footers(message)
  git_svn_id = get_unique(footers, 'git-svn-id')
  if git_svn_id:
    match = GIT_SVN_ID_PATTERN.match(git_svn_id)
    if match:
      svn_id = match.group(1)
  return svn_id


def get_unique(footers, key):
  key = normalize_name(key)
  values = footers[key]
  assert len(values) <= 1, 'Multiple %s footers' % key
  if values:
    return values[0]
  else:
    return None


def get_position(footers):
  """Get the commit position from the footers multimap using a heuristic.

  Returns:
    A tuple of the branch and the position on that branch. For example,

    Cr-Commit-Position: refs/heads/master@{#292272}

    would give the return value ('refs/heads/master', 292272).  If
    Cr-Commit-Position is not defined, we try to infer the ref and position
    from git-svn-id. The position number can be None if it was not inferrable.
  """

  position = get_unique(footers, 'Cr-Commit-Position')
  if position:
    match = CHROME_COMMIT_POSITION_PATTERN.match(position)
    assert match, 'Invalid Cr-Commit-Position value: %s' % position
    return (match.group(1), match.group(2))

  svn_commit = get_unique(footers, 'git-svn-id')
  if svn_commit:
    match = GIT_SVN_ID_PATTERN.match(svn_commit)
    assert match, 'Invalid git-svn-id value: %s' % svn_commit
    # V8 has different semantics than Chromium.
    if re.match(r'.*https?://v8\.googlecode\.com/svn/trunk',
                match.group(1)):
      return ('refs/heads/candidates', match.group(2))
    if re.match(r'.*https?://v8\.googlecode\.com/svn/branches/bleeding_edge',
                match.group(1)):
      return ('refs/heads/master', match.group(2))

    # Assume that any trunk svn revision will match the commit-position
    # semantics.
    if re.match('.*/trunk.*$', match.group(1)):
      return ('refs/heads/master', match.group(2))

    # But for now only support faking branch-heads for chrome.
    branch_match = re.match('.*/chrome/branches/([\w/-]+)/src$', match.group(1))
    if branch_match:
      # svn commit numbers do not map to branches.
      return ('refs/branch-heads/%s' % branch_match.group(1), None)

  raise ValueError('Unable to infer commit position from footers')


def main(args):
  parser = argparse.ArgumentParser(
    formatter_class=argparse.ArgumentDefaultsHelpFormatter
  )
  parser.add_argument('ref')

  g = parser.add_mutually_exclusive_group()
  g.add_argument('--key', metavar='KEY',
                 help='Get all values for the given footer name, one per '
                 'line (case insensitive)')
  g.add_argument('--position', action='store_true')
  g.add_argument('--position-ref', action='store_true')
  g.add_argument('--position-num', action='store_true')


  opts = parser.parse_args(args)

  message = git.run('log', '-1', '--format=%B', opts.ref)
  footers = parse_footers(message)

  if opts.key:
    for v in footers.get(normalize_name(opts.key), []):
      print v
  elif opts.position:
    pos = get_position(footers)
    print '%s@{#%s}' % (pos[0], pos[1] or '?')
  elif opts.position_ref:
    print get_position(footers)[0]
  elif opts.position_num:
    pos = get_position(footers)
    assert pos[1], 'No valid position for commit'
    print pos[1]
  else:
    for k in footers.keys():
      for v in footers[k]:
        print '%s: %s' % (k, v)
  return 0


if __name__ == '__main__':
  try:
    sys.exit(main(sys.argv[1:]))
  except KeyboardInterrupt:
    sys.stderr.write('interrupted\n')
    sys.exit(1)
