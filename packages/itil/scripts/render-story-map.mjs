#!/usr/bin/env node
// Render a story map from its JSON source into the canonical HTML grid.
//
// A story map is a two-dimensional grid: backbone activities run across the
// top as columns (the user journey), release slices run down as rows, and
// task cards sit in the cells. Reading a row left to right is everything
// that ships together.
//
// The shape lives in templates/story-map.html and nowhere else. This script
// knows what a story map is; it never inspects an existing map to infer it.
// That inference is what let every map in the corpus drift into a vertical
// stack together.
//
// A map is ONE file. Its data lives inside it, in a
// <script id="story-map-data" type="application/json"> island; the renderer
// rewrites the presentation around that island in place. There is no separate
// source file to diverge from the rendered output, and because the island is
// separable, a ratification fingerprint can be scoped to the data alone —
// so restyling every map in a corpus can never revoke a human approval.
//
// Usage: render-story-map.mjs <map.html>
//
// There is one mode, and it is idempotent. To CREATE a map, write a file
// containing nothing but the data island and render it — the renderer fills in
// everything around it. To CHANGE a map, edit the island in place and render
// again. Creation and editing are the same operation on the same file, so
// there is no seed file, no bootstrap flag, and no second code path to keep
// in step with the first.
//
// @adr ADR-102 (story maps render from JSON through a canonical template)
// @adr ADR-060 (Problem-RFC-Story framework — Phase 2 encoding, amended)
// @adr ADR-103 (story cards single-line — a readability convention now, not a
//      correctness constraint: ADR-101's whole-line filter that made it
//      load-bearing is retired, and cards sit outside the fingerprint basis)

import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const TEMPLATE = join(HERE, '..', 'templates', 'story-map.html');

/** Escape text destined for HTML body or attribute context. */
function esc(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/** Resolve a story's CURRENT lifecycle state from its own file.
 *
 *  Status is never authored on a card. Storing it would duplicate the story
 *  file, which means a sync obligation on every transition, a drift class that
 *  really did put three of eight maps out of date, and ratification churn —
 *  ticking a story to done is progress, not a revision of what a human
 *  approved, yet a stored value would drift the map's fingerprint.
 *
 *  Returns null when there is no stories tree (rendering outside a repository,
 *  e.g. from the published package) or no matching story. Callers omit the
 *  attribute rather than guessing.
 */
/** Locate a story by id and return its body, or null. Shared by the status and
 *  value resolvers so there is one definition of how a story file is found. */
function readStoryBody(storiesDir, storyId) {
  if (!storiesDir || !existsSync(storiesDir)) return null;
  const num = String(storyId).split('-')[1];
  if (!num) return null;
  let states;
  try {
    states = readdirSync(storiesDir);
  } catch {
    return null;
  }
  for (const state of states) {
    const dir = join(storiesDir, state);
    // The stories tree holds README files alongside the state directories.
    try {
      if (!statSync(dir).isDirectory()) continue;
    } catch {
      continue;
    }
    let hit;
    try {
      hit = readdirSync(dir).find((n) => n.startsWith(`STORY-${num}-`));
    } catch {
      continue;
    }
    if (!hit) continue;
    try {
      return { body: readFileSync(join(dir, hit), 'utf8'), state };
    } catch {
      return { body: null, state };
    }
  }
  return null;
}

function resolveStoryStatus(storiesDir, storyId) {
  const hit = readStoryBody(storiesDir, storyId);
  if (!hit) return null;
  if (!hit.body) return hit.state;
  const m = hit.body.match(/^status:\s*(.+)$/m);
  // Frontmatter is authoritative; the directory is the fallback, and the two
  // disagreeing is itself a defect worth seeing rather than papering over.
  return m ? m[1].trim() : hit.state;
}

/** A story's value statement, read from its `## User value` section.
 *
 *  Derived, never stored on the card — the fifth application of the same rule
 *  that removed storyStatus, card titles, the RFC story list and row status. A
 *  hand-written card value duplicates the story and degrades it: every one on
 *  STORY-MAP-002 had drifted into a "Value: ..." paraphrase while the stories
 *  themselves carried proper value-first statements. Deriving keeps the map
 *  showing what the story actually says.
 *
 *  Returns null outside a repository or when the story has no value section;
 *  callers omit the line rather than inventing one.
 */
function resolveStoryValue(storiesDir, storyId) {
  const hit = readStoryBody(storiesDir, storyId);
  if (!hit || !hit.body) return null;
  // PREFIX match: corpus headings carry trailing qualifiers — `## User value
  // (INVEST Valuable)` — so an end-anchored pattern silently finds nothing and
  // every card loses its value. Same trap the acceptance-criteria section hit.
  const lines = hit.body.split('\n');
  const start = lines.findIndex((l) => /^##\s+User value\b/.test(l));
  if (start === -1) return null;
  let end = lines.findIndex((l, i) => i > start && /^##\s/.test(l));
  if (end === -1) end = lines.length;
  const text = lines.slice(start + 1, end)
    .map((l) => l.trim())
    .filter(Boolean)
    .join(' ')
    .trim();
  return text ? splitValue(text) : null;
}

/** Break a value-first statement into its three clauses, preserving emphasis.
 *
 *  Stories are written "In order to <value>, as a <persona>, I want
 *  <capability>". Rendered as one paragraph it is a wall of text; the shape
 *  that makes it readable is the shape it was written in, so the split happens
 *  here and the client gives each clause its own line.
 *
 *  Emphasis is the AUTHOR's, never guessed. An earlier version bolded a persona
 *  head-noun it extracted itself — but across the corpus 12 of 50 values carry
 *  `**...**` and not one of them marks the persona: authors emphasise the
 *  capability. Inventing emphasis overrode what they had already said was
 *  important, so each clause comes back as a run list and the client renders
 *  exactly the marks the story carries.
 *
 *  Anything that does not match the pattern comes back as `{ raw }` and renders
 *  as a single block — a story written another way is not mangled to fit.
 */
function splitValue(text) {
  // Tolerant of how the clause actually ends in the corpus. "In order that" is
  // as common as "In order to"; "as the developer" as common as "as a"; and a
  // clause carrying a parenthetical closes on an em-dash rather than a comma —
  // "…toward fixed — as a developer…", "…away from the keyboard — I want…".
  // An earlier stricter pattern rejected 15 correctly-written statements and
  // rendered them as walls of text, which reads as a story defect when it is a
  // parser defect. Be strict about the SHAPE (value, who, want, in that order)
  // and loose about the punctuation between them.
  const m = text.match(
    /^In order (?:to|that)\s+([\s\S]+?)\s*[,—–-]\s*as (?:an?|the)\s+([\s\S]+?)\s*[,—–-]\s*I want\s+([\s\S]+)$/i
  );
  if (!m) return { raw: runs(text) };
  return { value: runs(m[1]), who: runs(m[2]), want: runs(m[3]) };
}

/** Split a markdown fragment into plain and emphasised runs.
 *
 *  Only `**strong**` — the one mark the corpus uses. Anything else stays
 *  literal rather than half-supported, and a lone `*` is left alone so prose
 *  containing one is not mangled. Returned as data, not HTML: the client builds
 *  text nodes and <strong> elements, so nothing here can inject markup.
 */
function runs(text) {
  const out = [];
  const re = /\*\*(.+?)\*\*/g;
  let last = 0, m;
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) out.push({ t: text.slice(last, m.index) });
    out.push({ t: m[1], em: true });
    last = m.index + m[0].length;
  }
  if (last < text.length) out.push({ t: text.slice(last) });
  return out.length ? out : [{ t: text }];
}

/** Where the stories tree sits relative to a map at docs/story-maps/<state>/. */
function storiesDirFor(mapPath) {
  return join(dirname(dirname(mapPath)), '..', 'stories');
}

/** The data island's opening tag, matched when reading a map back in. */
const ISLAND_OPEN = '<script id="story-map-data" type="application/json">';

/** Pull the authored data back out of a map. This is the only thing the
 *  renderer ever reads from an existing map — never its shape. */
export function extractIsland(html) {
  const start = html.indexOf(ISLAND_OPEN);
  if (start === -1) {
    throw new Error(
      'no <script id="story-map-data"> block found. A story map is defined by ' +
        'that block; to create one, write a file containing just the block and render it.'
    );
  }
  const from = start + ISLAND_OPEN.length;
  const end = html.indexOf('</script>', from);
  if (end === -1) throw new Error('data block is not closed');
  return JSON.parse(html.slice(from, end).replace(/\\u003c/g, '<'));
}

/** Serialise the island deterministically, so re-rendering an unchanged map is
 *  byte-identical and a content fingerprint over it is stable. `<` is escaped
 *  so a title containing `</script>` cannot break out of the block. */
function serialiseIsland(map) {
  return JSON.stringify(map, null, 2).replace(/</g, '\\u003c');
}

function renderMeta(map) {
  const t = map.traces ?? {};
  const rows = [
    ['story-map-id', map.storyMapId],
    ['status', map.status],
    ['persona', map.persona],
    ['secondary-persona', map.secondaryPersona],
    ['problems', (t.problems ?? []).join(',')],
    ['rfcs', (t.rfcs ?? []).join(',')],
    ['jtbd', (t.jtbd ?? []).join(',')],
    ['adrs', (t.adrs ?? []).join(',')],
    ['reported', map.reported],
    ['decision-makers', map.decisionMakers],
    ['human-oversight', map.humanOversight ?? 'unconfirmed'],
    ['oversight-hash', map.oversightHash],
    ['oversight-date', map.oversightDate],
    ['oversight-note', map.oversightNote],
  ];
  return rows
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => `  <meta name="${k}" content="${esc(v)}">`)
    .join('\n');
}

/** Resolve an artefact id to a path relative to the map, or null.
 *
 *  The renderer is the only layer with filesystem access, so link resolution
 *  belongs here — the client cannot know which lifecycle directory a problem
 *  currently sits in, and hard-coding one would rot the first time it moved.
 *  Maps live at docs/story-maps/<state>/, so `../..` reaches docs/.
 */
function resolveHref(mapPath, id) {
  const docs = join(dirname(dirname(mapPath)), '..');
  // No RFC entry, deliberately. ADR-103 made the release row the RFC, so the
  // 59 files under docs/rfcs/ are legacy records of delivered work. Linking one
  // sends a reader to a superseded artefact and re-teaches the two-tier model
  // this decision removed.
  const kinds = [
    [/^STORY-(\d+)$/, 'stories', (n) => `STORY-${n}-`, true],
    [/^STORY-MAP-(\d+)$/, 'story-maps', (n) => `STORY-MAP-${n}-`, true],
    [/^JTBD-(\d+)$/, 'jtbd', (n) => `JTBD-${n}-`, true],
    [/^ADR-(\d+)$/, 'decisions', (n) => `${n}-`, false],
    [/^P(\d+)$/, 'problems', (n) => `${n}-`, true],
  ];
  for (const [re, sub, prefix, nested] of kinds) {
    const m = String(id).match(re);
    if (!m) continue;
    const root = join(docs, sub);
    if (!existsSync(root)) return null;
    const want = prefix(m[1]);
    // Flat first, then one level down — problems, stories, maps and jobs are
    // filed under a lifecycle or persona directory; RFCs and decisions are not.
    const search = [root];
    if (nested) {
      try {
        for (const d of readdirSync(root)) {
          const sd = join(root, d);
          try { if (statSync(sd).isDirectory()) search.push(sd); } catch { /* skip */ }
        }
      } catch { return null; }
    }
    for (const dir of search) {
      let hit;
      try {
        hit = readdirSync(dir).find((n) => n.startsWith(want) && !n.startsWith('.'));
      } catch { continue; }
      if (hit) return relative(dirname(mapPath), join(dir, hit)).split(sep).join('/');
    }
    return null;
  }
  return null;
}

/** Everything derived from outside the island, emitted as one generated block:
 *  each story's lifecycle status and value statement, and an href for every
 *  artefact the map references.
 *
 *  None of it is authored. Status and value are read from each story's own file
 *  and hrefs from the docs tree, here, where the filesystem is available, and
 *  consumed by the shared script at view time. Omitted entirely when nothing
 *  resolves, which is the published-package case: a map opened outside a
 *  repository shows no status, no values and plain text instead of links.
 */
/** A row's status, derived — never authored (ADR-103).
 *
 *  delivered  — every story in the row is done or archived
 *  proposed   — a problem or an RFC names the row, and it is not delivered
 *  unproposed — nothing has asked for this release yet
 *
 *  THE definition. `story-map-query` reads the value emitted here rather than
 *  recomputing it, so the grid a human looks at and the JSON a tool reads
 *  cannot disagree — the drift class that put three of eight maps out of date
 *  when card status was stored.
 */
function rowStatus(row, tasks, statuses) {
  const mine = tasks.filter((t) => t.release === row.id);
  const terminal = (s) => s === 'done' || s === 'archived';
  if (mine.length && mine.every((t) => terminal(statuses[t.storyId]))) return 'delivered';
  if (row.rfc || (row.problems ?? []).length) return 'proposed';
  return 'unproposed';
}

function renderStatus(map, storiesDir, mapPath) {
  const status = {};
  const values = {};
  const hrefs = {};

  const ids = [...new Set((map.tasks ?? []).map((t) => t.storyId).filter(Boolean))];
  for (const id of ids) {
    const st = resolveStoryStatus(storiesDir, id);
    if (st) status[id] = st;
    const v = resolveStoryValue(storiesDir, id);
    if (v) values[id] = v;
  }

  if (mapPath) {
    // Every id the map mentions anywhere: cards, rows, traces and prose.
    const mentioned = new Set(ids);
    for (const t of map.tasks ?? []) {
      for (const k of ['rfc', 'jtbd']) if (t[k]) mentioned.add(t[k]);
      for (const m of String(t.ref ?? '').match(/\b(?:ADR|JTBD|RFC|STORY-MAP|STORY|P)-?\d+\b/g) ?? []) mentioned.add(m);
    }
    for (const r of map.releases ?? []) {
      if (r.rfc) mentioned.add(r.rfc);
      for (const pr of r.problems ?? []) mentioned.add(pr);
    }
    const proseBlob = JSON.stringify(map.traces ?? {}) + JSON.stringify(map.traceProse ?? {}) + String(map.lead ?? '');
    for (const m of proseBlob.match(/\b(?:ADR|JTBD|RFC|STORY-MAP|STORY|P)-?\d+\b/g) ?? []) mentioned.add(m);

    for (const id of mentioned) {
      const href = resolveHref(mapPath, id);
      if (href) hrefs[id] = href;
    }
  }

  // Row status depends on the story statuses resolved just above, so it is
  // computed here and emitted rather than left for the client — the browser
  // cannot read story files.
  const rows = {};
  for (const r of map.releases ?? []) rows[r.id] = rowStatus(r, map.tasks ?? [], status);

  const payload = {};
  if (Object.keys(rows).length) payload.rows = rows;
  if (Object.keys(status).length) payload.status = status;
  if (Object.keys(values).length) payload.values = values;
  if (Object.keys(hrefs).length) payload.hrefs = hrefs;
  if (Object.keys(payload).length === 0) return '';

  const body = JSON.stringify(payload, null, 2).replace(/</g, '\\u003c');
  return (
    '  <script id="story-map-status" type="application/json">\n' +
    body +
    '\n  <\/script>\n'
  );
}

function render(map, storiesDir, mapPath) {
  if (!Array.isArray(map.backbone) || map.backbone.length === 0) {
    throw new Error('story map needs a non-empty "backbone" array (the journey activities)');
  }
  if (!Array.isArray(map.releases) || map.releases.length === 0) {
    throw new Error('story map needs a non-empty "releases" array (the horizontal slices)');
  }

  const title = map.title ?? map.storyMapId;
  const tokens = {
    TITLE: esc(title),
    TITLE_FULL: esc(`${map.storyMapId}: ${title}`),
    LEAD: esc(map.lead ?? ''),
    DATA: serialiseIsland(map),
    META: renderMeta(map),
    STATUS: renderStatus(map, storiesDir, mapPath),
  };

  let out = readFileSync(TEMPLATE, 'utf8');
  for (const [key, value] of Object.entries(tokens)) {
    out = out.split(`{{${key}}}`).join(value);
  }
  return out;
}

/** Keep the shared stylesheet and script beside the maps. They are one copy for
 *  a whole corpus, so a presentation change touches one file rather than every
 *  map — which is the point of not committing generated markup. */
function ensureSharedAssets(mapPath) {
  const dest = dirname(dirname(mapPath));
  for (const name of ['story-map.css', 'story-map.js']) {
    const from = join(HERE, '..', 'templates', name);
    const to = join(dest, name);
    if (!existsSync(from)) continue;
    const src = readFileSync(from, 'utf8');
    if (!existsSync(to) || readFileSync(to, 'utf8') !== src) writeFileSync(to, src);
  }
}

function main(argv) {
  const [src] = argv;
  if (!src) {
    console.error('usage: render-story-map.mjs <map.html>');
    console.error('');
    console.error('  Renders a story map in place from its own data island.');
    console.error('  To create a map, write a file containing just the island:');
    console.error('');
    console.error('    <script id="story-map-data" type="application/json">');
    console.error('    { "storyMapId": "...", "backbone": [...], "releases": [...] }');
    console.error('    </script>');
    console.error('');
    console.error('  then render it. Creation and editing are the same command.');
    return 2;
  }
  const srcPath = resolve(src);
  if (!existsSync(srcPath)) {
    console.error(`render-story-map: source not found: ${src}`);
    return 1;
  }
  if (!existsSync(TEMPLATE)) {
    console.error(`render-story-map: template not found: ${TEMPLATE}`);
    return 1;
  }

  let map;
  try {
    map = extractIsland(readFileSync(srcPath, 'utf8'));
  } catch (err) {
    console.error(`render-story-map: ${src} — ${err.message}`);
    return 1;
  }

  let html;
  try {
    html = render(map, storiesDirFor(srcPath), srcPath);
  } catch (err) {
    console.error(`render-story-map: ${src} — ${err.message}`);
    return 1;
  }

  writeFileSync(srcPath, html);
  ensureSharedAssets(srcPath);
  return 0;
}

process.exit(main(process.argv.slice(2)));
