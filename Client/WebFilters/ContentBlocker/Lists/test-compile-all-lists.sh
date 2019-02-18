#!/bin/bash
set -e
pushd `dirname $0`

echo "Testing main blockers"

for file in *.json
do
  ./does-it-compile.swift "$file"
done

echo ""
echo "Testing regional blockers"

for file in Regional/*.json
do
  ./does-it-compile.swift "$file"
done

popd