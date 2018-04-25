#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for gclient_scm.py."""

# pylint: disable=E1103

# Import before super_mox to keep valid references.
from shutil import rmtree
from subprocess import Popen, PIPE, STDOUT

import logging
import os
import re
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from testing_support.super_mox import mox, StdoutCheck, SuperMoxTestBase
from testing_support.super_mox import TestCaseUtils

import gclient_scm
import git_cache
import subprocess2

# Disable global git cache
git_cache.Mirror.SetCachePath(None)

# Shortcut since this function is used often
join = gclient_scm.os.path.join

TIMESTAMP_RE = re.compile('\[[0-9]{1,2}:[0-9]{2}:[0-9]{2}\] (.*)', re.DOTALL)
def strip_timestamps(value):
  lines = value.splitlines(True)
  for i in xrange(len(lines)):
    m = TIMESTAMP_RE.match(lines[i])
    if m:
      lines[i] = m.group(1)
  return ''.join(lines)

# Access to a protected member XXX of a client class
# pylint: disable=W0212


class GCBaseTestCase(object):
  def assertRaisesError(self, msg, fn, *args, **kwargs):
    """Like unittest's assertRaises() but checks for Gclient.Error."""
    # pylint: disable=E1101
    try:
      fn(*args, **kwargs)
    except gclient_scm.gclient_utils.Error, e:
      self.assertEquals(e.args[0], msg)
    else:
      self.fail('%s not raised' % msg)


class BaseTestCase(GCBaseTestCase, SuperMoxTestBase):
  def setUp(self):
    SuperMoxTestBase.setUp(self)
    self.mox.StubOutWithMock(gclient_scm.gclient_utils, 'CheckCallAndFilter')
    self.mox.StubOutWithMock(gclient_scm.gclient_utils,
        'CheckCallAndFilterAndHeader')
    self.mox.StubOutWithMock(gclient_scm.gclient_utils, 'FileRead')
    self.mox.StubOutWithMock(gclient_scm.gclient_utils, 'FileWrite')
    self.mox.StubOutWithMock(gclient_scm.gclient_utils, 'rmtree')
    self.mox.StubOutWithMock(gclient_scm.scm.SVN, 'Capture')
    self.mox.StubOutWithMock(gclient_scm.scm.SVN, '_CaptureInfo')
    self.mox.StubOutWithMock(gclient_scm.scm.SVN, 'CaptureStatus')
    self.mox.StubOutWithMock(gclient_scm.scm.SVN, 'RunAndGetFileList')
    self.mox.StubOutWithMock(subprocess2, 'communicate')
    self.mox.StubOutWithMock(subprocess2, 'Popen')
    self._scm_wrapper = gclient_scm.CreateSCM
    gclient_scm.scm.SVN.current_version = None
    self._original_SVNBinaryExists = gclient_scm.SVNWrapper.BinaryExists
    self._original_GitBinaryExists = gclient_scm.GitWrapper.BinaryExists
    gclient_scm.SVNWrapper.BinaryExists = staticmethod(lambda : True)
    gclient_scm.GitWrapper.BinaryExists = staticmethod(lambda : True)
    # Absolute path of the fake checkout directory.
    self.base_path = join(self.root_dir, self.relpath)

  def tearDown(self):
    SuperMoxTestBase.tearDown(self)
    gclient_scm.SVNWrapper.BinaryExists = self._original_SVNBinaryExists
    gclient_scm.GitWrapper.BinaryExists = self._original_GitBinaryExists


class BasicTests(SuperMoxTestBase):
  def setUp(self):
    SuperMoxTestBase.setUp(self)

  def testGetFirstRemoteUrl(self):
    REMOTE_STRINGS = [('remote.origin.url E:\\foo\\bar', 'E:\\foo\\bar'),
                      ('remote.origin.url /b/foo/bar', '/b/foo/bar'),
                      ('remote.origin.url https://foo/bar', 'https://foo/bar'),
                      ('remote.origin.url E:\\Fo Bar\\bax', 'E:\\Fo Bar\\bax'),
                      ('remote.origin.url git://what/"do', 'git://what/"do')]
    FAKE_PATH = '/fake/path'
    self.mox.StubOutWithMock(gclient_scm.scm.GIT, 'Capture')
    for question, _ in REMOTE_STRINGS:
      gclient_scm.scm.GIT.Capture(
          ['config', '--local', '--get-regexp', r'remote.*.url'],
          cwd=FAKE_PATH).AndReturn(question)

    self.mox.ReplayAll()

    for _, answer in REMOTE_STRINGS:
      self.assertEquals(gclient_scm.SCMWrapper._get_first_remote_url(FAKE_PATH),
                        answer)

  def tearDown(self):
    SuperMoxTestBase.tearDown(self)


class BaseGitWrapperTestCase(GCBaseTestCase, StdoutCheck, TestCaseUtils,
                             unittest.TestCase):
  """This class doesn't use pymox."""
  class OptionsObject(object):
    def __init__(self, verbose=False, revision=None):
      self.auto_rebase = False
      self.verbose = verbose
      self.revision = revision
      self.manually_grab_svn_rev = True
      self.deps_os = None
      self.force = False
      self.reset = False
      self.nohooks = False
      self.no_history = False
      self.upstream = False
      self.cache_dir = None
      self.merge = False
      self.jobs = 1
      self.delete_unversioned_trees = False

  sample_git_import = """blob
mark :1
data 6
Hello

blob
mark :2
data 4
Bye

reset refs/heads/master
commit refs/heads/master
mark :3
author Bob <bob@example.com> 1253744361 -0700
committer Bob <bob@example.com> 1253744361 -0700
data 8
A and B
M 100644 :1 a
M 100644 :2 b

blob
mark :4
data 10
Hello
You

blob
mark :5
data 8
Bye
You

commit refs/heads/origin
mark :6
author Alice <alice@example.com> 1253744424 -0700
committer Alice <alice@example.com> 1253744424 -0700
data 13
Personalized
from :3
M 100644 :4 a
M 100644 :5 b

blob
mark :7
data 5
Mooh

commit refs/heads/feature
mark :8
author Bob <bob@example.com> 1390311986 -0000
committer Bob <bob@example.com> 1390311986 -0000
data 6
Add C
from :3
M 100644 :7 c

reset refs/heads/master
from :3
"""
  def Options(self, *args, **kwargs):
    return self.OptionsObject(*args, **kwargs)

  def checkstdout(self, expected):
    value = sys.stdout.getvalue()
    sys.stdout.close()
    # pylint: disable=E1101
    self.assertEquals(expected, strip_timestamps(value))

  @staticmethod
  def CreateGitRepo(git_import, path):
    """Do it for real."""
    try:
      Popen(['git', 'init', '-q'], stdout=PIPE, stderr=STDOUT,
            cwd=path).communicate()
    except OSError:
      # git is not available, skip this test.
      return False
    Popen(['git', 'fast-import', '--quiet'], stdin=PIPE, stdout=PIPE,
        stderr=STDOUT, cwd=path).communicate(input=git_import)
    Popen(['git', 'checkout', '-q'], stdout=PIPE, stderr=STDOUT,
        cwd=path).communicate()
    Popen(['git', 'remote', 'add', '-f', 'origin', '.'], stdout=PIPE,
        stderr=STDOUT, cwd=path).communicate()
    Popen(['git', 'checkout', '-b', 'new', 'origin/master', '-q'], stdout=PIPE,
        stderr=STDOUT, cwd=path).communicate()
    Popen(['git', 'push', 'origin', 'origin/origin:origin/master', '-q'],
        stdout=PIPE, stderr=STDOUT, cwd=path).communicate()
    Popen(['git', 'config', '--unset', 'remote.origin.fetch'], stdout=PIPE,
        stderr=STDOUT, cwd=path).communicate()
    Popen(['git', 'config', 'user.email', 'someuser@chromium.org'], stdout=PIPE,
        stderr=STDOUT, cwd=path).communicate()
    Popen(['git', 'config', 'user.name', 'Some User'], stdout=PIPE,
        stderr=STDOUT, cwd=path).communicate()
    return True

  def _GetAskForDataCallback(self, expected_prompt, return_value):
    def AskForData(prompt, options):
      self.assertEquals(prompt, expected_prompt)
      return return_value
    return AskForData

  def setUp(self):
    TestCaseUtils.setUp(self)
    unittest.TestCase.setUp(self)
    self.url = 'git://foo'
    # The .git suffix allows gclient_scm to recognize the dir as a git repo
    # when cloning it locally
    self.root_dir = tempfile.mkdtemp('.git')
    self.relpath = '.'
    self.base_path = join(self.root_dir, self.relpath)
    self.enabled = self.CreateGitRepo(self.sample_git_import, self.base_path)
    StdoutCheck.setUp(self)
    self._original_GitBinaryExists = gclient_scm.GitWrapper.BinaryExists
    self._original_SVNBinaryExists = gclient_scm.SVNWrapper.BinaryExists
    gclient_scm.GitWrapper.BinaryExists = staticmethod(lambda : True)
    gclient_scm.SVNWrapper.BinaryExists = staticmethod(lambda : True)

  def tearDown(self):
    try:
      rmtree(self.root_dir)
      StdoutCheck.tearDown(self)
      TestCaseUtils.tearDown(self)
      unittest.TestCase.tearDown(self)
    finally:
      # TODO(maruel): Use auto_stub.TestCase.
      gclient_scm.GitWrapper.BinaryExists = self._original_GitBinaryExists
      gclient_scm.SVNWrapper.BinaryExists = self._original_SVNBinaryExists


class ManagedGitWrapperTestCase(BaseGitWrapperTestCase):

  def testRevertMissing(self):
    if not self.enabled:
      return
    options = self.Options()
    file_path = join(self.base_path, 'a')
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.update(options, None, file_list)
    gclient_scm.os.remove(file_path)
    file_list = []
    scm.revert(options, self.args, file_list)
    self.assertEquals(file_list, [file_path])
    file_list = []
    scm.diff(options, self.args, file_list)
    self.assertEquals(file_list, [])
    sys.stdout.close()

  def testRevertNone(self):
    if not self.enabled:
      return
    options = self.Options()
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.update(options, None, file_list)
    file_list = []
    scm.revert(options, self.args, file_list)
    self.assertEquals(file_list, [])
    self.assertEquals(scm.revinfo(options, self.args, None),
                      'a7142dc9f0009350b96a11f372b6ea658592aa95')
    sys.stdout.close()

  def testRevertModified(self):
    if not self.enabled:
      return
    options = self.Options()
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.update(options, None, file_list)
    file_path = join(self.base_path, 'a')
    open(file_path, 'a').writelines('touched\n')
    file_list = []
    scm.revert(options, self.args, file_list)
    self.assertEquals(file_list, [file_path])
    file_list = []
    scm.diff(options, self.args, file_list)
    self.assertEquals(file_list, [])
    self.assertEquals(scm.revinfo(options, self.args, None),
                      'a7142dc9f0009350b96a11f372b6ea658592aa95')
    sys.stdout.close()

  def testRevertNew(self):
    if not self.enabled:
      return
    options = self.Options()
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.update(options, None, file_list)
    file_path = join(self.base_path, 'c')
    f = open(file_path, 'w')
    f.writelines('new\n')
    f.close()
    Popen(['git', 'add', 'c'], stdout=PIPE,
          stderr=STDOUT, cwd=self.base_path).communicate()
    file_list = []
    scm.revert(options, self.args, file_list)
    self.assertEquals(file_list, [file_path])
    file_list = []
    scm.diff(options, self.args, file_list)
    self.assertEquals(file_list, [])
    self.assertEquals(scm.revinfo(options, self.args, None),
                      'a7142dc9f0009350b96a11f372b6ea658592aa95')
    sys.stdout.close()

  def testStatusNew(self):
    if not self.enabled:
      return
    options = self.Options()
    file_path = join(self.base_path, 'a')
    open(file_path, 'a').writelines('touched\n')
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.status(options, self.args, file_list)
    self.assertEquals(file_list, [file_path])
    self.checkstdout(
        ('\n________ running \'git diff --name-status '
         '069c602044c5388d2d15c3f875b057c852003458\' in \'%s\'\nM\ta\n') %
            join(self.root_dir, '.'))

  def testStatus2New(self):
    if not self.enabled:
      return
    options = self.Options()
    expected_file_list = []
    for f in ['a', 'b']:
      file_path = join(self.base_path, f)
      open(file_path, 'a').writelines('touched\n')
      expected_file_list.extend([file_path])
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.status(options, self.args, file_list)
    expected_file_list = [join(self.base_path, x) for x in ['a', 'b']]
    self.assertEquals(sorted(file_list), expected_file_list)
    self.checkstdout(
        ('\n________ running \'git diff --name-status '
         '069c602044c5388d2d15c3f875b057c852003458\' in \'%s\'\nM\ta\nM\tb\n') %
            join(self.root_dir, '.'))

  def testUpdateUpdate(self):
    if not self.enabled:
      return
    options = self.Options()
    expected_file_list = [join(self.base_path, x) for x in ['a', 'b']]
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.update(options, (), file_list)
    self.assertEquals(file_list, expected_file_list)
    self.assertEquals(scm.revinfo(options, (), None),
                      'a7142dc9f0009350b96a11f372b6ea658592aa95')
    sys.stdout.close()

  def testUpdateMerge(self):
    if not self.enabled:
      return
    options = self.Options()
    options.merge = True
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    scm._Run(['checkout', '-q', 'feature'], options)
    rev = scm.revinfo(options, (), None)
    file_list = []
    scm.update(options, (), file_list)
    self.assertEquals(file_list, [join(self.base_path, x)
                                  for x in ['a', 'b', 'c']])
    # The actual commit that is created is unstable, so we verify its tree and
    # parents instead.
    self.assertEquals(scm._Capture(['rev-parse', 'HEAD:']),
                      'd2e35c10ac24d6c621e14a1fcadceb533155627d')
    self.assertEquals(scm._Capture(['rev-parse', 'HEAD^1']), rev)
    self.assertEquals(scm._Capture(['rev-parse', 'HEAD^2']),
                      scm._Capture(['rev-parse', 'origin/master']))
    sys.stdout.close()

  def testUpdateRebase(self):
    if not self.enabled:
      return
    options = self.Options()
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    scm._Run(['checkout', '-q', 'feature'], options)
    file_list = []
    # Fake a 'y' key press.
    scm._AskForData = self._GetAskForDataCallback(
        'Cannot fast-forward merge, attempt to rebase? '
        '(y)es / (q)uit / (s)kip : ', 'y')
    scm.update(options, (), file_list)
    self.assertEquals(file_list, [join(self.base_path, x)
                                  for x in ['a', 'b', 'c']])
    # The actual commit that is created is unstable, so we verify its tree and
    # parent instead.
    self.assertEquals(scm._Capture(['rev-parse', 'HEAD:']),
                      'd2e35c10ac24d6c621e14a1fcadceb533155627d')
    self.assertEquals(scm._Capture(['rev-parse', 'HEAD^']),
                      scm._Capture(['rev-parse', 'origin/master']))
    sys.stdout.close()

  def testUpdateReset(self):
    if not self.enabled:
      return
    options = self.Options()
    options.reset = True

    dir_path = join(self.base_path, 'c')
    os.mkdir(dir_path)
    open(join(dir_path, 'nested'), 'w').writelines('new\n')

    file_path = join(self.base_path, 'file')
    open(file_path, 'w').writelines('new\n')

    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.update(options, (), file_list)
    self.assert_(gclient_scm.os.path.isdir(dir_path))
    self.assert_(gclient_scm.os.path.isfile(file_path))
    sys.stdout.close()

  def testUpdateResetDeleteUnversionedTrees(self):
    if not self.enabled:
      return
    options = self.Options()
    options.reset = True
    options.delete_unversioned_trees = True

    dir_path = join(self.base_path, 'dir')
    os.mkdir(dir_path)
    open(join(dir_path, 'nested'), 'w').writelines('new\n')

    file_path = join(self.base_path, 'file')
    open(file_path, 'w').writelines('new\n')

    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    scm.update(options, (), file_list)
    self.assert_(not gclient_scm.os.path.isdir(dir_path))
    self.assert_(gclient_scm.os.path.isfile(file_path))
    sys.stdout.close()

  def testUpdateUnstagedConflict(self):
    if not self.enabled:
      return
    options = self.Options()
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_path = join(self.base_path, 'b')
    open(file_path, 'w').writelines('conflict\n')
    try:
      scm.update(options, (), [])
      self.fail()
    except (gclient_scm.gclient_utils.Error, subprocess2.CalledProcessError):
      # The exact exception text varies across git versions so it's not worth
      # verifying it. It's fine as long as it throws.
      pass
    # Manually flush stdout since we can't verify it's content accurately across
    # git versions.
    sys.stdout.getvalue()
    sys.stdout.close()

  def testUpdateConflict(self):
    if not self.enabled:
      return
    options = self.Options()
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_path = join(self.base_path, 'b')
    open(file_path, 'w').writelines('conflict\n')
    scm._Run(['commit', '-am', 'test'], options)
    scm._AskForData = self._GetAskForDataCallback(
        'Cannot fast-forward merge, attempt to rebase? '
        '(y)es / (q)uit / (s)kip : ', 'y')
    exception = ('Conflict while rebasing this branch.\n'
                 'Fix the conflict and run gclient again.\n'
                 'See \'man git-rebase\' for details.\n')
    self.assertRaisesError(exception, scm.update, options, (), [])
    exception = ('\n____ . at refs/remotes/origin/master\n'
                 '\tYou have unstaged changes.\n'
                 '\tPlease commit, stash, or reset.\n')
    self.assertRaisesError(exception, scm.update, options, (), [])
    sys.stdout.close()

  def testRevinfo(self):
    if not self.enabled:
      return
    options = self.Options()
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    rev_info = scm.revinfo(options, (), None)
    self.assertEquals(rev_info, '069c602044c5388d2d15c3f875b057c852003458')


class ManagedGitWrapperTestCaseMox(BaseTestCase):
  class OptionsObject(object):
    def __init__(self, verbose=False, revision=None, force=False):
      self.verbose = verbose
      self.revision = revision
      self.deps_os = None
      self.force = force
      self.reset = False
      self.nohooks = False
      # TODO(maruel): Test --jobs > 1.
      self.jobs = 1

  def Options(self, *args, **kwargs):
    return self.OptionsObject(*args, **kwargs)

  def checkstdout(self, expected):
    value = sys.stdout.getvalue()
    sys.stdout.close()
    # pylint: disable=E1101
    self.assertEquals(expected, strip_timestamps(value))

  def setUp(self):
    BaseTestCase.setUp(self)
    self.fake_hash_1 = 't0ta11yf4k3'
    self.fake_hash_2 = '3v3nf4k3r'
    self.url = 'git://foo'
    self.root_dir = '/tmp' if sys.platform != 'win32' else 't:\\tmp'
    self.relpath = 'fake'
    self.base_path = os.path.join(self.root_dir, self.relpath)
    self.backup_base_path = os.path.join(self.root_dir,
                                         'old_%s.git' % self.relpath)

  def tearDown(self):
    BaseTestCase.tearDown(self)

  def testGetUsableRevGit(self):
    # pylint: disable=E1101
    options = self.Options(verbose=True)

    self.mox.StubOutWithMock(gclient_scm.scm.GIT, 'IsValidRevision', True)
    gclient_scm.scm.GIT.IsValidRevision(cwd=self.base_path, rev=self.fake_hash_1
        ).AndReturn(True)

    self.mox.StubOutWithMock(gclient_scm.scm.GIT, 'IsGitSvn', True)
    gclient_scm.scm.GIT.IsGitSvn(cwd=self.base_path).MultipleTimes(
        ).AndReturn(False)

    gclient_scm.scm.os.path.isdir(self.base_path).AndReturn(True)
    gclient_scm.os.path.isdir(self.base_path).AndReturn(True)

    self.mox.ReplayAll()

    git_scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                    relpath=self.relpath)
    # A [fake] git sha1 with a git repo should work (this is in the case that
    # the LKGR gets flipped to git sha1's some day).
    self.assertEquals(git_scm.GetUsableRev(self.fake_hash_1, options),
                      self.fake_hash_1)
    # An SVN rev with an existing purely git repo should raise an exception.
    self.assertRaises(gclient_scm.gclient_utils.Error,
                      git_scm.GetUsableRev, '1', options)

  def testGetUsableRevGitSvn(self):
    # pylint: disable=E1101
    options = self.Options()
    too_big = str(1e7)

    # Pretend like the git-svn repo's HEAD is at r2.
    self.mox.StubOutWithMock(gclient_scm.scm.GIT, 'GetGitSvnHeadRev', True)
    gclient_scm.scm.GIT.GetGitSvnHeadRev(cwd=self.base_path).MultipleTimes(
        ).AndReturn(2)

    self.mox.StubOutWithMock(
        gclient_scm.scm.GIT, 'GetBlessedSha1ForSvnRev', True)
    # r1 -> first fake hash, r3 -> second fake hash.
    gclient_scm.scm.GIT.GetBlessedSha1ForSvnRev(cwd=self.base_path, rev='1'
        ).AndReturn(self.fake_hash_1)
    gclient_scm.scm.GIT.GetBlessedSha1ForSvnRev(cwd=self.base_path, rev='3'
        ).MultipleTimes().AndReturn(self.fake_hash_2)

    # Ensure that we call git svn fetch if our LKGR is > the git-svn HEAD rev.
    self.mox.StubOutWithMock(gclient_scm.GitWrapper, '_Fetch', True)
    self.mox.StubOutWithMock(gclient_scm.scm.GIT, 'Capture', True)
    gclient_scm.scm.GIT.Capture(['config', '--get', 'svn-remote.svn.fetch'],
                                cwd=self.base_path).AndReturn('blah')
    # pylint: disable=E1120
    gclient_scm.scm.GIT.Capture(['svn', 'fetch'], cwd=self.base_path)
    error = subprocess2.CalledProcessError(1, 'cmd', '/cwd', 'stdout', 'stderr')
    gclient_scm.scm.GIT.Capture(['config', '--get', 'svn-remote.svn.fetch'],
                                cwd=self.base_path).AndRaise(error)
    gclient_scm.GitWrapper._Fetch(options)
    gclient_scm.scm.GIT.Capture(['svn', 'fetch'], cwd=self.base_path)
    gclient_scm.GitWrapper._Fetch(options)

    self.mox.StubOutWithMock(gclient_scm.scm.GIT, 'IsGitSvn', True)
    gclient_scm.scm.GIT.IsGitSvn(cwd=self.base_path).MultipleTimes(
        ).AndReturn(True)

    self.mox.StubOutWithMock(gclient_scm.scm.GIT, 'IsValidRevision', True)
    gclient_scm.scm.GIT.IsValidRevision(cwd=self.base_path, rev=self.fake_hash_1
        ).AndReturn(True)
    gclient_scm.scm.GIT.IsValidRevision(cwd=self.base_path, rev=too_big
        ).MultipleTimes(2).AndReturn(False)

    gclient_scm.os.path.isdir(self.base_path).AndReturn(False)
    gclient_scm.os.path.isdir(self.base_path).MultipleTimes().AndReturn(True)

    self.mox.ReplayAll()

    git_svn_scm = self._scm_wrapper(url=self.url, root_dir=self.root_dir,
                                    relpath=self.relpath)
    # Without an existing checkout, this should fail.
    # TODO(dbeam) Fix this. http://crbug.com/109184
    self.assertRaises(gclient_scm.gclient_utils.Error,
                      git_svn_scm.GetUsableRev, '1', options)
    # Given an SVN revision with a git-svn checkout, it should be translated to
    # a git sha1 and be usable.
    self.assertEquals(git_svn_scm.GetUsableRev('1', options),
                      self.fake_hash_1)
    # Our fake HEAD rev is r2, so this should call git fetch and git svn fetch
    # to get more revs (pymox will complain if this doesn't happen). We mock an
    # optimized checkout the first time, so this run should call git fetch.
    self.assertEquals(git_svn_scm.GetUsableRev('3', options),
                      self.fake_hash_2)
    # The time we pretend we're not optimized, so no git fetch should fire.
    self.assertEquals(git_svn_scm.GetUsableRev('3', options),
                      self.fake_hash_2)
    # Given a git sha1 with a git-svn checkout, it should be used as is.
    self.assertEquals(git_svn_scm.GetUsableRev(self.fake_hash_1, options),
                      self.fake_hash_1)
    # We currently check for seemingly valid SVN revisions by assuming 6 digit
    # numbers, so assure that numeric revs >= 1000000 don't work.
    self.assertRaises(gclient_scm.gclient_utils.Error,
                      git_svn_scm.GetUsableRev, too_big, options)

  def testUpdateNoDotGit(self):
    options = self.Options()

    gclient_scm.os.path.isdir(
        os.path.join(self.base_path, '.git', 'hooks')).AndReturn(False)
    gclient_scm.os.path.exists(self.backup_base_path).AndReturn(False)
    gclient_scm.os.path.exists(self.base_path).AndReturn(True)
    gclient_scm.os.path.isdir(self.base_path).AndReturn(True)
    gclient_scm.os.path.exists(os.path.join(self.base_path, '.git')
                               ).AndReturn(False)
    self.mox.StubOutWithMock(gclient_scm.GitWrapper, '_Clone', True)
    # pylint: disable=E1120
    gclient_scm.GitWrapper._Clone('refs/remotes/origin/master', self.url,
                                  options)
    self.mox.StubOutWithMock(gclient_scm.subprocess2, 'check_output', True)
    gclient_scm.subprocess2.check_output(
        ['git', 'ls-files'], cwd=self.base_path,
        env=gclient_scm.scm.GIT.ApplyEnvVars({}), stderr=-1,).AndReturn('')
    gclient_scm.subprocess2.check_output(
        ['git', 'rev-parse', '--verify', 'HEAD'],
        cwd=self.base_path,
        env=gclient_scm.scm.GIT.ApplyEnvVars({}),
        stderr=-1,
        ).AndReturn('')

    self.mox.ReplayAll()
    scm = self._scm_wrapper(url=self.url, root_dir=self.root_dir,
                            relpath=self.relpath)
    scm.update(options, None, [])
    self.checkstdout('\n')

  def testUpdateConflict(self):
    options = self.Options()

    gclient_scm.os.path.isdir(
        os.path.join(self.base_path, '.git', 'hooks')).AndReturn(False)
    gclient_scm.os.path.exists(self.backup_base_path).AndReturn(False)
    gclient_scm.os.path.exists(self.base_path).AndReturn(True)
    gclient_scm.os.path.isdir(self.base_path).AndReturn(True)
    gclient_scm.os.path.exists(os.path.join(self.base_path, '.git')
                               ).AndReturn(False)
    self.mox.StubOutWithMock(gclient_scm.GitWrapper, '_Clone', True)
    # pylint: disable=E1120
    gclient_scm.GitWrapper._Clone(
        'refs/remotes/origin/master', self.url, options
    ).AndRaise(gclient_scm.subprocess2.CalledProcessError(None, None, None,
                                                          None, None))
    self.mox.StubOutWithMock(gclient_scm.GitWrapper, '_DeleteOrMove', True)
    gclient_scm.GitWrapper._DeleteOrMove(False)
    gclient_scm.GitWrapper._Clone('refs/remotes/origin/master', self.url,
                                  options)
    self.mox.StubOutWithMock(gclient_scm.subprocess2, 'check_output', True)
    gclient_scm.subprocess2.check_output(
        ['git', 'ls-files'], cwd=self.base_path,
        env=gclient_scm.scm.GIT.ApplyEnvVars({}), stderr=-1,).AndReturn('')
    gclient_scm.subprocess2.check_output(
        ['git', 'rev-parse', '--verify', 'HEAD'],
        cwd=self.base_path,
        env=gclient_scm.scm.GIT.ApplyEnvVars({}),
        stderr=-1,
        ).AndReturn('')

    self.mox.ReplayAll()
    scm = self._scm_wrapper(url=self.url, root_dir=self.root_dir,
                            relpath=self.relpath)
    scm.update(options, None, [])
    self.checkstdout('\n')


class UnmanagedGitWrapperTestCase(BaseGitWrapperTestCase):
  def checkInStdout(self, expected):
    value = sys.stdout.getvalue()
    sys.stdout.close()
    # pylint: disable=E1101
    self.assertIn(expected, value)

  def checkNotInStdout(self, expected):
    value = sys.stdout.getvalue()
    sys.stdout.close()
    # pylint: disable=E1101
    self.assertNotIn(expected, value)

  def getCurrentBranch(self):
    # Returns name of current branch or HEAD for detached HEAD
    branch = gclient_scm.scm.GIT.Capture(['rev-parse', '--abbrev-ref', 'HEAD'],
                                          cwd=self.base_path)
    if branch == 'HEAD':
      return None
    return branch

  def testUpdateClone(self):
    if not self.enabled:
      return
    options = self.Options()

    origin_root_dir = self.root_dir
    self.root_dir = tempfile.mkdtemp()
    self.relpath = '.'
    self.base_path = join(self.root_dir, self.relpath)

    scm = gclient_scm.CreateSCM(url=origin_root_dir,
                                root_dir=self.root_dir,
                                relpath=self.relpath)

    expected_file_list = [join(self.base_path, "a"),
                          join(self.base_path, "b")]
    file_list = []
    options.revision = 'unmanaged'
    scm.update(options, (), file_list)

    self.assertEquals(file_list, expected_file_list)
    self.assertEquals(scm.revinfo(options, (), None),
                      '069c602044c5388d2d15c3f875b057c852003458')
    # indicates detached HEAD
    self.assertEquals(self.getCurrentBranch(), None)
    self.checkInStdout(
      'Checked out refs/remotes/origin/master to a detached HEAD')

    rmtree(origin_root_dir)

  def testUpdateCloneOnCommit(self):
    if not self.enabled:
      return
    options = self.Options()

    origin_root_dir = self.root_dir
    self.root_dir = tempfile.mkdtemp()
    self.relpath = '.'
    self.base_path = join(self.root_dir, self.relpath)
    url_with_commit_ref = origin_root_dir +\
                          '@a7142dc9f0009350b96a11f372b6ea658592aa95'

    scm = gclient_scm.CreateSCM(url=url_with_commit_ref,
                                root_dir=self.root_dir,
                                relpath=self.relpath)

    expected_file_list = [join(self.base_path, "a"),
                          join(self.base_path, "b")]
    file_list = []
    options.revision = 'unmanaged'
    scm.update(options, (), file_list)

    self.assertEquals(file_list, expected_file_list)
    self.assertEquals(scm.revinfo(options, (), None),
                      'a7142dc9f0009350b96a11f372b6ea658592aa95')
    # indicates detached HEAD
    self.assertEquals(self.getCurrentBranch(), None)
    self.checkInStdout(
      'Checked out a7142dc9f0009350b96a11f372b6ea658592aa95 to a detached HEAD')

    rmtree(origin_root_dir)

  def testUpdateCloneOnBranch(self):
    if not self.enabled:
      return
    options = self.Options()

    origin_root_dir = self.root_dir
    self.root_dir = tempfile.mkdtemp()
    self.relpath = '.'
    self.base_path = join(self.root_dir, self.relpath)
    url_with_branch_ref = origin_root_dir + '@feature'

    scm = gclient_scm.CreateSCM(url=url_with_branch_ref,
                                root_dir=self.root_dir,
                                relpath=self.relpath)

    expected_file_list = [join(self.base_path, "a"),
                          join(self.base_path, "b"),
                          join(self.base_path, "c")]
    file_list = []
    options.revision = 'unmanaged'
    scm.update(options, (), file_list)

    self.assertEquals(file_list, expected_file_list)
    self.assertEquals(scm.revinfo(options, (), None),
                      '9a51244740b25fa2ded5252ca00a3178d3f665a9')
    self.assertEquals(self.getCurrentBranch(), 'feature')
    self.checkNotInStdout('Checked out feature to a detached HEAD')

    rmtree(origin_root_dir)

  def testUpdateCloneOnFetchedRemoteBranch(self):
    if not self.enabled:
      return
    options = self.Options()

    origin_root_dir = self.root_dir
    self.root_dir = tempfile.mkdtemp()
    self.relpath = '.'
    self.base_path = join(self.root_dir, self.relpath)
    url_with_branch_ref = origin_root_dir + '@refs/remotes/origin/feature'

    scm = gclient_scm.CreateSCM(url=url_with_branch_ref,
                                root_dir=self.root_dir,
                                relpath=self.relpath)

    expected_file_list = [join(self.base_path, "a"),
                          join(self.base_path, "b"),
                          join(self.base_path, "c")]
    file_list = []
    options.revision = 'unmanaged'
    scm.update(options, (), file_list)

    self.assertEquals(file_list, expected_file_list)
    self.assertEquals(scm.revinfo(options, (), None),
                      '9a51244740b25fa2ded5252ca00a3178d3f665a9')
    # indicates detached HEAD
    self.assertEquals(self.getCurrentBranch(), None)
    self.checkInStdout(
      'Checked out refs/remotes/origin/feature to a detached HEAD')

    rmtree(origin_root_dir)

  def testUpdateCloneOnTrueRemoteBranch(self):
    if not self.enabled:
      return
    options = self.Options()

    origin_root_dir = self.root_dir
    self.root_dir = tempfile.mkdtemp()
    self.relpath = '.'
    self.base_path = join(self.root_dir, self.relpath)
    url_with_branch_ref = origin_root_dir + '@refs/heads/feature'

    scm = gclient_scm.CreateSCM(url=url_with_branch_ref,
                                root_dir=self.root_dir,
                                relpath=self.relpath)

    expected_file_list = [join(self.base_path, "a"),
                          join(self.base_path, "b"),
                          join(self.base_path, "c")]
    file_list = []
    options.revision = 'unmanaged'
    scm.update(options, (), file_list)

    self.assertEquals(file_list, expected_file_list)
    self.assertEquals(scm.revinfo(options, (), None),
                      '9a51244740b25fa2ded5252ca00a3178d3f665a9')
    # @refs/heads/feature is AKA @refs/remotes/origin/feature in the clone, so
    # should be treated as such by gclient.
    # TODO(mmoss): Though really, we should only allow DEPS to specify branches
    # as they are known in the upstream repo, since the mapping into the local
    # repo can be modified by users (or we might even want to change the gclient
    # defaults at some point). But that will take more work to stop using
    # refs/remotes/ everywhere that we do (and to stop assuming a DEPS ref will
    # always resolve locally, like when passing them to show-ref or rev-list).
    self.assertEquals(self.getCurrentBranch(), None)
    self.checkInStdout(
      'Checked out refs/remotes/origin/feature to a detached HEAD')

    rmtree(origin_root_dir)

  def testUpdateUpdate(self):
    if not self.enabled:
      return
    options = self.Options()
    expected_file_list = []
    scm = gclient_scm.CreateSCM(url=self.url, root_dir=self.root_dir,
                                relpath=self.relpath)
    file_list = []
    options.revision = 'unmanaged'
    scm.update(options, (), file_list)
    self.assertEquals(file_list, expected_file_list)
    self.assertEquals(scm.revinfo(options, (), None),
                      '069c602044c5388d2d15c3f875b057c852003458')
    self.checkstdout('________ unmanaged solution; skipping .\n')


if __name__ == '__main__':
  level = logging.DEBUG if '-v' in sys.argv else logging.FATAL
  logging.basicConfig(
      level=level,
      format='%(asctime).19s %(levelname)s %(filename)s:'
             '%(lineno)s %(message)s')
  unittest.main()

# vim: ts=2:sw=2:tw=80:et:
