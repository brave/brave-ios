# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
From a system-installed copy of the toolchain, packages all the required bits
into a .zip file.

It assumes default install locations for tools, in particular:
- C:\Program Files (x86)\Microsoft Visual Studio 12.0\...
- C:\Program Files (x86)\Windows Kits\10\...

1. Start from a fresh Win7 VM image.
2. Install VS Pro. Deselect everything except MFC.
3. Install Windows 10 SDK. Select only the Windows SDK and Debugging Tools for
Windows.
4. Run this script, which will build a <sha1>.zip.

Express is not yet supported by this script, but patches welcome (it's not too
useful as the resulting zip can't be redistributed, and most will presumably
have a Pro license anyway).
"""

import optparse
import os
import platform
import shutil
import sys
import tempfile
import zipfile

import get_toolchain_if_necessary


VS_VERSION = None
WIN_VERSION = None


def BuildFileList():
  result = []

  # Subset of VS corresponding roughly to VC.
  paths = [
      'DIA SDK/bin',
      'DIA SDK/idl',
      'DIA SDK/include',
      'DIA SDK/lib',
      'VC/atlmfc',
      'VC/bin',
      'VC/crt',
      'VC/include',
      'VC/lib',
      'VC/redist',
  ]

  if VS_VERSION == '2013':
    paths += [
        ('VC/redist/x86/Microsoft.VC120.CRT', 'sys32'),
        ('VC/redist/x86/Microsoft.VC120.MFC', 'sys32'),
        ('VC/redist/Debug_NonRedist/x86/Microsoft.VC120.DebugCRT', 'sys32'),
        ('VC/redist/Debug_NonRedist/x86/Microsoft.VC120.DebugMFC', 'sys32'),
        ('VC/redist/x64/Microsoft.VC120.CRT', 'sys64'),
        ('VC/redist/x64/Microsoft.VC120.MFC', 'sys64'),
        ('VC/redist/Debug_NonRedist/x64/Microsoft.VC120.DebugCRT', 'sys64'),
        ('VC/redist/Debug_NonRedist/x64/Microsoft.VC120.DebugMFC', 'sys64'),
    ]
  elif VS_VERSION == '2015':
    paths += [
        ('VC/redist/x86/Microsoft.VC140.CRT', 'sys32'),
        ('VC/redist/x86/Microsoft.VC140.MFC', 'sys32'),
        ('VC/redist/debug_nonredist/x86/Microsoft.VC140.DebugCRT', 'sys32'),
        ('VC/redist/debug_nonredist/x86/Microsoft.VC140.DebugMFC', 'sys32'),
        ('VC/redist/x64/Microsoft.VC140.CRT', 'sys64'),
        ('VC/redist/x64/Microsoft.VC140.MFC', 'sys64'),
        ('VC/redist/debug_nonredist/x64/Microsoft.VC140.DebugCRT', 'sys64'),
        ('VC/redist/debug_nonredist/x64/Microsoft.VC140.DebugMFC', 'sys64'),
    ]
  else:
    raise ValueError('VS_VERSION %s' % VS_VERSION)

  if VS_VERSION == '2013':
    vs_path = r'C:\Program Files (x86)\Microsoft Visual Studio 12.0'
  else:
    vs_path = r'C:\Program Files (x86)\Microsoft Visual Studio 14.0'

  for path in paths:
    src = path[0] if isinstance(path, tuple) else path
    combined = os.path.join(vs_path, src)
    assert os.path.exists(combined) and os.path.isdir(combined)
    for root, _, files in os.walk(combined):
      for f in files:
        final_from = os.path.normpath(os.path.join(root, f))
        if isinstance(path, tuple):
          result.append(
              (final_from, os.path.normpath(os.path.join(path[1], f))))
        else:
          assert final_from.startswith(vs_path)
          dest = final_from[len(vs_path) + 1:]
          if VS_VERSION == '2013' and dest.lower().endswith('\\xtree'):
            # Patch for C4702 in xtree on VS2013. http://crbug.com/346399.
            (handle, patched) = tempfile.mkstemp()
            with open(final_from, 'rb') as unpatched_f:
              unpatched_contents = unpatched_f.read()
            os.write(handle,
                unpatched_contents.replace('warning(disable: 4127)',
                                           'warning(disable: 4127 4702)'))
            result.append((patched, dest))
          else:
            result.append((final_from, dest))

  # Just copy the whole SDK.
  sdk_path = r'C:\Program Files (x86)\Windows Kits\10'
  for root, _, files in os.walk(sdk_path):
    for f in files:
      combined = os.path.normpath(os.path.join(root, f))
      # Some of the files in this directory are exceedingly long (and exceed
      #_MAX_PATH for any moderately long root), so exclude them. We don't need
      # them anyway. Exclude the Windows Performance Toolkit just to save space.
      tail = combined[len(sdk_path) + 1:]
      if (tail.startswith('References\\') or
          tail.startswith('Windows Performance Toolkit\\')):
        continue
      if VS_VERSION == '2015':
        # There may be many Include\Lib\Source directories for many different
        # versions of Windows and packaging them all wastes ~450 MB
        # (uncompressed) per version and wastes time. Only copy the specified
        # version.
        if (tail.startswith('Include\\') or tail.startswith('Lib\\') or
            tail.startswith('Source\\')):
          if tail.count(WIN_VERSION) == 0:
            continue
      to = os.path.join('win_sdk', tail)
      result.append((combined, to))

  if VS_VERSION == '2015':

    system_crt_files = [
        'api-ms-win-core-file-l1-2-0.dll',
        'api-ms-win-core-file-l2-1-0.dll',
        'api-ms-win-core-localization-l1-2-0.dll',
        'api-ms-win-core-processthreads-l1-1-1.dll',
        'api-ms-win-core-synch-l1-2-0.dll',
        'api-ms-win-core-timezone-l1-1-0.dll',
        'api-ms-win-core-xstate-l2-1-0.dll',
        'api-ms-win-crt-conio-l1-1-0.dll',
        'api-ms-win-crt-convert-l1-1-0.dll',
        'api-ms-win-crt-environment-l1-1-0.dll',
        'api-ms-win-crt-filesystem-l1-1-0.dll',
        'api-ms-win-crt-heap-l1-1-0.dll',
        'api-ms-win-crt-locale-l1-1-0.dll',
        'api-ms-win-crt-math-l1-1-0.dll',
        'api-ms-win-crt-multibyte-l1-1-0.dll',
        'api-ms-win-crt-private-l1-1-0.dll',
        'api-ms-win-crt-process-l1-1-0.dll',
        'api-ms-win-crt-runtime-l1-1-0.dll',
        'api-ms-win-crt-stdio-l1-1-0.dll',
        'api-ms-win-crt-string-l1-1-0.dll',
        'api-ms-win-crt-time-l1-1-0.dll',
        'api-ms-win-crt-utility-l1-1-0.dll',
        'api-ms-win-eventing-provider-l1-1-0.dll',
        'ucrtbase.dll',
        'ucrtbased.dll',
    ]
    bitness = platform.architecture()[0]
    # When running 64-bit python the x64 DLLs will be in System32
    x64_path = 'System32' if bitness == '64bit' else 'Sysnative'
    x64_path = os.path.join(r'C:\Windows', x64_path)
    for system_crt_file in system_crt_files:
        result.append((os.path.join(r'C:\Windows\SysWOW64', system_crt_file),
                       os.path.join('sys32', system_crt_file)))
        result.append((os.path.join(x64_path, system_crt_file),
                       os.path.join('sys64', system_crt_file)))

  # Generically drop all arm stuff that we don't need, and
  # drop .msi files because we don't need installers.
  return [(f, t) for f, t in result if 'arm\\' not in f.lower() and
                                       'arm64\\' not in f.lower() and
                                       not f.lower().endswith('.msi')]


def GenerateSetEnvCmd(target_dir):
  """Generate a batch file that gyp expects to exist to set up the compiler
  environment.

  This is normally generated by a full install of the SDK, but we
  do it here manually since we do not do a full install."""
  with open(os.path.join(
        target_dir, r'win_sdk\bin\SetEnv.cmd'), 'w') as f:
    f.write('@echo off\n'
            ':: Generated by win_toolchain\\package_from_installed.py.\n'
            # Common to x86 and x64
            'set PATH=%~dp0..\\..\\Common7\\IDE;%PATH%\n'
            'set INCLUDE=%~dp0..\\..\\win_sdk\\Include\\WINVERSION\\um;'
               '%~dp0..\\..\\win_sdk\\Include\\WINVERSION\\shared;'
               '%~dp0..\\..\\win_sdk\\Include\\WINVERSION\\winrt;'
               '%~dp0..\\..\\win_sdk\\Include\\WINVERSION\\ucrt;' # VS 2015
               '%~dp0..\\..\\VC\\include;'
               '%~dp0..\\..\\VC\\atlmfc\\include\n'
            'if "%1"=="/x64" goto x64\n'.replace('WINVERSION', WIN_VERSION))

    # x86. Always use amd64_x86 cross, not x86 on x86.
    f.write('set PATH=%~dp0..\\..\\win_sdk\\bin\\x86;'
              '%~dp0..\\..\\VC\\bin\\amd64_x86;'
              '%~dp0..\\..\\VC\\bin\\amd64;'  # Needed for mspdb1x0.dll.
              '%PATH%\n')
    f.write('set LIB=%~dp0..\\..\\VC\\lib;'
               '%~dp0..\\..\\win_sdk\\Lib\\WINVERSION\\um\\x86;'
               '%~dp0..\\..\\win_sdk\\Lib\\WINVERSION\\ucrt\\x86;' # VS 2015
               '%~dp0..\\..\\VC\\atlmfc\\lib\n'
            'goto :EOF\n'.replace('WINVERSION', WIN_VERSION))

    # x64.
    f.write(':x64\n'
            'set PATH=%~dp0..\\..\\win_sdk\\bin\\x64;'
                '%~dp0..\\..\\VC\\bin\\amd64;'
                '%PATH%\n')
    f.write('set LIB=%~dp0..\\..\\VC\\lib\\amd64;'
               '%~dp0..\\..\\win_sdk\\Lib\\WINVERSION\\um\\x64;'
               '%~dp0..\\..\\win_sdk\\Lib\\WINVERSION\\ucrt\\x64;' # VS 2015
               '%~dp0..\\..\\VC\\atlmfc\\lib\\amd64\n'
               .replace('WINVERSION', WIN_VERSION))


def AddEnvSetup(files):
  """We need to generate this file in the same way that the "from pieces"
  script does, so pull that in here."""
  tempdir = tempfile.mkdtemp()
  os.makedirs(os.path.join(tempdir, 'win_sdk', 'bin'))
  GenerateSetEnvCmd(tempdir)
  files.append((os.path.join(tempdir, 'win_sdk', 'bin', 'SetEnv.cmd'),
                'win_sdk\\bin\\SetEnv.cmd'))
  vs_version_file = os.path.join(tempdir, 'VS_VERSION')
  with open(vs_version_file, 'wb') as version:
    print >>version, VS_VERSION
  files.append((vs_version_file, 'VS_VERSION'))


def RenameToSha1(output):
  """Determine the hash in the same way that the unzipper does to rename the
  # .zip file."""
  print 'Extracting to determine hash...'
  tempdir = tempfile.mkdtemp()
  old_dir = os.getcwd()
  os.chdir(tempdir)
  if VS_VERSION == '2013':
    rel_dir = 'vs2013_files'
  else:
    rel_dir = 'vs_files'
  with zipfile.ZipFile(
      os.path.join(old_dir, output), 'r', zipfile.ZIP_DEFLATED, True) as zf:
    zf.extractall(rel_dir)
  print 'Hashing...'
  sha1 = get_toolchain_if_necessary.CalculateHash(rel_dir)
  os.chdir(old_dir)
  shutil.rmtree(tempdir)
  final_name = sha1 + '.zip'
  os.rename(output, final_name)
  print 'Renamed %s to %s.' % (output, final_name)


def main():
  usage = 'usage: %prog [options] 2013|2015'
  parser = optparse.OptionParser(usage)
  parser.add_option('-w', '--winver', action='store', type='string',
                    dest='winver', default='10.0.10586.0',
                    help='Windows SDK version, such as 10.0.10586.0')
  parser.add_option('-d', '--dryrun', action='store_true', dest='dryrun',
                    default=False,
                    help='scan for file existence and prints statistics')
  (options, args) = parser.parse_args()

  if len(args) != 1 or args[0] not in ('2013', '2015'):
    print 'Must specify 2013 or 2015'
    parser.print_help();
    return 1

  global VS_VERSION
  VS_VERSION = args[0]
  global WIN_VERSION
  WIN_VERSION = options.winver

  print 'Building file list for VS %s Windows %s...' % (VS_VERSION, WIN_VERSION)
  files = BuildFileList()

  AddEnvSetup(files)

  if False:
    for f in files:
      print f[0], '->', f[1]
    return 0

  output = 'out.zip'
  if os.path.exists(output):
    os.unlink(output)
  count = 0
  version_match_count = 0
  total_size = 0
  missing_files = False
  with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, True) as zf:
    for disk_name, archive_name in files:
      sys.stdout.write('\r%d/%d ...%s' % (count, len(files), disk_name[-40:]))
      sys.stdout.flush()
      count += 1
      if disk_name.count(WIN_VERSION) > 0:
        version_match_count += 1
      if os.path.exists(disk_name):
        if options.dryrun:
          total_size += os.path.getsize(disk_name)
        else:
          zf.write(disk_name, archive_name)
      else:
        missing_files = True
        sys.stdout.write('\r%s does not exist.\n\n' % disk_name)
        sys.stdout.flush()
  if options.dryrun:
    sys.stdout.write('\r%1.3f GB of data in %d files, %d files for %s.%s\n' %
        (total_size / 1e9, count, version_match_count, WIN_VERSION, ' '*50))
    return 0
  if missing_files:
    raise 'One or more files were missing - aborting'
  if version_match_count == 0:
    raise 'No files found that match the specified winversion'
  sys.stdout.write('\rWrote to %s.%s\n' % (output, ' '*50))
  sys.stdout.flush()

  RenameToSha1(output)

  return 0


if __name__ == '__main__':
  sys.exit(main())
