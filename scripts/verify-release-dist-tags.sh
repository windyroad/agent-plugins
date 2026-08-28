#!/bin/bash

set -eu

package_root="${PACKAGE_ROOT:-packages}"
npm_cmd="${NPM_CMD:-npm}"
failed=0
seen=0

for pkg in "$package_root"/*/package.json; do
  [ -f "$pkg" ] || continue
  seen=$((seen + 1))
  name=$(node -e "const fs=require('fs'); console.log(JSON.parse(fs.readFileSync(process.argv[1], 'utf8')).name)" "$pkg")
  version=$(node -e "const fs=require('fs'); console.log(JSON.parse(fs.readFileSync(process.argv[1], 'utf8')).version)" "$pkg")
  latest=$("$npm_cmd" view "$name" dist-tags.latest 2>/dev/null || true)

  if [ "$latest" != "$version" ]; then
    echo "::error file=$pkg::$name@$version is published without latest (registry latest: ${latest:-missing})"
    failed=1
  fi
done

if [ "$seen" -eq 0 ]; then
  echo "::error::No package manifests found under $package_root"
  exit 1
fi

exit "$failed"
