#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Rolls DEPS controlled dependency.

Works only with git checkout and git dependencies.  Currently this
script will always roll to the tip of to origin/master.
"""

import argparse
import os
import re
import subprocess
import sys

NEED_SHELL = sys.platform.startswith('win')


class Error(Exception):
  pass


def check_output(*args, **kwargs):
  """subprocess.check_output() passing shell=True on Windows for git."""
  kwargs.setdefault('shell', NEED_SHELL)
  return subprocess.check_output(*args, **kwargs)


def check_call(*args, **kwargs):
  """subprocess.check_call() passing shell=True on Windows for git."""
  kwargs.setdefault('shell', NEED_SHELL)
  subprocess.check_call(*args, **kwargs)


def is_pristine(root, merge_base='origin/master'):
  """Returns True if a git checkout is pristine."""
  cmd = ['git', 'diff', '--ignore-submodules', merge_base]
  return not (check_output(cmd, cwd=root).strip() or
              check_output(cmd + ['--cached'], cwd=root).strip())


def get_log_url(upstream_url, head, master):
  """Returns an URL to read logs via a Web UI if applicable."""
  if re.match(r'https://[^/]*\.googlesource\.com/', upstream_url):
    # gitiles
    return '%s/+log/%s..%s' % (upstream_url, head[:12], master[:12])
  if upstream_url.startswith('https://github.com/'):
    upstream_url = upstream_url.rstrip('/')
    if upstream_url.endswith('.git'):
      upstream_url = upstream_url[:-len('.git')]
    return '%s/compare/%s...%s' % (upstream_url, head[:12], master[:12])
  return None


def should_show_log(upstream_url):
  """Returns True if a short log should be included in the tree."""
  # Skip logs for very active projects.
  if upstream_url.endswith((
      '/angle/angle.git',
      '/catapult-project/catapult.git',
      '/v8/v8.git')):
    return False
  if 'webrtc' in upstream_url:
    return False
  return True


def roll(root, deps_dir, roll_to, key, reviewers, bug, no_log, log_limit,
         ignore_dirty_tree=False):
  deps = os.path.join(root, 'DEPS')
  try:
    with open(deps, 'rb') as f:
      deps_content = f.read()
  except (IOError, OSError):
    raise Error('Ensure the script is run in the directory '
                'containing DEPS file.')

  if not ignore_dirty_tree and not is_pristine(root):
    raise Error('Ensure %s is clean first (no non-merged commits).' % root)

  full_dir = os.path.normpath(os.path.join(os.path.dirname(root), deps_dir))
  if not os.path.isdir(full_dir):
    raise Error('Directory not found: %s (%s)' % (deps_dir, full_dir))
  head = check_output(['git', 'rev-parse', 'HEAD'], cwd=full_dir).strip()

  if not head in deps_content:
    print('Warning: %s is not checked out at the expected revision in DEPS' %
          deps_dir)
    if key is None:
      print("Warning: no key specified.  Using '%s'." % deps_dir)
      key = deps_dir

    # It happens if the user checked out a branch in the dependency by himself.
    # Fall back to reading the DEPS to figure out the original commit.
    for i in deps_content.splitlines():
      m = re.match(r'\s+"' + key + '": "([a-z0-9]{40})",', i)
      if m:
        head = m.group(1)
        break
    else:
      raise Error('Expected to find commit %s for %s in DEPS' % (head, key))

  print('Found old revision %s' % head)

  check_call(['git', 'fetch', 'origin', '--quiet'], cwd=full_dir)
  roll_to = check_output(['git', 'rev-parse', roll_to], cwd=full_dir).strip()
  print('Found new revision %s' % roll_to)

  if roll_to == head:
    raise Error('No revision to roll!')

  commit_range = '%s..%s' % (head[:9], roll_to[:9])

  upstream_url = check_output(
      ['git', 'config', 'remote.origin.url'], cwd=full_dir).strip()
  log_url = get_log_url(upstream_url, head, roll_to)
  cmd = [
    'git', 'log', commit_range, '--date=short', '--no-merges',
  ]
  logs = check_output(
      cmd + ['--format=%ad %ae %s'], # Args with '=' are automatically quoted.
      cwd=full_dir)
  logs = re.sub(r'(?m)^(\d\d\d\d-\d\d-\d\d [^@]+)@[^ ]+( .*)$', r'\1\2', logs)
  nb_commits = logs.count('\n')

  header = 'Roll %s/ %s (%d commit%s).\n\n' % (
      deps_dir,
      commit_range,
      nb_commits,
      's' if nb_commits > 1 else '')

  log_section = ''
  if log_url:
    log_section = log_url + '\n\n'
  log_section += '$ %s ' % ' '.join(cmd)
  log_section += '--format=\'%ad %ae %s\'\n'
  if not no_log and should_show_log(upstream_url):
    if logs.count('\n') > log_limit:
      # Keep the first N log entries.
      logs = ''.join(logs.splitlines(True)[:log_limit]) + '(...)\n'
    log_section += logs
  log_section += '\n'

  reviewer = 'R=%s\n' % ','.join(reviewers) if reviewers else ''
  bug = 'BUG=%s\n' % bug if bug else ''
  msg = header + log_section + reviewer + bug

  print('Commit message:')
  print('\n'.join('    ' + i for i in msg.splitlines()))
  deps_content = deps_content.replace(head, roll_to)
  with open(deps, 'wb') as f:
    f.write(deps_content)
  check_call(['git', 'add', 'DEPS'], cwd=root)
  check_call(['git', 'commit', '--quiet', '-m', msg], cwd=root)

  # Pull the dependency to the right revision. This is surprising to users
  # otherwise.
  check_call(['git', 'checkout', '--quiet', roll_to], cwd=full_dir)

  print('')
  if not reviewers:
    print('You forgot to pass -r, make sure to insert a R=foo@example.com line')
    print('to the commit description before emailing.')
    print('')
  print('Run:')
  print('  git cl upload --send-mail')


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument(
      '--ignore-dirty-tree', action='store_true',
      help='Roll anyways, even if there is a diff.')
  parser.add_argument(
      '-r', '--reviewer',
      help='To specify multiple reviewers, use comma separated list, e.g. '
           '-r joe,jane,john. Defaults to @chromium.org')
  parser.add_argument('-b', '--bug', help='Associate a bug number to the roll')
  parser.add_argument(
      '--no-log', action='store_true',
      help='Do not include the short log in the commit message')
  parser.add_argument(
      '--log-limit', type=int, default=100,
      help='Trim log after N commits (default: %(default)s)')
  parser.add_argument(
      '--roll-to', default='origin/master',
      help='Specify the new commit to roll to (default: %(default)s)')
  parser.add_argument('dep_path', help='Path to dependency')
  parser.add_argument('key', nargs='?',
      help='Regexp for dependency in DEPS file')
  args = parser.parse_args()

  reviewers = None
  if args.reviewer:
    reviewers = args.reviewer.split(',')
    for i, r in enumerate(reviewers):
      if not '@' in r:
        reviewers[i] = r + '@chromium.org'

  try:
    roll(
        os.getcwd(),
        args.dep_path.rstrip('/').rstrip('\\'),
        args.roll_to,
        args.key,
        reviewers,
        args.bug,
        args.no_log,
        args.log_limit,
        args.ignore_dirty_tree)

  except Error as e:
    sys.stderr.write('error: %s\n' % e)
    return 1

  return 0


if __name__ == '__main__':
  sys.exit(main())
