#!/usr/bin/env node
// Read-only JSON query over the story-map corpus. Presentation and island
// parsing only — oversight facts arrive pre-computed on stdin from
// story-map-query.sh, which owns the single hash definition. Nothing here
// hashes anything; see that wrapper's header for why.
//
// Reads the data island, never the rendered grid. Under ADR-102 the grid is a
// projection regenerated from the island, so a map edited but not yet
// re-rendered would answer with stale content if this scraped the markup — and
// would disagree with the oversight hash, which is island-scoped.
//
// Operations:
//   list                     every map: id, title, status, jobs, problems,
//                            RFC row identities, ratification
//   get <MAP-ID>             one map: backbone, releases, tasks
//   find-story <STORY-ID>    which maps hold a story, and in which cell
//   find-rfc <RFC-ID>        which release rows carry an RFC and their stories
//   unratified               only the maps needing ratification, with a reason
//
// @adr ADR-102 (story maps render from JSON through a canonical template)
// @adr ADR-090 (drift-invalidated human-oversight marker)

import { readFileSync } from 'node:fs';

const ISLAND_OPEN = '<script id="story-map-data" type="application/json">';

/** Read the authored data. Falls through to null for a pre-ADR-102 map, which
 *  has no island — mirroring _oversight_hashable's own fallthrough rather than
 *  inventing a second rule about what counts as a map. */
function island(path) {
  let html;
  try {
    html = readFileSync(path, 'utf8');
  } catch {
    return null;
  }
  const start = html.indexOf(ISLAND_OPEN);
  if (start === -1) return null;
  const from = start + ISLAND_OPEN.length;
  const end = html.indexOf('</script>', from);
  if (end === -1) return null;
  try {
    return JSON.parse(html.slice(from, end).replace(/\\u003c/g, '<'));
  } catch {
    return null;
  }
}

/** Everything the renderer derived from outside the island — story statuses and
 *  values, row statuses, and resolved hrefs. Emitted alongside the data island
 *  when the renderer runs in a repository; outside one it is absent. */
function derivedIsland(mapPath) {
  let html;
  try {
    html = readFileSync(mapPath, 'utf8');
  } catch {
    return {};
  }
  const OPEN = '<script id="story-map-status" type="application/json">';
  const start = html.indexOf(OPEN);
  if (start === -1) return {};
  const from = start + OPEN.length;
  const end = html.indexOf('</script>', from);
  if (end === -1) return {};
  try {
    const d = JSON.parse(html.slice(from, end).replace(/\\u003c/g, '<'));
    // The derived island grew from a flat {storyId: status} map into
    // {rows, status, values, hrefs}. Normalise the older shape so a map
    // rendered by a previous version is still readable — this reader is not the
    // place to force a re-render.
    if (!d || typeof d !== 'object') return {};
    return d.status || d.rows || d.values || d.hrefs ? d : { status: d };
  } catch {
    return {};
  }
}

/** Oversight facts from the bash wrapper: path, ratified, reason. */
function readFacts() {
  let raw = '';
  try {
    raw = readFileSync(0, 'utf8');
  } catch {
    return [];
  }
  return raw
    .split('\n')
    .filter(Boolean)
    .map((line) => {
      const [path, ratified, reason] = line.split('\t');
      return { path, ratified: ratified === 'true', reason };
    });
}

/** Row status is DERIVED, and this reads the value the renderer emitted rather
 *  than recomputing it. There was a second copy of the derivation here; two
 *  definitions of one fact is the drift class this map format has already
 *  removed four times over. The renderer owns it because it is the only layer
 *  that can read story files.
 *
 *  A map edited but not re-rendered answers `stale` for every row — a value the
 *  renderer never emits, so it reads as "no derived answer" rather than
 *  impersonating a verdict. It is the same staleness the story statuses and card
 *  values already carry, and `story-map-edit` re-renders after every operation
 *  so it does not arise in practice.
 */
function rowStatus(row, derived) {
  return (derived.rows ?? {})[row.id] ?? 'stale';
}

function corpus() {
  return readFacts()
    .map((f) => ({ ...f, data: island(f.path), derived: derivedIsland(f.path) }))
    .filter((m) => m.data)
    .sort((a, b) => String(a.data.storyMapId).localeCompare(String(b.data.storyMapId)));
}

function summary(m) {
  return {
    storyMapId: m.data.storyMapId,
    title: m.data.title ?? null,
    status: m.data.status ?? null,
    persona: m.data.persona ?? null,
    // `traces` holds ONE authored key — the jobs the map is drawn for. Spelled
    // out rather than passed through, so a stale island carrying the removed
    // `adrs`/`rfcs` cannot leak them back into the query's answer.
    traces: { jtbd: m.data.traces?.jtbd ?? [] },
    // Derived, and read from what the renderer emitted rather than recomputed —
    // the renderer is the definition, and two definitions of one fact is the
    // drift class this format has removed repeatedly. Row RFC identities are
    // AUTHORED, so they come from the island; only problems are derived.
    problems: m.derived?.mapProblems ?? [],
    rfcs: [...new Set((m.data.releases ?? []).map((r) => r.rfc).filter(Boolean))],
    ratified: m.ratified,
    reason: m.reason,
    activities: (m.data.backbone ?? []).length,
    releases: (m.data.releases ?? []).length,
    cards: (m.data.tasks ?? []).length,
    path: m.path,
  };
}

const OPS = {
  list: (maps) => maps.map(summary),

  get(maps, [id]) {
    if (!id) throw new Error('get needs a story-map id, e.g. STORY-MAP-002');
    const m = maps.find((x) => x.data.storyMapId === id);
    if (!m) throw new Error(`no story map ${id} in this corpus`);
    return {
      ...summary(m),
      backbone: m.data.backbone ?? [],
      releasesDetail: (m.data.releases ?? []).map((r) => ({
        ...r,
        status: rowStatus(r, m.derived ?? {}),
      })),
      tasks: m.data.tasks ?? [],
    };
  },

  'find-story': (maps, [storyId]) => {
    if (!storyId) throw new Error('find-story needs a story id, e.g. STORY-047');
    const hits = [];
    for (const m of maps) {
      for (const t of m.data.tasks ?? []) {
        if (t.storyId !== storyId) continue;
        hits.push({
          storyMapId: m.data.storyMapId,
          activity: t.activity,
          release: t.release,
          title: t.title ?? null,
          ratified: m.ratified,
          path: m.path,
        });
      }
    }
    return hits;
  },

  'find-rfc': (maps, [rfcId]) => {
    if (!rfcId) throw new Error('find-rfc needs an RFC id, e.g. RFC-062');
    const hits = [];
    for (const m of maps) {
      for (const row of m.data.releases ?? []) {
        if (row.rfc !== rfcId) continue;
        hits.push({
          storyMapId: m.data.storyMapId,
          rowId: row.id,
          status: rowStatus(row, m.derived ?? {}),
          stories: [...new Set((m.data.tasks ?? [])
            .filter((task) => task.release === row.id)
            .map((task) => task.storyId)
            .filter(Boolean))],
          path: m.path,
        });
      }
    }
    return hits;
  },

  unratified: (maps) => maps.filter((m) => !m.ratified).map(summary),
};

function main(argv) {
  const [op, ...rest] = argv;
  if (!op || !OPS[op]) {
    console.error('usage: story-map-query <list|get|find-story|find-rfc|unratified> [args] [--maps-dir DIR]');
    console.error('');
    console.error('  list                   every map: status, jobs, problems, RFC rows, ratification');
    console.error('  get <MAP-ID>           one map: backbone, release bands, cards');
    console.error('  find-story <STORY-ID>  which maps hold a story, and in which cell');
    console.error('  find-rfc <RFC-ID>       which release rows carry an RFC and their stories');
    console.error('  unratified             maps needing ratification, each with a reason');
    return 2;
  }
  let out;
  try {
    out = OPS[op](corpus(), rest);
  } catch (err) {
    console.error(`story-map-query: ${err.message}`);
    return 1;
  }
  process.stdout.write(JSON.stringify(out, null, 2) + '\n');
  return 0;
}

process.exit(main(process.argv.slice(2)));
