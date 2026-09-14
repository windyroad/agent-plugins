#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { existsSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { relative, resolve, sep } from 'node:path';
import { spawnSync } from 'node:child_process';
import { historicalProjectionHash, validateHistoricalContent, validateHistoricalMapping } from './story-map-history.mjs';

const [targetArg, mappingArg] = process.argv.slice(2);
if (!targetArg || !mappingArg) {
  console.error('usage: migrate-story-map.mjs <legacy-map.html> <mapping.json>');
  process.exit(2);
}

const unresolvedTarget = resolve(targetArg);
if (!existsSync(unresolvedTarget)) process.exit(0);
const target = realpathSync(unresolvedTarget);
const source = readFileSync(target);
if (source.includes(Buffer.from('<script id="story-map-data"'))) process.exit(0);

const mapping = JSON.parse(readFileSync(resolve(mappingArg), 'utf8'));
const allowed = new Set(['mapId', 'path', 'authorityAdr', 'sourceCommit', 'sourceSha256', 'map']);
if (!mapping || typeof mapping !== 'object' || Object.keys(mapping).some((key) => !allowed.has(key)) ||
    Object.keys(mapping).length !== allowed.size) {
  throw new Error('mapping must contain exactly mapId, path, authorityAdr, sourceCommit, sourceSha256, and map');
}
const actualPath = relative(process.cwd(), target).split(sep).join('/');
const sourceSha256 = createHash('sha256').update(source).digest('hex');
if (mapping.path !== actualPath || mapping.mapId !== mapping.map?.storyMapId ||
    mapping.sourceSha256 !== sourceSha256 || !mapping.sourceCommit) {
  throw new Error('mapping identity, path, source commit, or source fingerprint does not match the selected map');
}
if (!validateHistoricalContent(mapping.map)) throw new Error('mapping contains no historical pre-RFC rows');

const manifestPath = resolve('docs/story-maps/legacy-projection-manifest.json');
const previousManifest = existsSync(manifestPath) ? readFileSync(manifestPath) : null;
const manifest = previousManifest ? JSON.parse(previousManifest) : { schemaVersion: 1, maps: [] };
if (manifest.schemaVersion !== 1 || !Array.isArray(manifest.maps) ||
    manifest.maps.some((entry) => entry?.mapId === mapping.mapId || entry?.path === mapping.path)) {
  throw new Error('legacy projection manifest is invalid or already contains the selected map');
}
const entry = {
  mapId: mapping.mapId,
  path: mapping.path,
  authorityAdr: mapping.authorityAdr,
  sourceCommit: mapping.sourceCommit,
  sourceSha256,
  historicalSha256: historicalProjectionHash(mapping.map),
  canonicalSha256: '0'.repeat(64),
};
validateHistoricalMapping(mapping.map, target, entry);
manifest.maps.push(entry);

const render = () => {
  const result = spawnSync(process.execPath, [resolve(import.meta.dirname, 'render-story-map.mjs'), target], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error(result.stderr || result.stdout || 'story-map render failed');
};

try {
  const island = `<script id="story-map-data" type="application/json">\n${JSON.stringify(mapping.map, null, 2).replaceAll('<', '\\u003c')}\n</script>\n`;
  writeFileSync(target, island);
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  render();
  entry.canonicalSha256 = createHash('sha256').update(readFileSync(target)).digest('hex');
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  render();
  const verified = createHash('sha256').update(readFileSync(target)).digest('hex');
  if (verified !== entry.canonicalSha256) throw new Error('canonical story-map fingerprint changed during verification');
} catch (error) {
  writeFileSync(target, source);
  if (previousManifest) writeFileSync(manifestPath, previousManifest);
  else rmSync(manifestPath, { force: true });
  throw error;
}

console.log(`migrated ${mapping.mapId} to the canonical story-map format`);
