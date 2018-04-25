#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for gclient.py.

See gclient_smoketest.py for integration tests.
"""

import Queue
import copy
import logging
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import gclient
import gclient_utils
from testing_support import trial_dir


def write(filename, content):
  """Writes the content of a file and create the directories as needed."""
  filename = os.path.abspath(filename)
  dirname = os.path.dirname(filename)
  if not os.path.isdir(dirname):
    os.makedirs(dirname)
  with open(filename, 'w') as f:
    f.write(content)


class SCMMock(object):
  def __init__(self, unit_test, url):
    self.unit_test = unit_test
    self.url = url

  def RunCommand(self, command, options, args, file_list):
    self.unit_test.assertEquals('None', command)
    self.unit_test.processed.put(self.url)

  def FullUrlForRelativeUrl(self, url):
    return self.url + url

  # pylint: disable=R0201
  def DoesRemoteURLMatch(self, _):
    return True

  def GetActualRemoteURL(self, _):
    return self.url


class GclientTest(trial_dir.TestCase):
  def setUp(self):
    super(GclientTest, self).setUp()
    self.processed = Queue.Queue()
    self.previous_dir = os.getcwd()
    os.chdir(self.root_dir)
    # Manual mocks.
    self._old_createscm = gclient.gclient_scm.CreateSCM
    gclient.gclient_scm.CreateSCM = self._createscm
    self._old_sys_stdout = sys.stdout
    sys.stdout = gclient.gclient_utils.MakeFileAutoFlush(sys.stdout)
    sys.stdout = gclient.gclient_utils.MakeFileAnnotated(sys.stdout)

  def tearDown(self):
    self.assertEquals([], self._get_processed())
    gclient.gclient_scm.CreateSCM = self._old_createscm
    sys.stdout = self._old_sys_stdout
    os.chdir(self.previous_dir)
    super(GclientTest, self).tearDown()

  def _createscm(self, parsed_url, root_dir, name, out_fh=None, out_cb=None):
    self.assertTrue(parsed_url.startswith('svn://example.com/'), parsed_url)
    self.assertTrue(root_dir.startswith(self.root_dir), root_dir)
    return SCMMock(self, parsed_url)

  def testDependencies(self):
    self._dependencies('1')

  def testDependenciesJobs(self):
    self._dependencies('1000')

  def _dependencies(self, jobs):
    """Verifies that dependencies are processed in the right order.

    e.g. if there is a dependency 'src' and another 'src/third_party/bar', that
    bar isn't fetched until 'src' is done.
    Also test that a From() dependency should not be processed when it is listed
    as a requirement.

    Args:
      |jobs| is the number of parallel jobs simulated.
    """
    parser = gclient.OptionParser()
    options, args = parser.parse_args(['--jobs', jobs])
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo" },\n'
        '  { "name": "bar", "url": "svn://example.com/bar" },\n'
        '  { "name": "bar/empty", "url": "svn://example.com/bar_empty" },\n'
        ']')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "foo/dir1": "/dir1",\n'
        # This one will depend on dir1/dir2 in bar.
        '  "foo/dir1/dir2/dir3": "/dir1/dir2/dir3",\n'
        '  "foo/dir1/dir2/dir3/dir4": "/dir1/dir2/dir3/dir4",\n'
        '  "foo/dir1/dir2/dir5/dir6":\n'
        '    From("foo/dir1/dir2/dir3/dir4", "foo/dir1/dir2"),\n'
        '}')
    write(
        os.path.join('bar', 'DEPS'),
        'deps = {\n'
        # There is two foo/dir1/dir2. This one is fetched as bar/dir1/dir2.
        '  "foo/dir1/dir2": "/dir1/dir2",\n'
        '}')
    write(
        os.path.join('bar/empty', 'DEPS'),
        'deps = {\n'
        '}')
    # Test From()
    write(
        os.path.join('foo/dir1/dir2/dir3/dir4', 'DEPS'),
        'deps = {\n'
        # This one should not be fetched or set as a requirement.
        '  "foo/dir1/dir2/dir5": "svn://example.com/x",\n'
        # This foo/dir1/dir2 points to a different url than the one in bar.
        '  "foo/dir1/dir2": "/dir1/another",\n'
        '}')

    obj = gclient.GClient.LoadCurrentConfig(options)
    self._check_requirements(obj.dependencies[0], {})
    self._check_requirements(obj.dependencies[1], {})
    obj.RunOnDeps('None', args)
    actual = self._get_processed()
    first_3 = [
        'svn://example.com/bar',
        'svn://example.com/bar_empty',
        'svn://example.com/foo',
    ]
    if jobs != 1:
      # We don't care of the ordering of these items except that bar must be
      # before bar/empty.
      self.assertTrue(
          actual.index('svn://example.com/bar') <
          actual.index('svn://example.com/bar_empty'))
      self.assertEquals(first_3, sorted(actual[0:3]))
    else:
      self.assertEquals(first_3, actual[0:3])
    self.assertEquals(
        [
          'svn://example.com/foo/dir1',
          'svn://example.com/bar/dir1/dir2',
          'svn://example.com/foo/dir1/dir2/dir3',
          'svn://example.com/foo/dir1/dir2/dir3/dir4',
          'svn://example.com/foo/dir1/dir2/dir3/dir4/dir1/another',
        ],
        actual[3:])

    self.assertEquals(3, len(obj.dependencies))
    self.assertEquals('foo', obj.dependencies[0].name)
    self.assertEquals('bar', obj.dependencies[1].name)
    self.assertEquals('bar/empty', obj.dependencies[2].name)
    self._check_requirements(
        obj.dependencies[0],
        {
          'foo/dir1': ['bar', 'bar/empty', 'foo'],
          'foo/dir1/dir2/dir3':
              ['bar', 'bar/empty', 'foo', 'foo/dir1', 'foo/dir1/dir2'],
          'foo/dir1/dir2/dir3/dir4':
              [ 'bar', 'bar/empty', 'foo', 'foo/dir1', 'foo/dir1/dir2',
                'foo/dir1/dir2/dir3'],
          'foo/dir1/dir2/dir5/dir6':
              [ 'bar', 'bar/empty', 'foo', 'foo/dir1', 'foo/dir1/dir2',
                'foo/dir1/dir2/dir3/dir4'],
        })
    self._check_requirements(
        obj.dependencies[1],
        {
          'foo/dir1/dir2': ['bar', 'bar/empty', 'foo', 'foo/dir1'],
        })
    self._check_requirements(
        obj.dependencies[2],
        {})
    self._check_requirements(
        obj,
        {
          'foo': [],
          'bar': [],
          'bar/empty': ['bar'],
        })

  def _check_requirements(self, solution, expected):
    for dependency in solution.dependencies:
      e = expected.pop(dependency.name)
      a = sorted(dependency.requirements)
      self.assertEquals(e, a, (dependency.name, e, a))
    self.assertEquals({}, expected)

  def _get_processed(self):
    """Retrieves the item in the order they were processed."""
    items = []
    try:
      while True:
        items.append(self.processed.get_nowait())
    except Queue.Empty:
      pass
    return items

  def testAutofix(self):
    # Invalid urls causes pain when specifying requirements. Make sure it's
    # auto-fixed.
    d = gclient.Dependency(
        None, 'name', 'proto://host/path/@revision', None, None, None, None,
        None, '', True)
    self.assertEquals('proto://host/path@revision', d.url)

  def testStr(self):
    parser = gclient.OptionParser()
    options, _ = parser.parse_args([])
    obj = gclient.GClient('foo', options)
    obj.add_dependencies_and_close(
        [
          gclient.Dependency(
            obj, 'foo', 'url', None, None, None, None, None, 'DEPS', True),
          gclient.Dependency(
            obj, 'bar', 'url', None, None, None, None, None, 'DEPS', True),
        ],
        [])
    obj.dependencies[0].add_dependencies_and_close(
        [
          gclient.Dependency(
            obj.dependencies[0], 'foo/dir1', 'url', None, None, None, None,
            None, 'DEPS', True),
          gclient.Dependency(
            obj.dependencies[0], 'foo/dir2',
            gclient.GClientKeywords.FromImpl('bar'), None, None, None, None,
            None, 'DEPS', True),
          gclient.Dependency(
            obj.dependencies[0], 'foo/dir3',
            gclient.GClientKeywords.FileImpl('url'), None, None, None, None,
            None, 'DEPS', True),
        ],
        [])
    # Make sure __str__() works fine.
    # pylint: disable=W0212
    obj.dependencies[0]._file_list.append('foo')
    str_obj = str(obj)
    self.assertEquals(471, len(str_obj), '%d\n%s' % (len(str_obj), str_obj))

  def testHooks(self):
    topdir = self.root_dir
    gclient_fn = os.path.join(topdir, '.gclient')
    fh = open(gclient_fn, 'w')
    print >> fh, 'solutions = [{"name":"top","url":"svn://example.com/top"}]'
    fh.close()
    subdir_fn = os.path.join(topdir, 'top')
    os.mkdir(subdir_fn)
    deps_fn = os.path.join(subdir_fn, 'DEPS')
    fh = open(deps_fn, 'w')
    hooks = [{'pattern':'.', 'action':['cmd1', 'arg1', 'arg2']}]
    print >> fh, 'hooks = %s' % repr(hooks)
    fh.close()

    fh = open(os.path.join(subdir_fn, 'fake.txt'), 'w')
    print >> fh, 'bogus content'
    fh.close()

    os.chdir(topdir)

    parser = gclient.OptionParser()
    options, _ = parser.parse_args([])
    options.force = True
    client = gclient.GClient.LoadCurrentConfig(options)
    work_queue = gclient_utils.ExecutionQueue(options.jobs, None, False)
    for s in client.dependencies:
      work_queue.enqueue(s)
    work_queue.flush({}, None, [], options=options)
    self.assertEqual(client.GetHooks(options), [x['action'] for x in hooks])

  def testCustomHooks(self):
    topdir = self.root_dir
    gclient_fn = os.path.join(topdir, '.gclient')
    fh = open(gclient_fn, 'w')
    extra_hooks = [{'name': 'append', 'pattern':'.', 'action':['supercmd']}]
    print >> fh, ('solutions = [{"name":"top","url":"svn://example.com/top",'
        '"custom_hooks": %s},' ) % repr(extra_hooks + [{'name': 'skip'}])
    print >> fh, '{"name":"bottom","url":"svn://example.com/bottom"}]'
    fh.close()
    subdir_fn = os.path.join(topdir, 'top')
    os.mkdir(subdir_fn)
    deps_fn = os.path.join(subdir_fn, 'DEPS')
    fh = open(deps_fn, 'w')
    hooks = [{'pattern':'.', 'action':['cmd1', 'arg1', 'arg2']}]
    hooks.append({'pattern':'.', 'action':['cmd2', 'arg1', 'arg2']})
    skip_hooks = [
        {'name': 'skip', 'pattern':'.', 'action':['cmd3', 'arg1', 'arg2']}]
    skip_hooks.append(
        {'name': 'skip', 'pattern':'.', 'action':['cmd4', 'arg1', 'arg2']})
    print >> fh, 'hooks = %s' % repr(hooks + skip_hooks)
    fh.close()

    # Make sure the custom hooks for that project don't affect the next one.
    subdir_fn = os.path.join(topdir, 'bottom')
    os.mkdir(subdir_fn)
    deps_fn = os.path.join(subdir_fn, 'DEPS')
    fh = open(deps_fn, 'w')
    sub_hooks = [{'pattern':'.', 'action':['response1', 'yes1', 'yes2']}]
    sub_hooks.append(
        {'name': 'skip', 'pattern':'.', 'action':['response2', 'yes', 'sir']})
    print >> fh, 'hooks = %s' % repr(sub_hooks)
    fh.close()

    fh = open(os.path.join(subdir_fn, 'fake.txt'), 'w')
    print >> fh, 'bogus content'
    fh.close()

    os.chdir(topdir)

    parser = gclient.OptionParser()
    options, _ = parser.parse_args([])
    options.force = True
    client = gclient.GClient.LoadCurrentConfig(options)
    work_queue = gclient_utils.ExecutionQueue(options.jobs, None, False)
    for s in client.dependencies:
      work_queue.enqueue(s)
    work_queue.flush({}, None, [], options=options)
    self.assertEqual(client.GetHooks(options),
                     [x['action'] for x in hooks + extra_hooks + sub_hooks])

  def testTargetOS(self):
    """Verifies that specifying a target_os pulls in all relevant dependencies.

    The target_os variable allows specifying the name of an additional OS which
    should be considered when selecting dependencies from a DEPS' deps_os. The
    value will be appended to the _enforced_os tuple.
    """

    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo",\n'
        '    "url": "svn://example.com/foo",\n'
        '  }]\n'
        'target_os = ["baz"]')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "foo/dir1": "/dir1",'
        '}\n'
        'deps_os = {\n'
        '  "unix": { "foo/dir2": "/dir2", },\n'
        '  "baz": { "foo/dir3": "/dir3", },\n'
        '}')

    parser = gclient.OptionParser()
    options, _ = parser.parse_args(['--jobs', '1'])
    options.deps_os = "unix"

    obj = gclient.GClient.LoadCurrentConfig(options)
    self.assertEqual(['baz', 'unix'], sorted(obj.enforced_os))

  def testTargetOsWithTargetOsOnly(self):
    """Verifies that specifying a target_os and target_os_only pulls in only
    the relevant dependencies.

    The target_os variable allows specifying the name of an additional OS which
    should be considered when selecting dependencies from a DEPS' deps_os. With
    target_os_only also set, the _enforced_os tuple will be set to only the
    target_os value.
    """

    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo",\n'
        '    "url": "svn://example.com/foo",\n'
        '  }]\n'
        'target_os = ["baz"]\n'
        'target_os_only = True')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "foo/dir1": "/dir1",'
        '}\n'
        'deps_os = {\n'
        '  "unix": { "foo/dir2": "/dir2", },\n'
        '  "baz": { "foo/dir3": "/dir3", },\n'
        '}')

    parser = gclient.OptionParser()
    options, _ = parser.parse_args(['--jobs', '1'])
    options.deps_os = "unix"

    obj = gclient.GClient.LoadCurrentConfig(options)
    self.assertEqual(['baz'], sorted(obj.enforced_os))

  def testTargetOsOnlyWithoutTargetOs(self):
    """Verifies that specifying a target_os_only without target_os_only raises
    an exception.
    """

    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo",\n'
        '    "url": "svn://example.com/foo",\n'
        '  }]\n'
        'target_os_only = True')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "foo/dir1": "/dir1",'
        '}\n'
        'deps_os = {\n'
        '  "unix": { "foo/dir2": "/dir2", },\n'
        '}')

    parser = gclient.OptionParser()
    options, _ = parser.parse_args(['--jobs', '1'])
    options.deps_os = "unix"

    exception_raised = False
    try:
      gclient.GClient.LoadCurrentConfig(options)
    except gclient_utils.Error:
      exception_raised = True
    self.assertTrue(exception_raised)

  def testTargetOsInDepsFile(self):
    """Verifies that specifying a target_os value in a DEPS file pulls in all
    relevant dependencies.

    The target_os variable in a DEPS file allows specifying the name of an
    additional OS which should be considered when selecting dependencies from a
    DEPS' deps_os. The value will be appended to the _enforced_os tuple.
    """

    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo",\n'
        '    "url": "svn://example.com/foo",\n'
        '  },\n'
        '  { "name": "bar",\n'
        '    "url": "svn://example.com/bar",\n'
        '  }]\n')
    write(
        os.path.join('foo', 'DEPS'),
        'target_os = ["baz"]\n'
        'deps_os = {\n'
        '  "unix": { "foo/unix": "/unix", },\n'
        '  "baz": { "foo/baz": "/baz", },\n'
        '  "jaz": { "foo/jaz": "/jaz", },\n'
        '}')
    write(
        os.path.join('bar', 'DEPS'),
        'deps_os = {\n'
        '  "unix": { "bar/unix": "/unix", },\n'
        '  "baz": { "bar/baz": "/baz", },\n'
        '  "jaz": { "bar/jaz": "/jaz", },\n'
        '}')

    parser = gclient.OptionParser()
    options, _ = parser.parse_args(['--jobs', '1'])
    options.deps_os = 'unix'

    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    self.assertEqual(['unix'], sorted(obj.enforced_os))
    self.assertEquals(
        [
          'svn://example.com/bar',
          'svn://example.com/bar/unix',
          'svn://example.com/foo',
          'svn://example.com/foo/baz',
          'svn://example.com/foo/unix',
          ],
        sorted(self._get_processed()))

  def testUpdateWithOsDeps(self):
    """Verifies that complicated deps_os constructs result in the
    correct data also with multple operating systems. Also see
    testDepsOsOverrideDepsInDepsFile."""

    test_data = [
      # Tuples of deps, deps_os, os_list and expected_deps.
      (
        # OS doesn't need module.
        {'foo': 'default_foo'},
        {'os1': { 'foo': None } },
        ['os1'],
        {'foo': None}
        ),
      (
        # OS wants a different version of module.
        {'foo': 'default_foo'},
        {'os1': { 'foo': 'os1_foo'} },
        ['os1'],
        {'foo': 'os1_foo'}
        ),
      (
        # OS with no overrides at all.
        {'foo': 'default_foo'},
        {'os1': { 'foo': None } },
        ['os2'],
        {'foo': 'default_foo'}
        ),
      (
        # One OS doesn't need module, one OS wants the default.
        {'foo': 'default_foo'},
        {'os1': { 'foo': None },
         'os2': {}},
        ['os1', 'os2'],
        {'foo': 'default_foo'}
        ),
      (
        # One OS doesn't need module, another OS wants a special version.
        {'foo': 'default_foo'},
        {'os1': { 'foo': None },
         'os2': { 'foo': 'os2_foo'}},
        ['os1', 'os2'],
        {'foo': 'os2_foo'}
        ),
      (
        # One OS wants to add a module.
        {'foo': 'default_foo'},
        {'os1': { 'bar': 'os1_bar' }},
        ['os1'],
        {'foo': 'default_foo',
         'bar': 'os1_bar'}
        ),
      (
        # One OS wants to add a module. One doesn't care.
        {'foo': 'default_foo'},
        {'os1': { 'bar': 'os1_bar' }},
        ['os1', 'os2'],
        {'foo': 'default_foo',
         'bar': 'os1_bar'}
        ),
      (
        # Two OSes want to add a module with the same definition.
        {'foo': 'default_foo'},
        {'os1': { 'bar': 'os12_bar' },
         'os2': { 'bar': 'os12_bar' }},
        ['os1', 'os2'],
        {'foo': 'default_foo',
         'bar': 'os12_bar'}
        ),
      ]
    for deps, deps_os, target_os_list, expected_deps in test_data:
      orig_deps = copy.deepcopy(deps)
      result = gclient.Dependency.MergeWithOsDeps(deps, deps_os, target_os_list)
      self.assertEqual(result, expected_deps)
      self.assertEqual(deps, orig_deps)


  def testLateOverride(self):
    """Verifies expected behavior of LateOverride."""
    url = "git@github.com:dart-lang/spark.git"
    d = gclient.Dependency(None, 'name', 'url',
                           None, None, None, None, None, '', True)
    late_url = d.LateOverride(url)
    self.assertEquals(url, late_url)

  def testDepsOsOverrideDepsInDepsFile(self):
    """Verifies that a 'deps_os' path can override a 'deps' path. Also
    see testUpdateWithOsDeps above.
    """

    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo",\n'
        '    "url": "svn://example.com/foo",\n'
        '  },]\n')
    write(
        os.path.join('foo', 'DEPS'),
        'target_os = ["baz"]\n'
        'deps = {\n'
        '  "foo/src": "/src",\n' # This path is to be overridden by similar path
                                 # in deps_os['unix'].
        '}\n'
        'deps_os = {\n'
        '  "unix": { "foo/unix": "/unix",'
        '            "foo/src": "/src_unix"},\n'
        '  "baz": { "foo/baz": "/baz",\n'
        '           "foo/src": None},\n'
        '  "jaz": { "foo/jaz": "/jaz", },\n'
        '}')

    parser = gclient.OptionParser()
    options, _ = parser.parse_args(['--jobs', '1'])
    options.deps_os = 'unix'

    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    self.assertEqual(['unix'], sorted(obj.enforced_os))
    self.assertEquals(
        [
          'svn://example.com/foo',
          'svn://example.com/foo/baz',
          'svn://example.com/foo/src_unix',
          'svn://example.com/foo/unix',
          ],
        sorted(self._get_processed()))

  def testRecursionOverride(self):
    """Verifies gclient respects the |recursion| var syntax.

    We check several things here:
    - |recursion| = 3 sets recursion on the foo dep to exactly 3
      (we pull /fizz, but not /fuzz)
    - pulling foo/bar at recursion level 1 (in .gclient) is overriden by
      a later pull of foo/bar at recursion level 2 (in the dep tree)
    """
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo" },\n'
        '  { "name": "foo/bar", "url": "svn://example.com/bar" },\n'
          ']')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}\n'
        'recursion = 3')
    write(
        os.path.join('bar', 'DEPS'),
        'deps = {\n'
        '  "baz": "/baz",\n'
        '}')
    write(
        os.path.join('baz', 'DEPS'),
        'deps = {\n'
        '  "fizz": "/fizz",\n'
        '}')
    write(
        os.path.join('fizz', 'DEPS'),
        'deps = {\n'
        '  "fuzz": "/fuzz",\n'
        '}')

    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    self.assertEquals(
        [
          'svn://example.com/foo',
          'svn://example.com/bar',
          'svn://example.com/foo/bar',
          'svn://example.com/foo/bar/baz',
          'svn://example.com/foo/bar/baz/fizz',
        ],
        self._get_processed())

  def testRecursedepsOverride(self):
    """Verifies gclient respects the |recursedeps| var syntax.

    This is what we mean to check here:
    - |recursedeps| = [...] on 2 levels means we pull exactly 3 deps
      (up to /fizz, but not /fuzz)
    - pulling foo/bar with no recursion (in .gclient) is overriden by
      a later pull of foo/bar with recursion (in the dep tree)
    - pulling foo/tar with no recursion (in .gclient) is no recursively
      pulled (taz is left out)
    """
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo" },\n'
        '  { "name": "foo/bar", "url": "svn://example.com/bar" },\n'
        '  { "name": "foo/tar", "url": "svn://example.com/tar" },\n'
          ']')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}\n'
        'recursedeps = ["bar"]')
    write(
        os.path.join('bar', 'DEPS'),
        'deps = {\n'
        '  "baz": "/baz",\n'
        '}\n'
        'recursedeps = ["baz"]')
    write(
        os.path.join('baz', 'DEPS'),
        'deps = {\n'
        '  "fizz": "/fizz",\n'
        '}')
    write(
        os.path.join('fizz', 'DEPS'),
        'deps = {\n'
        '  "fuzz": "/fuzz",\n'
        '}')
    write(
        os.path.join('tar', 'DEPS'),
        'deps = {\n'
        '  "taz": "/taz",\n'
        '}')

    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    self.assertEquals(
        [
          'svn://example.com/foo',
          'svn://example.com/bar',
          'svn://example.com/tar',
          'svn://example.com/foo/bar',
          'svn://example.com/foo/bar/baz',
          'svn://example.com/foo/bar/baz/fizz',
        ],
        self._get_processed())

  def testRecursedepsOverrideWithRelativePaths(self):
    """Verifies gclient respects |recursedeps| with relative paths."""

    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo" },\n'
          ']')
    write(
        os.path.join('foo', 'DEPS'),
        'use_relative_paths = True\n'
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}\n'
        'recursedeps = ["bar"]')
    write(
        os.path.join('bar', 'DEPS'),
        'deps = {\n'
        '  "baz": "/baz",\n'
        '}')
    write(
        os.path.join('baz', 'DEPS'),
        'deps = {\n'
        '  "fizz": "/fizz",\n'
        '}')

    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    self.assertEquals(
        [
          'svn://example.com/foo',
          # use_relative_paths means the following dep evaluates with 'foo'
          # prepended.
          'svn://example.com/foo/bar',
        ],
        self._get_processed())

  def testRecursionOverridesRecursedeps(self):
    """Verifies gclient respects |recursion| over |recursedeps|.

    |recursion| is set in a top-level DEPS file.  That value is meant
    to affect how many subdeps are parsed via recursion.

    |recursedeps| is set in each DEPS file to control whether or not
    to recurse into the immediate next subdep.

    This test verifies that if both syntaxes are mixed in a DEPS file,
    we disable |recursedeps| support and only obey |recursion|.

    Since this setting is evaluated per DEPS file, recursed DEPS
    files will each be re-evaluated according to the per DEPS rules.
    So a DEPS that only contains |recursedeps| could then override any
    previous |recursion| setting.  There is extra processing to ensure
    this does not happen.

    For this test to work correctly, we need to use a DEPS chain that
    only contains recursion controls in the top DEPS file.

    In foo, |recursion| and |recursedeps| are specified.  When we see
    |recursion|, we stop trying to use |recursedeps|.

    There are 2 constructions of DEPS here that are key to this test:

    (1) In foo, if we used |recursedeps| instead of |recursion|, we
        would also pull in bar.  Since bar's DEPS doesn't contain any
        recursion statements, we would stop processing at bar.

    (2) In fizz, if we used |recursedeps| at all, we should pull in
        fuzz.

    We expect to keep going past bar (satisfying 1) and we don't
    expect to pull in fuzz (satisfying 2).
    """
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo" },\n'
        '  { "name": "foo/bar", "url": "svn://example.com/bar" },\n'
          ']')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}\n'
        'recursion = 3\n'
        'recursedeps = ["bar"]')
    write(
        os.path.join('bar', 'DEPS'),
        'deps = {\n'
        '  "baz": "/baz",\n'
        '}')
    write(
        os.path.join('baz', 'DEPS'),
        'deps = {\n'
        '  "fizz": "/fizz",\n'
        '}')
    write(
        os.path.join('fizz', 'DEPS'),
        'deps = {\n'
        '  "fuzz": "/fuzz",\n'
        '}\n'
        'recursedeps = ["fuzz"]')
    write(
        os.path.join('fuzz', 'DEPS'),
        'deps = {\n'
        '  "tar": "/tar",\n'
        '}')

    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    self.assertEquals(
        [
          'svn://example.com/foo',
          'svn://example.com/bar',
          'svn://example.com/foo/bar',
          # Deps after this would have been skipped if we were obeying
          # |recursedeps|.
          'svn://example.com/foo/bar/baz',
          'svn://example.com/foo/bar/baz/fizz',
          # And this dep would have been picked up if we were obeying
          # |recursedeps|.
          # 'svn://example.com/foo/bar/baz/fuzz',
        ],
        self._get_processed())

  def testGitDeps(self):
    """Verifies gclient respects a .DEPS.git deps file.

    Along the way, we also test that if both DEPS and .DEPS.git are present,
    that gclient does not read the DEPS file.  This will reliably catch bugs
    where gclient is always hitting the wrong file (DEPS).
    """
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo",\n'
        '    "deps_file" : ".DEPS.git",\n'
        '  },\n'
          ']')
    write(
        os.path.join('foo', '.DEPS.git'),
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "baz": "/baz",\n'
        '}')

    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    self.assertEquals(
        [
          'svn://example.com/foo',
          'svn://example.com/foo/bar',
        ],
        self._get_processed())

  def testGitDepsFallback(self):
    """Verifies gclient respects fallback to DEPS upon missing deps file."""
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo",\n'
        '    "deps_file" : ".DEPS.git",\n'
        '  },\n'
          ']')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}')

    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    self.assertEquals(
        [
          'svn://example.com/foo',
          'svn://example.com/foo/bar',
        ],
        self._get_processed())

  def testDepsFromNotAllowedHostsUnspecified(self):
    """Verifies gclient works fine with DEPS without allowed_hosts."""
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo",\n'
        '    "deps_file" : ".DEPS.git",\n'
        '  },\n'
          ']')
    write(
        os.path.join('foo', 'DEPS'),
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}')
    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    dep = obj.dependencies[0]
    self.assertEquals([], dep.findDepsFromNotAllowedHosts())
    self.assertEquals(frozenset(), dep.allowed_hosts)
    self._get_processed()

  def testDepsFromNotAllowedHostsOK(self):
    """Verifies gclient works fine with DEPS with proper allowed_hosts."""
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo",\n'
        '    "deps_file" : ".DEPS.git",\n'
        '  },\n'
          ']')
    write(
        os.path.join('foo', '.DEPS.git'),
        'allowed_hosts = ["example.com"]\n'
        'deps = {\n'
        '  "bar": "svn://example.com/bar",\n'
        '}')
    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    dep = obj.dependencies[0]
    self.assertEquals([], dep.findDepsFromNotAllowedHosts())
    self.assertEquals(frozenset(['example.com']), dep.allowed_hosts)
    self._get_processed()

  def testDepsFromNotAllowedHostsBad(self):
    """Verifies gclient works fine with DEPS with proper allowed_hosts."""
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo",\n'
        '    "deps_file" : ".DEPS.git",\n'
        '  },\n'
          ']')
    write(
        os.path.join('foo', '.DEPS.git'),
        'allowed_hosts = ["other.com"]\n'
        'deps = {\n'
        '  "bar": "svn://example.com/bar",\n'
        '}')
    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    obj.RunOnDeps('None', [])
    dep = obj.dependencies[0]
    self.assertEquals(frozenset(['other.com']), dep.allowed_hosts)
    self.assertEquals([dep.dependencies[0]], dep.findDepsFromNotAllowedHosts())
    self._get_processed()

  def testDepsParseFailureWithEmptyAllowedHosts(self):
    """Verifies gclient fails with defined but empty allowed_hosts."""
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo",\n'
        '    "deps_file" : ".DEPS.git",\n'
        '  },\n'
          ']')
    write(
        os.path.join('foo', 'DEPS'),
        'allowed_hosts = []\n'
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}')
    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    try:
      obj.RunOnDeps('None', [])
      self.fail()
    except gclient_utils.Error, e:
      self.assertIn('allowed_hosts must be', str(e))
    finally:
      self._get_processed()

  def testDepsParseFailureWithNonIterableAllowedHosts(self):
    """Verifies gclient fails with defined but non-iterable allowed_hosts."""
    write(
        '.gclient',
        'solutions = [\n'
        '  { "name": "foo", "url": "svn://example.com/foo",\n'
        '    "deps_file" : ".DEPS.git",\n'
        '  },\n'
          ']')
    write(
        os.path.join('foo', 'DEPS'),
        'allowed_hosts = None\n'
        'deps = {\n'
        '  "bar": "/bar",\n'
        '}')
    options, _ = gclient.OptionParser().parse_args([])
    obj = gclient.GClient.LoadCurrentConfig(options)
    try:
      obj.RunOnDeps('None', [])
      self.fail()
    except gclient_utils.Error, e:
      self.assertIn('allowed_hosts must be', str(e))
    finally:
      self._get_processed()


if __name__ == '__main__':
  sys.stdout = gclient_utils.MakeFileAutoFlush(sys.stdout)
  sys.stdout = gclient_utils.MakeFileAnnotated(sys.stdout, include_zero=True)
  sys.stderr = gclient_utils.MakeFileAutoFlush(sys.stderr)
  sys.stderr = gclient_utils.MakeFileAnnotated(sys.stderr, include_zero=True)
  logging.basicConfig(
      level=[logging.ERROR, logging.WARNING, logging.INFO, logging.DEBUG][
        min(sys.argv.count('-v'), 3)],
      format='%(relativeCreated)4d %(levelname)5s %(module)13s('
              '%(lineno)d) %(message)s')
  unittest.main()
