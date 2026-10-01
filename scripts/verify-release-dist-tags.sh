#!/bin/bash

set -eu

package_root="${PACKAGE_ROOT:-packages}"
npm_cmd="${NPM_CMD:-npm}"
mode="${1:-post-publish}"
post_publish_window="${POST_PUBLISH_WINDOW:-300}"
post_publish_delay="${POST_PUBLISH_DELAY:-5}"
failed=0
seen=0
pending_pkgs=()
pending_names=()
pending_versions=()

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
    latest=$("$npm_cmd" view "$name" dist-tags.latest --workspaces=false 2>/dev/null || true)
    if [ "$latest" != "$version" ]; then
      echo "::error file=$pkg::$name@$version already exists but is not latest (registry latest: ${latest:-missing}); choose a new version"
      failed=1
    fi
    continue
  fi

  pending_pkgs+=("$pkg")
  pending_names+=("$name")
  pending_versions+=("$version")
done

if [ "$seen" -eq 0 ]; then
  echo "::error::No package manifests found under $package_root"
  exit 1
fi

if [ "$mode" = "post-publish" ]; then
  deadline=$(( $(date +%s) + post_publish_window ))
  probed=0
  while [ "${#pending_pkgs[@]}" -gt 0 ]; do
    [ "$probed" -eq 0 ] || [ "$(date +%s)" -lt "$deadline" ] || break
    probed=1
    next_pkgs=()
    next_names=()
    next_versions=()
    next_latest=()
    for i in "${!pending_pkgs[@]}"; do
      latest=$("$npm_cmd" view "${pending_names[i]}" dist-tags.latest --workspaces=false --prefer-online 2>/dev/null || true)
      if [ "$latest" != "${pending_versions[i]}" ]; then
        next_pkgs+=("${pending_pkgs[i]}")
        next_names+=("${pending_names[i]}")
        next_versions+=("${pending_versions[i]}")
        next_latest+=("$latest")
      fi
    done
    pending_pkgs=("${next_pkgs[@]}")
    pending_names=("${next_names[@]}")
    pending_versions=("${next_versions[@]}")
    pending_latest=("${next_latest[@]}")
    [ "${#pending_pkgs[@]}" -gt 0 ] || break
    [ "$(date +%s)" -lt "$deadline" ] || break
    sleep "$post_publish_delay"
  done

  for i in "${!pending_pkgs[@]}"; do
    published=$("$npm_cmd" view "${pending_names[i]}@${pending_versions[i]}" version --workspaces=false --prefer-online 2>/dev/null || true)
    if [ -z "$published" ]; then
      echo "::error file=${pending_pkgs[i]}::${pending_names[i]}@${pending_versions[i]} is not visible in the registry yet"
    else
      echo "::error file=${pending_pkgs[i]}::${pending_names[i]}@${pending_versions[i]} exists but is not latest (registry latest: ${pending_latest[i]:-missing})"
    fi
    failed=1
  done
fi

exit "$failed"
