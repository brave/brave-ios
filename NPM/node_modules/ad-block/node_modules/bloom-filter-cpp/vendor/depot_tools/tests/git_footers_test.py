#!/usr/bin/env python

"""Tests for git_footers."""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import git_footers

class GitFootersTest(unittest.TestCase):
  _message = """
This is my commit message. There are many like it, but this one is mine.

My commit message is my best friend. It is my life. I must master it.

"""

  _position = 'refs/heads/master@{#292272}'

  _position_footer = 'Cr-Commit-Position: %s\n' % _position

  _git_svn_id = ('svn://svn.chromium.org/chrome/trunk/src@290386'
                 ' 0039d316-1c4b-4281-b951-d872f2087c98')

  _git_svn_id_footer = 'git-svn-id: %s\n' % _git_svn_id

  _git_svn_id_branch = (
      'svn://svn.chromium.org/chrome/branches/blabble/src@177288')

  _git_svn_id_footer_branch = 'git-svn-id: %s\n' % _git_svn_id_branch


  def testFootersBasic(self):
    self.assertEqual(
        git_footers.parse_footers(self._message), {})
    self.assertEqual(
        git_footers.parse_footers(self._message + self._position_footer),
        { 'Cr-Commit-Position': [ self._position ] })
    self.assertEqual(
        git_footers.parse_footers(self._message + self._git_svn_id_footer),
        { 'Git-Svn-Id': [ self._git_svn_id ] })
    self.assertEqual(
        git_footers.parse_footers(self._message + self._position_footer
                                                + self._position_footer),
        { 'Cr-Commit-Position': [ self._position, self._position ] })

  def testTrunkHeuristic(self):
    footers = git_footers.parse_footers(self._message + self._git_svn_id_footer)
    self.assertEqual(
        footers,
        { 'Git-Svn-Id': [ self._git_svn_id ] })
    self.assertEqual(
        git_footers.get_position(footers),
        ('refs/heads/master', '290386'))

  def testBranchHeuristic(self):
    footers = git_footers.parse_footers(self._message +
                                        self._git_svn_id_footer_branch)
    self.assertEqual(
        footers,
        { 'Git-Svn-Id': [ self._git_svn_id_branch ] })
    self.assertEqual(
        git_footers.get_position(footers),
        ('refs/branch-heads/blabble', None))

if __name__ == '__main__':
  unittest.main()
