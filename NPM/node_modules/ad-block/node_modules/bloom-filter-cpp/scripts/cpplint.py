#!/usr/bin/env python

import fnmatch
import os
import sys

from lib.util import execute

IGNORE_FILES = [
  # os.path.join('./node_modules', 'nan', 'nan_implementation_12_inl.h')
]

SOURCE_ROOT = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))


def main():
  os.chdir(SOURCE_ROOT)
  files = list_files([''],
                     ['*.cpp', '*.cc', '*.h'])

  node_modules_files = list_files(['node_modules'],
                     ['*.cpp', '*.cc', '*.h'])

  call_cpplint(list(set(files) - set(IGNORE_FILES) - set(node_modules_files)))


def list_files(directories, filters):
  matches = []
  for directory in directories:
    for root, _, filenames, in os.walk(os.path.join('./', directory)):
      for f in filters:
        for filename in fnmatch.filter(filenames, f):
          matches.append(os.path.join(root, filename))
  return matches


def call_cpplint(files):
  cpplint = os.path.join(SOURCE_ROOT, 'vendor', 'depot_tools', 'cpplint.py')
  execute([sys.executable, cpplint] + files)


if __name__ == '__main__':
  sys.exit(main())
