# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for tools/validate_config.py."""

import mock
import os
import unittest

from cq_client import cq_pb2
from cq_client import validate_config


TEST_DIR = os.path.dirname(os.path.abspath(__file__))


class TestValidateConfig(unittest.TestCase):
  def test_is_valid_rietveld(self):
    with open(os.path.join(TEST_DIR, 'cq_rietveld.cfg'), 'r') as test_config:
      self.assertTrue(validate_config.IsValid(test_config.read()))

  def test_is_valid_gerrit(self):
    with open(os.path.join(TEST_DIR, 'cq_gerrit.cfg'), 'r') as test_config:
      self.assertTrue(validate_config.IsValid(test_config.read()))

  def test_one_codereview(self):
    with open(os.path.join(TEST_DIR, 'cq_gerrit.cfg'), 'r') as gerrit_config:
      data = gerrit_config.read()
    data += '\n'.join([
        'rietveld{',
        'url: "https://blabla.com"',
        '}'
    ])
    self.assertFalse(validate_config.IsValid(data))

  def test_has_field(self):
    config = cq_pb2.Config()

    self.assertFalse(validate_config._HasField(config, 'version'))
    config.version = 1
    self.assertTrue(validate_config._HasField(config, 'version'))

    self.assertFalse(validate_config._HasField(
        config, 'rietveld.project_bases'))
    config.rietveld.project_bases.append('foo://bar')
    self.assertTrue(validate_config._HasField(
        config, 'rietveld.project_bases'))

    self.assertFalse(validate_config._HasField(
        config, 'verifiers.try_job.buckets'))
    self.assertFalse(validate_config._HasField(
        config, 'verifiers.try_job.buckets.name'))

    bucket = config.verifiers.try_job.buckets.add()
    bucket.name = 'tryserver.chromium.linux'


    self.assertTrue(validate_config._HasField(
        config, 'verifiers.try_job.buckets'))
    self.assertTrue(validate_config._HasField(
        config, 'verifiers.try_job.buckets.name'))

    config.verifiers.try_job.buckets.add()
    self.assertFalse(validate_config._HasField(
        config, 'verifiers.try_job.buckets.name'))
