#!/bin/bash

set -eu

package_root="${PACKAGE_ROOT:-packages}"
npm_cmd="${NPM_CMD:-npm}"
mode="${1:-post-publish}"
post_publish_attempts="${POST_PUBLISH_ATTEMPTS:-6}"
post_publish_delay="${POST_PUBLISH_DELAY:-5}"
failed=0
seen=0

if [ "$mode" != "post-publish" ] && [ "$mode" != "--pre-publish" ]; then
  echo "Usage: $0 [--pre-publish]" >&2
  exit 2
fi

for pkg in "$package_root"/*/package.json; do
  [ -f "$pkg" ] || continue
  seen=$((seen + 1))
  name=$(node -e "const fs=require('fs'); console.log(JSON.parse(fs.readFileSync(process.argv[1], 'utf8')).name)" "$pkg")
  version=$(node -e "const fs=require('fs'); console.log(JSON.parse(fs.readFileSync(process.argv[1], 'utf8')).version)" "$pkg")

  if [ "$mode" = "--pre-publish" ]; then
    published=$("$npm_cmd" view "$name@$version" version --workspaces=false 2>/dev/null || true)
    [ -n "$published" ] || continue
  fi

  attempt=1
  while true; do
    latest=$("$npm_cmd" view "$name" dist-tags.latest --workspaces=false 2>/dev/null || true)
    if [ "$mode" = "post-publish" ] && [ "$latest" != "$version" ] && [ "$attempt" -lt "$post_publish_attempts" ]; then
      sleep "$post_publish_delay"
      attempt=$((attempt + 1))
      continue
    fi
    break
  done

  if [ "$latest" != "$version" ]; then
    if [ "$mode" = "--pre-publish" ]; then
      echo "::error file=$pkg::$name@$version already exists but is not latest (registry latest: ${latest:-missing}); choose a new version"
    else
      echo "::error file=$pkg::$name@$version is published without latest (registry latest: ${latest:-missing})"
    fi
    failed=1
  fi
done

if [ "$seen" -eq 0 ]; then
  echo "::error::No package manifests found under $package_root"
  exit 1
fi

exit "$failed"
