#!/usr/bin/env bash
. demo_repo.sh

run git cherry-pick-upload -h
echo

pcommand git cherry-pick-upload -b my_branch c02b7d24a066adb747fdeb12deb21bfa
echo 'Found parent revision: b96d69fda53845a205151613a9c4cc93'
echo 'Loaded authentication cookies from .codereview_upload_cookies'
echo 'Issue created. URL: https://codereview.chromium.org/1234567890'
echo '  Uploading base_file for some/path/first.file: OK'
echo '  Uploading some/path/first.file: OK'
echo '  Uploading base_file for some/path/second.file: OK'
echo '  Uploading some/path/second.file: OK'
echo '  Uploading base_file for some/path/third.file: OK'
echo '  Uploading some/path/third.file: OK'
echo 'Finalizing upload: OK'
