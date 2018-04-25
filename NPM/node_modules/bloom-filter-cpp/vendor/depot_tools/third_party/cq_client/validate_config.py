#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""CQ config validation library."""

import argparse
# This file was originally copied together with the cq_client library from the
# internal commit_queue repository and then modified to import protobuf26
# instead of google.protobuf to prevent conflicts with a different version of
# google.protobuf that some users of depot_tools have installed. If you need to
# update this file, please make similar changes again and add this comment back.
# More details on why we chose to rename the package can be found in the file
# depot_tools/third_party/protobuf26/README.chromium.
import protobuf26 as protobuf
import logging
import re
import sys

from cq_client import cq_pb2


REQUIRED_FIELDS = [
  'version',
  'verifiers',
  'cq_name',
]

LEGACY_FIELDS = [
  'svn_repo_url',
]

EMAIL_REGEXP = '^[^@]+@[^@]+\.[^@]+$'


def _HasField(message, field_path):
  """Checks that at least one field with given path exist in the proto message.

  This function correctly handles repeated fields and will make sure that each
  repeated field will have required sub-path, e.g. if 'abc' is a repeated field
  and field_path is 'abc.def', then the function will only return True when each
  entry for 'abc' will contain at least one value for 'def'.

  Args:
    message (google.protobuf.message.Message): Protocol Buffer message to check.
    field_path (string): Path to the target field separated with ".".

  Return:
    True if at least one such field is explicitly set in the message.
  """
  path_parts = field_path.split('.', 1)
  field_name = path_parts[0]
  sub_path = path_parts[1] if len(path_parts) == 2 else None

  field_labels = {fd.name: fd.label for fd in message.DESCRIPTOR.fields}
  repeated_field = (field_labels[field_name] ==
                    protobuf.descriptor.FieldDescriptor.LABEL_REPEATED)

  if sub_path:
    field = getattr(message, field_name)
    if repeated_field:
      if not field:
        return False
      return all(_HasField(entry, sub_path) for entry in field)
    else:
      return _HasField(field, sub_path)
  else:
    if repeated_field:
      return len(getattr(message, field_name)) > 0
    else:
      return message.HasField(field_name)


def IsValid(cq_config):
  """Validates a CQ config and prints errors/warnings to the screen.

  Args:
    cq_config (string): Unparsed text format of the CQ config proto.

  Returns:
    True if the config is valid.
  """
  try:
    config = cq_pb2.Config()
    protobuf.text_format.Merge(cq_config, config)
  except protobuf.text_format.ParseError as e:
    logging.error('Failed to parse config as protobuf:\n%s', e)
    return False

  if _HasField(config, 'gerrit'):
    if _HasField(config, 'rietveld'):
      logging.error('gerrit and rietveld are not supported at the same time.')
      return False
    # TODO(tandrii): validate gerrit.
    required_fields = REQUIRED_FIELDS + ['gerrit.cq_verified_label']
    if _HasField(config, 'verifiers.reviewer_lgtm'):
      logging.error('reviewer_lgtm verifier is not supported with Gerrit.')
      return False
  elif _HasField(config, 'rietveld'):
    required_fields = REQUIRED_FIELDS + ['rietveld.url']
  else:
    logging.error('either rietveld gerrit are required fields.')
    return False

  for fname in required_fields:
    if not _HasField(config, fname):
      logging.error('%s is a required field', fname)
      return False

  for fname in LEGACY_FIELDS:
    if _HasField(config, fname):
      logging.warn('%s is a legacy field', fname)


  for base in config.rietveld.project_bases:
    try:
      re.compile(base)
    except re.error:
      logging.error('failed to parse "%s" in project_bases as a regexp', base)
      return False

  # TODO(sergiyb): For each field, check valid values depending on its
  # semantics, e.g. email addresses, regular expressions etc.
  return True
