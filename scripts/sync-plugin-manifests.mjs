#!/usr/bin/env node
// Sync the version field in every packages/<plugin>/.claude-plugin/plugin.json
// from the matching packages/<plugin>/package.json. Runs as part of the
// Changesets `npm run version` hook so the release PR contains the
// coordinated bump for both files. Also supports a --check mode that CI
// uses to fail PRs that edit package.json without the matching plugin.json.
//
// See docs/decisions/021-plugin-manifest-version-sync-mechanism.proposed.md
// See docs/problems/042-changesets-does-not-sync-plugin-manifest-version.known-error.md
//
// Usage:
//   node scripts/sync-plugin-manifests.mjs          # sync all manifests
//   node scripts/sync-plugin-manifests.mjs --check  # exit non-zero on drift
//
// Packages without a sibling .claude-plugin/plugin.json (e.g. shared,
// agent-plugins) are skipped silently.

import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, "..");
const PACKAGES_DIR = join(REPO_ROOT, "packages");

const mode = process.argv.includes("--check") ? "check" : "sync";

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function writeJsonPreservingFormat(path, data) {
  // Preserve trailing newline convention used by the repo's other JSON files.
  writeFileSync(path, JSON.stringify(data, null, 2) + "\n", "utf8");
}

const packages = readdirSync(PACKAGES_DIR, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

const drifted = [];
const synced = [];
let checkedCount = 0;

for (const pkg of packages) {
  const pkgJsonPath = join(PACKAGES_DIR, pkg, "package.json");
  const manifestPath = join(PACKAGES_DIR, pkg, ".claude-plugin", "plugin.json");

  if (!existsSync(pkgJsonPath)) {
    continue;
  }
  if (!existsSync(manifestPath)) {
    continue;
  }

  checkedCount += 1;

  const pkgJson = readJson(pkgJsonPath);
  const manifest = readJson(manifestPath);

  if (manifest.version === pkgJson.version) {
    continue;
  }

  if (mode === "check") {
    drifted.push({
      pkg,
      package: pkgJson.version,
      manifest: manifest.version,
    });
  } else {
    manifest.version = pkgJson.version;
    writeJsonPreservingFormat(manifestPath, manifest);
    synced.push({ pkg, version: pkgJson.version });
  }
}

if (mode === "check") {
  if (drifted.length > 0) {
    for (const { pkg, package: pv, manifest: mv } of drifted) {
      console.error(`DIVERGED: packages/${pkg} package.json=${pv} plugin.json=${mv}`);
    }
    console.error("");
    console.error(
      `ERROR: ${drifted.length} plugin manifest(s) have drifted from their package.json.`,
    );
    console.error("Run: npm run sync:plugin-manifests");
    process.exit(1);
  }
  console.log(`OK: all ${checkedCount} plugin manifest version(s) match their package.json`);
  process.exit(0);
}

if (synced.length === 0) {
  console.log(`OK: all ${checkedCount} plugin manifest version(s) already in sync`);
} else {
  for (const { pkg, version } of synced) {
    console.log(`synced: packages/${pkg}/.claude-plugin/plugin.json -> ${version}`);
  }
  console.log("");
  console.log(
    `Synced ${synced.length} plugin manifest(s). Review with: git diff packages/*/.claude-plugin/plugin.json`,
  );
}
