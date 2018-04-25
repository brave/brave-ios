#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Smoke tests for gclient.py.

Shell out 'gclient' and run basic conformance tests.

This test assumes GClientSmokeBase.URL_BASE is valid.
"""

import logging
import os
import re
import subprocess
import sys
import unittest

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT_DIR)

import gclient_utils
import scm as gclient_scm
import subprocess2
from testing_support import fake_repos
from testing_support.fake_repos import join, write

GCLIENT_PATH = os.path.join(ROOT_DIR, 'gclient')
COVERAGE = False


class GClientSmokeBase(fake_repos.FakeReposTestBase):
  def setUp(self):
    super(GClientSmokeBase, self).setUp()
    # Make sure it doesn't try to auto update when testing!
    self.env = os.environ.copy()
    self.env['DEPOT_TOOLS_UPDATE'] = '0'

  def gclient(self, cmd, cwd=None):
    if not cwd:
      cwd = self.root_dir
    if COVERAGE:
      # Don't use the wrapper script.
      cmd_base = ['coverage', 'run', '-a', GCLIENT_PATH + '.py']
    else:
      cmd_base = [GCLIENT_PATH]
    cmd = cmd_base + cmd
    process = subprocess.Popen(cmd, cwd=cwd, env=self.env,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               shell=sys.platform.startswith('win'))
    (stdout, stderr) = process.communicate()
    logging.debug("XXX: %s\n%s\nXXX" % (' '.join(cmd), stdout))
    logging.debug("YYY: %s\n%s\nYYY" % (' '.join(cmd), stderr))
    # pylint: disable=E1103
    return (stdout.replace('\r\n', '\n'), stderr.replace('\r\n', '\n'),
            process.returncode)

  def untangle(self, stdout):
    tasks = {}
    remaining = []
    for line in stdout.splitlines(False):
      m = re.match(r'^(\d)+>(.*)$', line)
      if not m:
        remaining.append(line)
      else:
        self.assertEquals([], remaining)
        tasks.setdefault(int(m.group(1)), []).append(m.group(2))
    out = []
    for key in sorted(tasks.iterkeys()):
      out.extend(tasks[key])
    out.extend(remaining)
    return '\n'.join(out)

  def parseGclient(self, cmd, items, expected_stderr='', untangle=False):
    """Parse gclient's output to make it easier to test.
    If untangle is True, tries to sort out the output from parallel checkout."""
    (stdout, stderr, returncode) = self.gclient(cmd)
    if untangle:
      stdout = self.untangle(stdout)
    self.checkString(expected_stderr, stderr)
    self.assertEquals(0, returncode)
    return self.checkBlock(stdout, items)

  def splitBlock(self, stdout):
    """Split gclient's output into logical execution blocks.
    ___ running 'foo' at '/bar'
    (...)
    ___ running 'baz' at '/bar'
    (...)

    will result in 2 items of len((...).splitlines()) each.
    """
    results = []
    for line in stdout.splitlines(False):
      # Intentionally skips empty lines.
      if not line:
        continue
      if line.startswith('__'):
        match = re.match(r'^________ ([a-z]+) \'(.*)\' in \'(.*)\'$', line)
        if not match:
          match = re.match(r'^_____ (.*) is missing, synching instead$', line)
          if match:
            # Blah, it's when a dependency is deleted, we should probably not
            # output this message.
            results.append([line])
          elif (
              not re.match(
                  r'_____ [^ ]+ : Attempting rebase onto [0-9a-f]+...',
                  line) and
              not re.match(r'_____ [^ ]+ at [^ ]+', line)):
            # The two regexp above are a bit too broad, they are necessary only
            # for git checkouts.
            self.fail(line)
        else:
          results.append([[match.group(1), match.group(2), match.group(3)]])
      else:
        if not results:
          # TODO(maruel): gclient's git stdout is inconsistent.
          # This should fail the test instead!!
          pass
        else:
          results[-1].append(line)
    return results

  def checkBlock(self, stdout, items):
    results = self.splitBlock(stdout)
    for i in xrange(min(len(results), len(items))):
      if isinstance(items[i], (list, tuple)):
        verb = items[i][0]
        path = items[i][1]
      else:
        verb = items[i]
        path = self.root_dir
      self.checkString(results[i][0][0], verb, (i, results[i][0][0], verb))
      if sys.platform == 'win32':
        # Make path lower case since casing can change randomly.
        self.checkString(
            results[i][0][2].lower(),
            path.lower(),
            (i, results[i][0][2].lower(), path.lower()))
      else:
        self.checkString(results[i][0][2], path, (i, results[i][0][2], path))
    self.assertEquals(len(results), len(items), (stdout, items, len(results)))
    return results

  @staticmethod
  def svnBlockCleanup(out):
    """Work around svn status difference between svn 1.5 and svn 1.6
    I don't know why but on Windows they are reversed. So sorts the items."""
    for i in xrange(len(out)):
      if len(out[i]) < 2:
        continue
      out[i] = [out[i][0]] + sorted([x[1:].strip() for x in out[i][1:]])
    return out


class GClientSmoke(GClientSmokeBase):
  """Doesn't require either svnserve nor git-daemon."""
  @property
  def svn_base(self):
    return 'svn://random.server/svn/'

  @property
  def git_base(self):
    return 'git://random.server/git/'

  def testHelp(self):
    """testHelp: make sure no new command was added."""
    result = self.gclient(['help'])
    # Roughly, not too short, not too long.
    self.assertTrue(1000 < len(result[0]) and len(result[0]) < 2300,
                    'Too much written to stdout: %d bytes' % len(result[0]))
    self.assertEquals(0, len(result[1]))
    self.assertEquals(0, result[2])

  def testUnknown(self):
    result = self.gclient(['foo'])
    # Roughly, not too short, not too long.
    self.assertTrue(1000 < len(result[0]) and len(result[0]) < 2300,
                    'Too much written to stdout: %d bytes' % len(result[0]))
    self.assertEquals(0, len(result[1]))
    self.assertEquals(0, result[2])

  def testNotConfigured(self):
    res = ('', 'Error: client not configured; see \'gclient config\'\n', 1)
    self.check(res, self.gclient(['cleanup']))
    self.check(res, self.gclient(['diff']))
    self.check(res, self.gclient(['pack']))
    self.check(res, self.gclient(['revert']))
    self.check(res, self.gclient(['revinfo']))
    self.check(res, self.gclient(['runhooks']))
    self.check(res, self.gclient(['status']))
    self.check(res, self.gclient(['sync']))
    self.check(res, self.gclient(['update']))

  def testConfig(self):
    p = join(self.root_dir, '.gclient')
    def test(cmd, expected):
      if os.path.exists(p):
        os.remove(p)
      results = self.gclient(cmd)
      self.check(('', '', 0), results)
      self.checkString(expected, open(p, 'rU').read())

    test(['config', self.svn_base + 'trunk/src/'],
         ('solutions = [\n'
          '  { "name"        : "src",\n'
          '    "url"         : "%strunk/src",\n'
          '    "deps_file"   : "DEPS",\n'
          '    "managed"     : True,\n'
          '    "custom_deps" : {\n'
          '    },\n'
          '    "safesync_url": "",\n'
          '  },\n'
          ']\n'
          'cache_dir = None\n') % self.svn_base)

    test(['config', self.git_base + 'repo_1', '--name', 'src'],
         ('solutions = [\n'
          '  { "name"        : "src",\n'
          '    "url"         : "%srepo_1",\n'
          '    "deps_file"   : "DEPS",\n'
          '    "managed"     : True,\n'
          '    "custom_deps" : {\n'
          '    },\n'
          '    "safesync_url": "",\n'
          '  },\n'
          ']\n'
          'cache_dir = None\n') % self.git_base)

    test(['config', 'foo', 'faa'],
         'solutions = [\n'
         '  { "name"        : "foo",\n'
         '    "url"         : "foo",\n'
         '    "deps_file"   : "DEPS",\n'
          '    "managed"     : True,\n'
         '    "custom_deps" : {\n'
         '    },\n'
         '    "safesync_url": "faa",\n'
         '  },\n'
         ']\n'
         'cache_dir = None\n')

    test(['config', 'foo', '--deps', 'blah'],
         'solutions = [\n'
         '  { "name"        : "foo",\n'
         '    "url"         : "foo",\n'
         '    "deps_file"   : "blah",\n'
         '    "managed"     : True,\n'
         '    "custom_deps" : {\n'
         '    },\n'
          '    "safesync_url": "",\n'
         '  },\n'
         ']\n'
         'cache_dir = None\n')

    test(['config', '--spec', '["blah blah"]'], '["blah blah"]')

    os.remove(p)
    results = self.gclient(['config', 'foo', 'faa', 'fuu'])
    err = ('Usage: gclient.py config [options] [url] [safesync url]\n\n'
           'gclient.py: error: Inconsistent arguments. Use either --spec or one'
           ' or 2 args\n')
    self.check(('', err, 2), results)
    self.assertFalse(os.path.exists(join(self.root_dir, '.gclient')))

  def testSolutionNone(self):
    results = self.gclient(['config', '--spec',
                            'solutions=[{"name": "./", "url": None}]'])
    self.check(('', '', 0), results)
    results = self.gclient(['sync'])
    self.check(('', '', 0), results)
    self.assertTree({})
    results = self.gclient(['revinfo'])
    self.check(('./: None\n', '', 0), results)
    self.check(('', '', 0), self.gclient(['cleanup']))
    self.check(('', '', 0), self.gclient(['diff']))
    self.assertTree({})
    self.check(('', '', 0), self.gclient(['pack']))
    self.check(('', '', 0), self.gclient(['revert']))
    self.assertTree({})
    self.check(('', '', 0), self.gclient(['runhooks']))
    self.assertTree({})
    self.check(('', '', 0), self.gclient(['status']))

  def testDifferentTopLevelDirectory(self):
    # Check that even if the .gclient file does not mention the directory src
    # itself, but it is included via dependencies, the .gclient file is used.
    self.gclient(['config', self.svn_base + 'trunk/src.DEPS'])
    deps = join(self.root_dir, 'src.DEPS')
    os.mkdir(deps)
    write(join(deps, 'DEPS'),
        'deps = { "src": "%strunk/src" }' % (self.svn_base))
    src = join(self.root_dir, 'src')
    os.mkdir(src)
    res = self.gclient(['status', '--jobs', '1'], src)
    self.checkBlock(res[0], [('running', deps), ('running', src)])


class GClientSmokeGIT(GClientSmokeBase):
  def setUp(self):
    super(GClientSmokeGIT, self).setUp()
    self.enabled = self.FAKE_REPOS.set_up_git()

  def testSync(self):
    if not self.enabled:
      return
    # TODO(maruel): safesync.
    self.gclient(['config', self.git_base + 'repo_1', '--name', 'src'])
    # Test unversioned checkout.
    self.parseGclient(
        ['sync', '--deps', 'mac', '--jobs', '1'],
        ['running', 'running'])
    # TODO(maruel): http://crosbug.com/3582 hooks run even if not matching, must
    # add sync parsing to get the list of updated files.
    tree = self.mangle_git_tree(('repo_1@2', 'src'),
                                ('repo_2@1', 'src/repo2'),
                                ('repo_3@2', 'src/repo2/repo_renamed'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

    # Manually remove git_hooked1 before synching to make sure it's not
    # recreated.
    os.remove(join(self.root_dir, 'src', 'git_hooked1'))

    # Test incremental versioned sync: sync backward.
    self.parseGclient(
        ['sync', '--jobs', '1', '--revision',
        'src@' + self.githash('repo_1', 1),
        '--deps', 'mac', '--delete_unversioned_trees'],
        ['deleting'])
    tree = self.mangle_git_tree(('repo_1@1', 'src'),
                                ('repo_2@2', 'src/repo2'),
                                ('repo_3@1', 'src/repo2/repo3'),
                                ('repo_4@2', 'src/repo4'))
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)
    # Test incremental sync: delete-unversioned_trees isn't there.
    self.parseGclient(
        ['sync', '--deps', 'mac', '--jobs', '1'],
        ['running', 'running'])
    tree = self.mangle_git_tree(('repo_1@2', 'src'),
                                ('repo_2@1', 'src/repo2'),
                                ('repo_3@1', 'src/repo2/repo3'),
                                ('repo_3@2', 'src/repo2/repo_renamed'),
                                ('repo_4@2', 'src/repo4'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

  def testSyncIgnoredSolutionName(self):
    """TODO(maruel): This will become an error soon."""
    if not self.enabled:
      return
    self.gclient(['config', self.git_base + 'repo_1', '--name', 'src'])
    self.parseGclient(
        ['sync', '--deps', 'mac', '--jobs', '1',
         '--revision', 'invalid@' + self.githash('repo_1', 1)],
        ['running', 'running'],
        'Please fix your script, having invalid --revision flags '
        'will soon considered an error.\n')
    tree = self.mangle_git_tree(('repo_1@2', 'src'),
                                ('repo_2@1', 'src/repo2'),
                                ('repo_3@2', 'src/repo2/repo_renamed'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

  def testSyncNoSolutionName(self):
    if not self.enabled:
      return
    # When no solution name is provided, gclient uses the first solution listed.
    self.gclient(['config', self.git_base + 'repo_1', '--name', 'src'])
    self.parseGclient(
        ['sync', '--deps', 'mac', '--jobs', '1',
         '--revision', self.githash('repo_1', 1)],
        [])
    tree = self.mangle_git_tree(('repo_1@1', 'src'),
                                ('repo_2@2', 'src/repo2'),
                                ('repo_3@1', 'src/repo2/repo3'),
                                ('repo_4@2', 'src/repo4'))
    self.assertTree(tree)

  def testSyncJobs(self):
    if not self.enabled:
      return
    # TODO(maruel): safesync.
    self.gclient(['config', self.git_base + 'repo_1', '--name', 'src'])
    # Test unversioned checkout.
    self.parseGclient(
        ['sync', '--deps', 'mac', '--jobs', '8'],
        ['running', 'running'],
        untangle=True)
    # TODO(maruel): http://crosbug.com/3582 hooks run even if not matching, must
    # add sync parsing to get the list of updated files.
    tree = self.mangle_git_tree(('repo_1@2', 'src'),
                                ('repo_2@1', 'src/repo2'),
                                ('repo_3@2', 'src/repo2/repo_renamed'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

    # Manually remove git_hooked1 before synching to make sure it's not
    # recreated.
    os.remove(join(self.root_dir, 'src', 'git_hooked1'))

    # Test incremental versioned sync: sync backward.
    # Use --jobs 1 otherwise the order is not deterministic.
    self.parseGclient(
        ['sync', '--revision', 'src@' + self.githash('repo_1', 1),
          '--deps', 'mac', '--delete_unversioned_trees', '--jobs', '1'],
        ['deleting'],
        untangle=True)
    tree = self.mangle_git_tree(('repo_1@1', 'src'),
                                ('repo_2@2', 'src/repo2'),
                                ('repo_3@1', 'src/repo2/repo3'),
                                ('repo_4@2', 'src/repo4'))
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)
    # Test incremental sync: delete-unversioned_trees isn't there.
    self.parseGclient(
        ['sync', '--deps', 'mac', '--jobs', '8'],
        ['running', 'running'],
        untangle=True)
    tree = self.mangle_git_tree(('repo_1@2', 'src'),
                                ('repo_2@1', 'src/repo2'),
                                ('repo_3@1', 'src/repo2/repo3'),
                                ('repo_3@2', 'src/repo2/repo_renamed'),
                                ('repo_4@2', 'src/repo4'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

  def testRunHooks(self):
    if not self.enabled:
      return
    self.gclient(['config', self.git_base + 'repo_1', '--name', 'src'])
    self.gclient(['sync', '--deps', 'mac'])
    tree = self.mangle_git_tree(('repo_1@2', 'src'),
                                ('repo_2@1', 'src/repo2'),
                                ('repo_3@2', 'src/repo2/repo_renamed'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

    os.remove(join(self.root_dir, 'src', 'git_hooked1'))
    os.remove(join(self.root_dir, 'src', 'git_hooked2'))
    # runhooks runs all hooks even if not matching by design.
    out = self.parseGclient(['runhooks', '--deps', 'mac'],
                            ['running', 'running'])
    self.assertEquals(1, len(out[0]))
    self.assertEquals(1, len(out[1]))
    tree = self.mangle_git_tree(('repo_1@2', 'src'),
                                ('repo_2@1', 'src/repo2'),
                                ('repo_3@2', 'src/repo2/repo_renamed'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

  def testPreDepsHooks(self):
    if not self.enabled:
      return
    self.gclient(['config', self.git_base + 'repo_5', '--name', 'src'])
    expectation = [
        ('running', self.root_dir),                 # pre-deps hook
    ]
    out = self.parseGclient(['sync', '--deps', 'mac', '--jobs=1',
                             '--revision', 'src@' + self.githash('repo_5', 2)],
                            expectation)
    self.assertEquals(2, len(out[0]))
    self.assertEquals('pre-deps hook', out[0][1])
    tree = self.mangle_git_tree(('repo_5@2', 'src'),
                                ('repo_1@2', 'src/repo1'),
                                ('repo_2@1', 'src/repo2')
                                )
    tree['src/git_pre_deps_hooked'] = 'git_pre_deps_hooked'
    self.assertTree(tree)

    os.remove(join(self.root_dir, 'src', 'git_pre_deps_hooked'))

    # Pre-DEPS hooks don't run with runhooks.
    self.gclient(['runhooks', '--deps', 'mac'])
    tree = self.mangle_git_tree(('repo_5@2', 'src'),
                                ('repo_1@2', 'src/repo1'),
                                ('repo_2@1', 'src/repo2')
                                )
    self.assertTree(tree)

    # Pre-DEPS hooks run when syncing with --nohooks.
    self.gclient(['sync', '--deps', 'mac', '--nohooks',
                  '--revision', 'src@' + self.githash('repo_5', 2)])
    tree = self.mangle_git_tree(('repo_5@2', 'src'),
                                ('repo_1@2', 'src/repo1'),
                                ('repo_2@1', 'src/repo2')
                                )
    tree['src/git_pre_deps_hooked'] = 'git_pre_deps_hooked'
    self.assertTree(tree)

    os.remove(join(self.root_dir, 'src', 'git_pre_deps_hooked'))

    # Pre-DEPS hooks don't run with --noprehooks
    self.gclient(['sync', '--deps', 'mac', '--noprehooks',
                  '--revision', 'src@' + self.githash('repo_5', 2)])
    tree = self.mangle_git_tree(('repo_5@2', 'src'),
                                ('repo_1@2', 'src/repo1'),
                                ('repo_2@1', 'src/repo2')
                                )
    self.assertTree(tree)

  def testPreDepsHooksError(self):
    if not self.enabled:
      return
    self.gclient(['config', self.git_base + 'repo_5', '--name', 'src'])
    expectated_stdout = [
        ('running', self.root_dir),                 # pre-deps hook
        ('running', self.root_dir),                 # pre-deps hook (fails)
    ]
    expected_stderr = ("Error: Command '/usr/bin/python -c import sys; "
                       "sys.exit(1)' returned non-zero exit status 1 in %s\n"
                       % self.root_dir)
    stdout, stderr, retcode = self.gclient(['sync', '--deps', 'mac', '--jobs=1',
                                            '--revision',
                                            'src@' + self.githash('repo_5', 3)])
    self.assertEquals(stderr, expected_stderr)
    self.assertEquals(2, retcode)
    self.checkBlock(stdout, expectated_stdout)

  def testRevInfo(self):
    if not self.enabled:
      return
    self.gclient(['config', self.git_base + 'repo_1', '--name', 'src'])
    self.gclient(['sync', '--deps', 'mac'])
    results = self.gclient(['revinfo', '--deps', 'mac'])
    out = ('src: %(base)srepo_1\n'
           'src/repo2: %(base)srepo_2@%(hash2)s\n'
           'src/repo2/repo_renamed: %(base)srepo_3\n' %
          {
            'base': self.git_base,
            'hash2': self.githash('repo_2', 1)[:7],
          })
    self.check((out, '', 0), results)
    results = self.gclient(['revinfo', '--deps', 'mac', '--actual'])
    out = ('src: %(base)srepo_1@%(hash1)s\n'
           'src/repo2: %(base)srepo_2@%(hash2)s\n'
           'src/repo2/repo_renamed: %(base)srepo_3@%(hash3)s\n' %
          {
            'base': self.git_base,
            'hash1': self.githash('repo_1', 2),
            'hash2': self.githash('repo_2', 1),
            'hash3': self.githash('repo_3', 2),
          })
    self.check((out, '', 0), results)


class GClientSmokeGITMutates(GClientSmokeBase):
  """testRevertAndStatus mutates the git repo so move it to its own suite."""
  def setUp(self):
    super(GClientSmokeGITMutates, self).setUp()
    self.enabled = self.FAKE_REPOS.set_up_git()

  def testRevertAndStatus(self):
    if not self.enabled:
      return

    # Commit new change to repo to make repo_2's hash use a custom_var.
    cur_deps = self.FAKE_REPOS.git_hashes['repo_1'][-1][1]['DEPS']
    repo_2_hash = self.FAKE_REPOS.git_hashes['repo_2'][1][0][:7]
    new_deps = cur_deps.replace('repo_2@%s\'' % repo_2_hash,
                                'repo_2@\' + Var(\'r2hash\')')
    new_deps = 'vars = {\'r2hash\': \'%s\'}\n%s' % (repo_2_hash, new_deps)
    self.FAKE_REPOS._commit_git('repo_1', {  # pylint: disable=W0212
      'DEPS': new_deps,
      'origin': 'git/repo_1@3\n',
    })

    config_template = (
"""solutions = [{
  "name"        : "src",
  "url"         : "%(git_base)srepo_1",
  "deps_file"   : "DEPS",
  "managed"     : True,
  "custom_vars" : %(custom_vars)s,
}]""")

    self.gclient(['config', '--spec', config_template % {
      'git_base': self.git_base,
      'custom_vars': {}
    }])

    # Tested in testSync.
    self.gclient(['sync', '--deps', 'mac'])
    write(join(self.root_dir, 'src', 'repo2', 'hi'), 'Hey!')

    out = self.parseGclient(['status', '--deps', 'mac', '--jobs', '1'], [])
    # TODO(maruel): http://crosbug.com/3584 It should output the unversioned
    # files.
    self.assertEquals(0, len(out))

    # Revert implies --force implies running hooks without looking at pattern
    # matching. For each expected path, 'git reset' and 'git clean' are run, so
    # there should be two results for each. The last two results should reflect
    # writing git_hooked1 and git_hooked2. There's only one result for the third
    # because it is clean and has no output for 'git clean'.
    out = self.parseGclient(['revert', '--deps', 'mac', '--jobs', '1'],
                            ['running', 'running'])
    self.assertEquals(2, len(out))
    tree = self.mangle_git_tree(('repo_1@3', 'src'),
                                ('repo_2@1', 'src/repo2'),
                                ('repo_3@2', 'src/repo2/repo_renamed'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

    # Make a new commit object in the origin repo, to force reset to fetch.
    self.FAKE_REPOS._commit_git('repo_2', {  # pylint: disable=W0212
      'origin': 'git/repo_2@3\n',
    })

    self.gclient(['config', '--spec', config_template % {
      'git_base': self.git_base,
      'custom_vars': {'r2hash': self.FAKE_REPOS.git_hashes['repo_2'][-1][0] }
    }])
    out = self.parseGclient(['revert', '--deps', 'mac', '--jobs', '1'],
                            ['running', 'running'])
    self.assertEquals(2, len(out))
    tree = self.mangle_git_tree(('repo_1@3', 'src'),
                                ('repo_2@3', 'src/repo2'),
                                ('repo_3@2', 'src/repo2/repo_renamed'))
    tree['src/git_hooked1'] = 'git_hooked1'
    tree['src/git_hooked2'] = 'git_hooked2'
    self.assertTree(tree)

    results = self.gclient(['status', '--deps', 'mac', '--jobs', '1'])
    out = results[0].splitlines(False)
    # TODO(maruel): http://crosbug.com/3584 It should output the unversioned
    # files.
    self.assertEquals(0, len(out))

  def testSyncNoHistory(self):
    if not self.enabled:
      return
    # Create an extra commit in repo_2 and point DEPS to its hash.
    cur_deps = self.FAKE_REPOS.git_hashes['repo_1'][-1][1]['DEPS']
    repo_2_hash_old = self.FAKE_REPOS.git_hashes['repo_2'][1][0][:7]
    self.FAKE_REPOS._commit_git('repo_2', {  # pylint: disable=W0212
      'last_file': 'file created in last commit',
    })
    repo_2_hash_new = self.FAKE_REPOS.git_hashes['repo_2'][-1][0]
    new_deps = cur_deps.replace(repo_2_hash_old, repo_2_hash_new)
    self.assertNotEqual(new_deps, cur_deps)
    self.FAKE_REPOS._commit_git('repo_1', {  # pylint: disable=W0212
      'DEPS': new_deps,
      'origin': 'git/repo_1@4\n',
    })

    config_template = (
"""solutions = [{
"name"        : "src",
"url"         : "%(git_base)srepo_1",
"deps_file"   : "DEPS",
"managed"     : True,
}]""")

    self.gclient(['config', '--spec', config_template % {
      'git_base': self.git_base
    }])

    self.gclient(['sync', '--no-history', '--deps', 'mac'])
    repo2_root = join(self.root_dir, 'src', 'repo2')

    # Check that repo_2 is actually shallow and its log has only one entry.
    rev_lists = subprocess2.check_output(['git', 'rev-list', 'HEAD'],
                                         cwd=repo2_root)
    self.assertEquals(repo_2_hash_new, rev_lists.strip('\r\n'))

    # Check that we have actually checked out the right commit.
    self.assertTrue(os.path.exists(join(repo2_root, 'last_file')))


class SkiaDEPSTransitionSmokeTest(GClientSmokeBase):
  """Simulate the behavior of bisect bots as they transition across the Skia
  DEPS change."""

  FAKE_REPOS_CLASS = fake_repos.FakeRepoSkiaDEPS

  def setUp(self):
    super(SkiaDEPSTransitionSmokeTest, self).setUp()
    self.enabled = self.FAKE_REPOS.set_up_git()

  def testSkiaDEPSChangeGit(self):
    if not self.enabled:
      return

    # Create an initial checkout:
    # - Single checkout at the root.
    # - Multiple checkouts in a shared subdirectory.
    self.gclient(['config', '--spec',
        'solutions=['
        '{"name": "src",'
        ' "url": "' + self.git_base + 'repo_2",'
        '}]'])

    checkout_path = os.path.join(self.root_dir, 'src')
    skia = os.path.join(checkout_path, 'third_party', 'skia')
    skia_gyp = os.path.join(skia, 'gyp')
    skia_include = os.path.join(skia, 'include')
    skia_src = os.path.join(skia, 'src')

    gyp_git_url = self.git_base + 'repo_3'
    include_git_url = self.git_base + 'repo_4'
    src_git_url = self.git_base + 'repo_5'
    skia_git_url = self.FAKE_REPOS.git_base + 'repo_1'

    pre_hash = self.githash('repo_2', 1)
    post_hash = self.githash('repo_2', 2)

    # Initial sync. Verify that we get the expected checkout.
    res = self.gclient(['sync', '--deps', 'mac', '--revision',
                        'src@%s' % pre_hash])
    self.assertEqual(res[2], 0, 'Initial sync failed.')
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_gyp), gyp_git_url)
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_include), include_git_url)
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_src), src_git_url)

    # Verify that the sync succeeds. Verify that we have the  expected merged
    # checkout.
    res = self.gclient(['sync', '--deps', 'mac', '--revision',
                        'src@%s' % post_hash])
    self.assertEqual(res[2], 0, 'DEPS change sync failed.')
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia), skia_git_url)

    # Sync again. Verify that we still have the expected merged checkout.
    res = self.gclient(['sync', '--deps', 'mac', '--revision',
                        'src@%s' % post_hash])
    self.assertEqual(res[2], 0, 'Subsequent sync failed.')
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia), skia_git_url)

    # Sync back to the original DEPS. Verify that we get the original structure.
    res = self.gclient(['sync', '--deps', 'mac', '--revision',
                        'src@%s' % pre_hash])
    self.assertEqual(res[2], 0, 'Reverse sync failed.')
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_gyp), gyp_git_url)
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_include), include_git_url)
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_src), src_git_url)

    # Sync again. Verify that we still have the original structure.
    res = self.gclient(['sync', '--deps', 'mac', '--revision',
                        'src@%s' % pre_hash])
    self.assertEqual(res[2], 0, 'Subsequent sync #2 failed.')
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_gyp), gyp_git_url)
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_include), include_git_url)
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             skia_src), src_git_url)


class BlinkDEPSTransitionSmokeTest(GClientSmokeBase):
  """Simulate the behavior of bisect bots as they transition across the Blink
  DEPS change."""

  FAKE_REPOS_CLASS = fake_repos.FakeRepoBlinkDEPS

  def setUp(self):
    super(BlinkDEPSTransitionSmokeTest, self).setUp()
    self.enabled = self.FAKE_REPOS.set_up_git()
    self.checkout_path = os.path.join(self.root_dir, 'src')
    self.blink = os.path.join(self.checkout_path, 'third_party', 'WebKit')
    self.blink_git_url = self.FAKE_REPOS.git_base + 'repo_2'
    self.pre_merge_sha = self.githash('repo_1', 1)
    self.post_merge_sha = self.githash('repo_1', 2)

  def CheckStatusPreMergePoint(self):
    self.assertEqual(gclient_scm.GIT.Capture(['config', 'remote.origin.url'],
                                             self.blink), self.blink_git_url)
    self.assertTrue(os.path.exists(join(self.blink, '.git')))
    self.assertTrue(os.path.exists(join(self.blink, 'OWNERS')))
    with open(join(self.blink, 'OWNERS')) as f:
      owners_content = f.read()
      self.assertEqual('OWNERS-pre', owners_content, 'OWNERS not updated')
    self.assertTrue(os.path.exists(join(self.blink, 'Source', 'exists_always')))
    self.assertTrue(os.path.exists(
        join(self.blink, 'Source', 'exists_before_but_not_after')))
    self.assertFalse(os.path.exists(
        join(self.blink, 'Source', 'exists_after_but_not_before')))

  def CheckStatusPostMergePoint(self):
    # Check that the contents still exists
    self.assertTrue(os.path.exists(join(self.blink, 'OWNERS')))
    with open(join(self.blink, 'OWNERS')) as f:
      owners_content = f.read()
      self.assertEqual('OWNERS-post', owners_content, 'OWNERS not updated')
    self.assertTrue(os.path.exists(join(self.blink, 'Source', 'exists_always')))
    # Check that file removed between the branch point are actually deleted.
    self.assertTrue(os.path.exists(
        join(self.blink, 'Source', 'exists_after_but_not_before')))
    self.assertFalse(os.path.exists(
        join(self.blink, 'Source', 'exists_before_but_not_after')))
    # But not the .git folder
    self.assertFalse(os.path.exists(join(self.blink, '.git')))

  @unittest.skip('flaky')
  def testBlinkDEPSChangeUsingGclient(self):
    """Checks that {src,blink} repos are consistent when syncing going back and
    forth using gclient sync src@revision."""
    if not self.enabled:
      return

    self.gclient(['config', '--spec',
        'solutions=['
        '{"name": "src",'
        ' "url": "' + self.git_base + 'repo_1",'
        '}]'])

    # Go back and forth two times.
    for _ in xrange(2):
      res = self.gclient(['sync', '--jobs', '1',
                          '--revision', 'src@%s' % self.pre_merge_sha])
      self.assertEqual(res[2], 0, 'DEPS change sync failed.')
      self.CheckStatusPreMergePoint()

      res = self.gclient(['sync', '--jobs', '1',
                          '--revision', 'src@%s' % self.post_merge_sha])
      self.assertEqual(res[2], 0, 'DEPS change sync failed.')
      self.CheckStatusPostMergePoint()


  @unittest.skip('flaky')
  def testBlinkDEPSChangeUsingGit(self):
    """Like testBlinkDEPSChangeUsingGclient, but move the main project using
    directly git and not gclient sync."""
    if not self.enabled:
      return

    self.gclient(['config', '--spec',
        'solutions=['
        '{"name": "src",'
        ' "url": "' + self.git_base + 'repo_1",'
        ' "managed": False,'
        '}]'])

    # Perform an initial sync to bootstrap the repo.
    res = self.gclient(['sync', '--jobs', '1'])
    self.assertEqual(res[2], 0, 'Initial gclient sync failed.')

    # Go back and forth two times.
    for _ in xrange(2):
      subprocess2.check_call(['git', 'checkout', '-q', self.pre_merge_sha],
                             cwd=self.checkout_path)
      res = self.gclient(['sync', '--jobs', '1'])
      self.assertEqual(res[2], 0, 'gclient sync failed.')
      self.CheckStatusPreMergePoint()

      subprocess2.check_call(['git', 'checkout', '-q', self.post_merge_sha],
                             cwd=self.checkout_path)
      res = self.gclient(['sync', '--jobs', '1'])
      self.assertEqual(res[2], 0, 'DEPS change sync failed.')
      self.CheckStatusPostMergePoint()


  @unittest.skip('flaky')
  def testBlinkLocalBranchesArePreserved(self):
    """Checks that the state of local git branches are effectively preserved
    when going back and forth."""
    if not self.enabled:
      return

    self.gclient(['config', '--spec',
        'solutions=['
        '{"name": "src",'
        ' "url": "' + self.git_base + 'repo_1",'
        '}]'])

    # Initialize to pre-merge point.
    self.gclient(['sync', '--revision', 'src@%s' % self.pre_merge_sha])
    self.CheckStatusPreMergePoint()

    # Create a branch named "foo".
    subprocess2.check_call(['git', 'checkout', '-qB', 'foo'],
                           cwd=self.blink)

    # Cross the pre-merge point.
    self.gclient(['sync', '--revision', 'src@%s' % self.post_merge_sha])
    self.CheckStatusPostMergePoint()

    # Go backwards and check that we still have the foo branch.
    self.gclient(['sync', '--revision', 'src@%s' % self.pre_merge_sha])
    self.CheckStatusPreMergePoint()
    subprocess2.check_call(
        ['git', 'show-ref', '-q', '--verify', 'refs/heads/foo'], cwd=self.blink)


if __name__ == '__main__':
  if '-v' in sys.argv:
    logging.basicConfig(level=logging.DEBUG)

  if '-c' in sys.argv:
    COVERAGE = True
    sys.argv.remove('-c')
    if os.path.exists('.coverage'):
      os.remove('.coverage')
    os.environ['COVERAGE_FILE'] = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        '.coverage')
  unittest.main()
