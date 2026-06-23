#!/usr/bin/env node
// Sync packages/<plugin>/.codex-plugin/plugin.json version fields from the
// sibling package.json. Mirrors scripts/sync-plugin-manifests.mjs for Claude.

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

function writeJson(path, data) {
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
  const manifestPath = join(PACKAGES_DIR, pkg, ".codex-plugin", "plugin.json");

  if (!existsSync(pkgJsonPath) || !existsSync(manifestPath)) {
    continue;
  }

  checkedCount += 1;

  const pkgJson = readJson(pkgJsonPath);
  const manifest = readJson(manifestPath);

  if (manifest.version === pkgJson.version) {
    continue;
  }

  if (mode === "check") {
    drifted.push({ pkg, package: pkgJson.version, manifest: manifest.version });
  } else {
    manifest.version = pkgJson.version;
    writeJson(manifestPath, manifest);
    synced.push({ pkg, version: pkgJson.version });
  }
}

if (mode === "check") {
  if (drifted.length > 0) {
    for (const { pkg, package: packageVersion, manifest } of drifted) {
      console.error(
        `DIVERGED: packages/${pkg} package.json=${packageVersion} .codex-plugin/plugin.json=${manifest}`,
      );
    }
    console.error("");
    console.error(
      `ERROR: ${drifted.length} Codex plugin manifest(s) have drifted from their package.json.`,
    );
    console.error("Run: npm run sync:codex-plugin-manifests");
    process.exit(1);
  }
  console.log(`OK: all ${checkedCount} Codex plugin manifest version(s) match their package.json`);
  process.exit(0);
}

if (synced.length === 0) {
  console.log(`OK: all ${checkedCount} Codex plugin manifest version(s) already in sync`);
} else {
  for (const { pkg, version } of synced) {
    console.log(`synced: packages/${pkg}/.codex-plugin/plugin.json -> ${version}`);
  }
  console.log("");
  console.log(
    "Synced Codex plugin manifest(s). Review with: git diff packages/*/.codex-plugin/plugin.json",
  );
}
