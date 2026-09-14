import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { basename, dirname, join, relative, sep } from 'node:path';

const SHA256 = /^[a-f0-9]{64}$/;
const keysAre = (value, allowed) => Object.keys(value).every((key) => allowed.has(key));

function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (!value || typeof value !== 'object') return value;
  return Object.fromEntries(Object.keys(value).sort().map((key) => [key, stable(value[key])]));
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

export function historicalProjectionHash(map) {
  const rows = (map.releases ?? [])
    .filter((row) => row?.historicalProjection !== undefined)
    .map(({ id, name, note, preRfc, historicalProjection }) =>
      stable({ id, name, note, preRfc, historicalProjection }));
  return sha256(JSON.stringify(rows));
}

function authorityProjectionHash(body, mapId) {
  if (!/^human-oversight:\s*confirmed\s*$/m.test(body)) return null;
  const lines = body.split('\n');
  const start = lines.findIndex((line) => /^legacy-projections:\s*$/.test(line));
  if (start === -1) return null;
  const found = new Map();
  for (const line of lines.slice(start + 1)) {
    if (!line.trim()) continue;
    if (!/^\s+/.test(line)) break;
    const match = line.match(/^\s+(STORY-MAP-\d+):\s*([a-f0-9]{64})\s*$/);
    if (!match || found.has(match[1])) return null;
    found.set(match[1], match[2]);
  }
  return found.get(mapId) ?? null;
}

function decisionFile(docsRoot, authorityAdr) {
  const match = String(authorityAdr ?? '').match(/^ADR-(\d+)$/);
  if (!match) return null;
  const prefix = `${String(Number(match[1])).padStart(3, '0')}-`;
  const dir = join(docsRoot, 'decisions');
  try {
    const hits = readdirSync(dir).filter((name) => name.startsWith(prefix) && name.endsWith('.md'));
    return hits.length === 1 ? join(dir, hits[0]) : null;
  } catch {
    return null;
  }
}

export function validateHistoricalContent(map) {
  const historical = (map.releases ?? []).filter((row) => row?.historicalProjection !== undefined);
  if (!historical.length) return false;

  const activities = new Set((map.backbone ?? []).map((activity) => activity.id));
  for (const row of historical) {
    const projection = row.historicalProjection;
    if (row.preRfc !== true || row.rfc || !projection || typeof projection !== 'object' ||
        !keysAre(row, new Set(['id', 'name', 'note', 'preRfc', 'historicalProjection']))) {
      throw new Error(`historical row ${row.id ?? '(missing id)'} must use preRfc: true, contain historicalProjection, and contain no rfc`);
    }
    if (!keysAre(projection, new Set(['reported', 'sourceBandId', 'sourceLabel', 'sourceNote', 'cards'])) ||
        !projection.reported || !projection.sourceBandId || !projection.sourceLabel ||
        typeof projection.sourceNote !== 'string' || !Array.isArray(projection.cards)) {
      throw new Error(`historical row ${row.id ?? '(missing id)'} has an incomplete historicalProjection`);
    }
    if ((map.tasks ?? []).some((task) => task.release === row.id)) {
      throw new Error(`historical row ${row.id} cannot contain ordinary tasks`);
    }
    for (const card of projection.cards) {
      if (!card || !keysAre(card, new Set(['activity', 'title', 'text', 'statusLabel'])) ||
          !activities.has(card.activity) || !card.title || !card.text || !card.statusLabel ||
          card.storyId || card.release || card.rfc) {
        throw new Error(`historical row ${row.id} has an invalid historical card`);
      }
    }
  }

  return true;
}

export function validateHistoricalMapping(map, mapPath, entry) {
  if (!validateHistoricalContent(map)) return;
  if (!mapPath) throw new Error('historical pre-RFC rows require a repository path');

  let storyMapsRoot = dirname(mapPath);
  if (basename(storyMapsRoot) !== 'story-maps') storyMapsRoot = dirname(storyMapsRoot);
  if (basename(storyMapsRoot) !== 'story-maps') throw new Error('historical story map must live in docs/story-maps');
  const docsRoot = dirname(storyMapsRoot);
  const repoRoot = dirname(docsRoot);
  const expectedPath = relative(repoRoot, mapPath).split(sep).join('/');
  const hash = historicalProjectionHash(map);
  if (entry.path !== expectedPath || entry.historicalSha256 !== hash ||
      !SHA256.test(entry.sourceSha256 ?? '') || !SHA256.test(entry.canonicalSha256 ?? '') ||
      !/^[a-f0-9]{7,64}$/.test(entry.sourceCommit ?? '')) {
    throw new Error(`legacy projection manifest entry for ${map.storyMapId} does not match the map`);
  }
  const retained = spawnSync('git', ['-C', repoRoot, 'show', `${entry.sourceCommit}:${entry.path}`]);
  if (retained.status !== 0 || sha256(retained.stdout) !== entry.sourceSha256) {
    throw new Error(`legacy projection source fingerprint for ${map.storyMapId} does not match retained history`);
  }
  const authority = decisionFile(docsRoot, entry.authorityAdr);
  if (!authority || !existsSync(authority)) {
    throw new Error(`legacy projection authority ${entry.authorityAdr ?? '(missing)'} cannot be resolved`);
  }
  const authorisedHash = authorityProjectionHash(readFileSync(authority, 'utf8'), map.storyMapId);
  if (authorisedHash !== hash) throw new Error(`legacy projection authority ${entry.authorityAdr} is unconfirmed or mismatched`);
}

export function validateHistoricalRows(map, mapPath) {
  if (!validateHistoricalContent(map)) return;
  let storyMapsRoot = dirname(mapPath);
  if (basename(storyMapsRoot) !== 'story-maps') storyMapsRoot = dirname(storyMapsRoot);
  const manifestPath = join(storyMapsRoot, 'legacy-projection-manifest.json');
  let manifest;
  try {
    manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  } catch {
    throw new Error('historical pre-RFC rows require a valid legacy-projection-manifest.json');
  }
  if (manifest.schemaVersion !== 1 || !Array.isArray(manifest.maps)) {
    throw new Error('legacy projection manifest has an unsupported schema');
  }
  const matches = manifest.maps.filter((entry) => entry?.mapId === map.storyMapId);
  if (matches.length !== 1) throw new Error(`legacy projection manifest must contain exactly one entry for ${map.storyMapId}`);
  validateHistoricalMapping(map, mapPath, matches[0]);
}
