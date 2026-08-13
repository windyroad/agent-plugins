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

/** The problems a story closes, from its `problems:` frontmatter.
 *
 *  Derived like everything else that already exists elsewhere. Three places
 *  were naming problems — the map's `traces.problems`, an authored list on each
 *  row, and the story files — and all three disagreed: the map cited two
 *  problems no story mentioned and omitted three that stories did. The story is
 *  the only one of the three that can be right, because it is where the work
 *  and the problem meet.
 *
 *  A row's problems are the union of its stories'; the map's are the union of
 *  its rows'. A card with no story file contributes nothing, which is the
 *  honest answer — an untraced row should look untraced rather than inherit a
 *  trace from a neighbour.
 */
function resolveStoryProblems(storiesDir, storyId) {
  const hit = readStoryBody(storiesDir, storyId);
  if (!hit || !hit.body) return [];
  const m = hit.body.match(/^problems:\s*\[(.*?)\]\s*$/m);
  if (!m) return [];
  return m[1].split(',').map((s) => s.trim()).filter(Boolean);
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
  // The value statement is the FIRST paragraph. Filtering blanks out of the
  // whole section glued a following paragraph onto the "I want" clause: on a
  // phone STORY-052's card ran to 169 words, most of it the evidence prose the
  // author had deliberately put below the statement. A story is free to
  // explain itself under its value; the card carries the statement.
  const para = [];
  for (const line of lines.slice(start + 1, end)) {
    const t = line.trim();
    if (!t) { if (para.length) break; continue; }
    para.push(t);
  }
  const text = para.join(' ').trim();
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
  // and loose about everything else — the punctuation between the clauses, and
  // how the persona opens.
  //
  // The article is NOT required. "as whoever picks the ticket up" is the shape
  // written correctly; demanding a/an/the was a guess about wording, and the
  // guess cost STORY-060 its three lines with nothing reporting why. Widening
  // does not close that class on its own — see assertValueStatementsSplit,
  // which is what makes the next unanticipated phrasing loud instead of silent.
  // The connectives are CAPTURED, not re-emitted from memory. A story written
  // "In order that ..." was being relabelled "In order to ...", and dropping
  // the article from the persona group turned "as a developer" into a card
  // reading "as a a developer". The renderer does not get to decide how the
  // author opened a clause; it only decides where the line breaks.
  const m = text.match(
    /^(In order (?:to|that))\s+([\s\S]+?)\s*[,—–-]\s*(as)\s+([\s\S]+?)\s*[,—–-]\s*(I want)\s+([\s\S]+)$/i
  );
  if (!m) return { raw: runs(text) };
  return {
    leads: [m[1], m[3], m[5]],
    value: runs(m[2]), who: runs(m[4]), want: runs(m[6]),
  };
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

/** What the reader is looking at, in prose, before any scrolling.
 *
 *  Both facts that make a map a decision — that it is a draft, and that nobody
 *  has agreed it yet — lived only in `<meta>`, which does not render. A reader
 *  opening the file on a phone got a title, then five screens of grid, and had
 *  to infer the ask from the genre. The scale is the other half: the caption
 *  carries "N activities across M releases" but is clipped for screen readers
 *  only, so the one reader who cannot see how much is left is the one scrolling
 *  through it.
 */
function renderOrient(map) {
  const rows = (map.releases ?? []).length;
  const cards = (map.tasks ?? []).length;
  const agreed = (map.humanOversight ?? 'unconfirmed') === 'confirmed';
  const lead = agreed
    ? 'Agreed.'
    : map.status === 'draft' ? 'Draft — not yet agreed.' : 'Proposed — not yet agreed.';
  const shape = `${rows} release${rows === 1 ? '' : 's'}, ${cards} ` +
    `${cards === 1 ? 'story' : 'stories'}, one release per row.`;
  const ask = agreed
    ? ''
    : '<p class="orient">Read the release names down the left. Say yes to agree ' +
      'it, or name the row that is wrong or missing. The detail inside the cards ' +
      'is there if you want it, not because you have to read it.</p>';
  return `    <p class="orient"><strong>${lead}</strong> ${esc(shape)}</p>\n${ask ? '    ' + ask + '\n' : ''}`;
}

function renderMeta(map, derived) {
  const t = map.traces ?? {};
  // `problems` and `rfcs` are DERIVED, and the read is unconditional — no
  // `?? t.problems` alternation, which would let a pre-migration island outvote
  // the corpus and re-open the override ADR-104 forbids.
  //
  // The rfcs filter is load-bearing, not defensive: a row legitimately carries no
  // RFC, in two spellings — `"rfc": null` on a pre-RFC row, and no `rfc` key at
  // all. A raw join yields ",RFC-005,…" or ",,", and `content=",,"` satisfies the
  // reverse-tracers' `content="[^"]+"` guard, so a map with no RFCs would stop
  // looking like one.
  const rfcs = [...new Set((map.releases ?? []).map((r) => r.rfc).filter(Boolean))];
  const rows = [
    ['story-map-id', map.storyMapId],
    ['status', map.status],
    ['persona', map.persona],
    ['secondary-persona', map.secondaryPersona],
    ['problems', (derived.mapProblems ?? []).join(',')],
    ['rfcs', rfcs.join(',')],
    ['jtbd', (t.jtbd ?? []).join(',')],
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
 *  consumed by the renderer below, not at view time. Omitted entirely when nothing
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
  const shipped = mine.length && mine.every((t) => terminal(statuses[t.storyId]));
  // A row carries an RFC identity. The exception is CLOSED: it covers rows
  // holding work that shipped before rows carried identities, and those say so
  // with `preRfc`. Delivery alone cannot earn the exception — every row is
  // delivered eventually, so that reading would make shipping unproposed work
  // legitimate by finishing it.
  if (row.graveyard) return 'archived';
  if (shipped && (row.rfc || row.preRfc)) return 'delivered';
  if (row.rfc || (row.problems ?? []).length) return 'proposed';
  // NOT a third resting state. A row whose stories close no problem is a defect:
  // either the problem exists and the stories should trace it, or it needs
  // documenting. This used to return `unproposed` and render as "Speculative",
  // which gave a tidy name to work nobody had asked for and let it sit there.
  return 'untraced';
}

function renderStatus(map, storiesDir, mapPath) {
  const status = {};
  const values = {};
  const hrefs = {};

  const ids = [...new Set((map.tasks ?? []).map((t) => t.storyId).filter(Boolean))];
  const storyProblems = {};
  for (const id of ids) {
    const st = resolveStoryStatus(storiesDir, id);
    if (st) status[id] = st;
    const v = resolveStoryValue(storiesDir, id);
    if (v) values[id] = v;
    storyProblems[id] = resolveStoryProblems(storiesDir, id);
  }

  if (mapPath) {
    // Every id the map mentions anywhere: cards, rows, traces and prose.
    const mentioned = new Set(ids);
    for (const t of map.tasks ?? []) {
      for (const k of ['rfc', 'jtbd']) if (t[k]) mentioned.add(t[k]);
      for (const m of String(t.ref ?? '').match(/\b(?:ADR|JTBD|RFC|STORY-MAP|STORY|P)-?\d+\b/g) ?? []) mentioned.add(m);
    }
    for (const r of map.releases ?? []) if (r.rfc) mentioned.add(r.rfc);
    // Only `traces.jtbd` — the one authored trace left. Scanning the whole object
    // would resolve an authored `traces.adrs` into `hrefs`, leaving it UNRENDERED
    // but not inert; narrowing is what makes "inert" true.
    for (const m of (map.traces?.jtbd ?? []).join(' ').match(/\b(?:ADR|JTBD|RFC|STORY-MAP|STORY|P)-?\d+\b/g) ?? []) mentioned.add(m);
    // The problems each story closes, so they resolve to links on the rows.
    for (const pr of Object.values(storyProblems).flat()) mentioned.add(pr);

    for (const id of mentioned) {
      const href = resolveHref(mapPath, id);
      if (href) hrefs[id] = href;
    }
  }

  // Row status depends on the story statuses resolved just above, so it is
  // computed here and emitted rather than left for the client — the browser
  // cannot read story files.
  const rows = {};
  const rowProblems = {};
  const mapProblems = new Set();
  for (const r of map.releases ?? []) {
    const mine = (map.tasks ?? []).filter((t) => t.release === r.id);
    const ps = new Set();
    for (const t of mine) {
      if (!t.storyId) continue;
      for (const pr of storyProblems[t.storyId] ?? []) ps.add(pr);
    }
    const sorted = [...ps].sort();
    if (sorted.length) rowProblems[r.id] = sorted;
    sorted.forEach((pr) => mapProblems.add(pr));
    rows[r.id] = rowStatus({ ...r, problems: sorted }, map.tasks ?? [], status);
  }

  const payload = {};
  if (Object.keys(rows).length) payload.rows = rows;
  if (Object.keys(rowProblems).length) payload.rowProblems = rowProblems;
  if (mapProblems.size) payload.mapProblems = [...mapProblems].sort();
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


/* ---------------------------------------------------------------------------
 * The grid, rendered HERE rather than in the browser.
 *
 * It used to be built client-side from the data island by a shared story-map.js.
 * That made the file a thin shell: open it anywhere that does not run scripts —
 * a phone's file preview, a sandboxed viewer, GitHub's HTML rendering, print —
 * and you got the fallback message instead of the map. A map you cannot read
 * without a live script engine is not a document.
 *
 * Rendering here costs nothing that mattered. The renderer already runs on every
 * edit (story-map-edit re-renders after each operation), it already reads the
 * story corpus for status, values and problems, and the fingerprint is scoped to
 * the data island (ADR-102) — so generated markup in the file cannot drift a
 * ratification. Presentation stays de-duplicated in the shared stylesheet, which
 * is where the duplication actually was.
 *
 * Markup is byte-identical to what the script produced, including every
 * accessibility property that was reviewed: scope on both header axes, the
 * spanning empty-band cell with its visually-hidden sentence, role="list" on the
 * card lists, and the aria-hidden glyph carrying status as a second channel
 * alongside colour.
 * ------------------------------------------------------------------------- */

const BADGE_GLYPH = { 'b-live': '\u2713', 'b-next': '\u2192', 'b-later': '\u25c7', 'b-defect': '\u26a0' };

/** Status as a class. Derived, never an authored badge — a hand-written R1/R2
 *  ordinal duplicated the RFC identity and collided with it. */
function badgeClass(rel) {
  switch (String(rel.status || '').toLowerCase()) {
    case 'delivered': return 'b-live';
    case 'proposed':  return rel.rfc ? 'b-next' : 'b-defect';
    default:          return 'b-defect';
  }
}

/** What a row is CALLED. A row IS an RFC (ADR-103), so where a problem has
 *  proposed it, its id is the label. There is deliberately no "not yet
 *  allocated" state: drawing the row is what allocates the identity. */
/** What a row is CALLED. A row IS an RFC (ADR-103), so its id is the label.
 *
 *  Without one, the label says what is MISSING rather than inventing a status.
 *  Two distinct gaps, and they need different work:
 *
 *    proposed, no id — the stories close a problem, so the release is real and
 *                      wants an RFC identity. Drawing the row is what allocates
 *                      it; this row was drawn and never given one.
 *    untraced        — no story here closes anything. Link an existing problem
 *                      or document a new one.
 *
 *  Neither is a resting state, so neither gets a comfortable name. "Speculative"
 *  was the comfortable name, and it rendered on a row whose own header read
 *  "closes P160, P443" — the label and the trace contradicting each other.
 */
function rowLabel(rel) {
  if (rel.rfc) return rel.rfc;
  switch (String(rel.status || '').toLowerCase()) {
    case 'delivered': return 'Delivered, pre-RFC';
    // No glyph here \u2014 badge() prepends the one for the class, aria-hidden, as
    // the non-colour channel. A second copy in the label put "warning" into the
    // accessible name and rendered "\u26a0 \u26a0 Needs an RFC id".
    case 'proposed':  return 'Needs an RFC id';
    default:          return 'Untraced \u2014 needs a problem';
  }
}

function badge(cls, text) {
  return `<span class="badge ${cls}"><span class="b-glyph" aria-hidden="true">${esc(BADGE_GLYPH[cls] || '')}</span>${esc(text)}</span>`;
}

/** Wrap in a link when the renderer resolved one, else return the text. */
function link(hrefs, id, inner) {
  const href = id && hrefs[id];
  return href ? `<a href="${esc(href)}" class="ref-link">${inner}</a>` : inner;
}

/** Turn every artefact id in a run of prose into a link, leaving the rest be. */
function linkify(hrefs, text) {
  const re = /\b(?:ADR|JTBD|RFC|STORY-MAP|STORY|P)-?\d+\b/g;
  let out = '', last = 0, m;
  while ((m = re.exec(text)) !== null) {
    out += esc(text.slice(last, m.index));
    out += link(hrefs, m[0], esc(m[0]));
    last = m.index + m[0].length;
  }
  return out + esc(text.slice(last));
}

/** Emphasis runs from the story, as text and <strong>. Data in, markup out —
 *  nothing here interprets a story body as HTML. */
function runsHtml(list) {
  return (list || []).map((r) => (r.em ? `<strong>${esc(r.t)}</strong>` : esc(r.t))).join('');
}

/** A value statement as three lines. Run together it is a wall of text at card
 *  width; the shape that makes it scannable is the shape it was written in. */
function valueHtml(v) {
  if (!v) return '';
  if (v.raw || !v.value) {
    return `<div class="t-value"><div class="v-line">${runsHtml(v.raw)}</div></div>`;
  }
  const [l0, l1, l2] = v.leads ?? ['In order to', 'as', 'I want'];
  const parts = [
    [`${l0} `, v.value, 'v-inorder'],
    [`${l1} `, v.who, 'v-asa'],
    [`${l2} `, v.want, 'v-iwant'],
  ];
  return '<div class="t-value">' + parts.map(([lead, runs, cls]) =>
    `<div class="v-line ${cls}"><span class="v-lead">${esc(lead)}</span>${runsHtml(runs)}</div>`
  ).join('') + '</div>';
}

/** A card's own lifecycle state, as real text.
 *
 *  A row only reads delivered when everything in it is done, so a single
 *  shipped story inside an in-flight row was invisible: the status reached the
 *  markup as `data-status` and no stylesheet rule ever referenced it. The same
 *  story was reported as live three times against a map that looked identical
 *  each time.
 *
 *  The glyph is real text, never generated content — under forced colors the
 *  backgrounds collapse and it becomes the only discriminator. Draft is quiet
 *  but present; ABSENCE is reserved for a status that could not be resolved,
 *  which is a different fact and needs an edit rather than a nudge.
 */
const CARD_STATUS = {
  done:          ['ts-done',  '✓', 'Done'],
  archived:      ['ts-arch',  '○', 'Archived'],
  'in-progress': ['ts-prog',  '◑', 'In progress'],
  accepted:      ['ts-acc',   '○', 'Accepted'],
  draft:         ['ts-draft', '',       'Draft'],
};

function statusHtml(status) {
  const hit = CARD_STATUS[status];
  if (!hit) return '';
  const [cls, glyph, label] = hit;
  const mark = glyph ? `<span class="ts-glyph" aria-hidden="true">${glyph}</span>` : '';
  return `<div class="t-status ${cls}">${mark}${esc(label)}</div>`;
}

function cardHtml(task, status, value, hrefs) {
  const attrs = ['class="task"'];
  if (task.storyId) attrs.push(`data-story-id="${esc(task.storyId)}"`);
  if (task.rfc) attrs.push(`data-rfc="${esc(task.rfc)}"`);
  if (task.jtbd) attrs.push(`data-jtbd="${esc(task.jtbd)}"`);
  if (status) attrs.push(`data-status="${esc(status)}"`);
  let out = `<div ${attrs.join(' ')}>`;
  out += statusHtml(status);
  out += link(hrefs, task.storyId, `<span class="t-title">${esc(task.title || '')}</span>`);
  out += valueHtml(value);
  if (task.ref) out += `<div class="t-ref">Traces: ${linkify(hrefs, String(task.ref))}</div>`;
  return out + '</div>';
}

/** The whole grid: caption, both header axes, and one row per release. */
/** Read back the payload we just serialised, so the grid and the island share
 *  one resolution rather than computing it twice. */
function parseDerived(statusBlock) {
  const m = statusBlock.match(/<script id="story-map-status" type="application\/json">\n([\s\S]*?)\n\s*<\/script>/);
  if (!m) return {};
  try {
    return JSON.parse(m[1].replace(/\\u003c/g, '<'));
  } catch {
    return {};
  }
}

/* There is no lead paragraph. It was persona plus an observation, and both were
 * already on the page: the persona appears in every card's value statement ("as
 * a developer", 24 times on STORY-MAP-002), and any observation about the shape
 * of the work — how many columns, how much is live, which cells are empty — is
 * countable from the grid the reader is looking at.
 *
 * A map shows the work. Where a specific column or row needs a note, both carry
 * a `note` field for exactly that, next to the thing it is about. Prose at the
 * top that restates the picture below it is the ADR-104 rule applied to writing.
 */

function renderGrid(map, derived) {
  const backbone = map.backbone ?? [];
  const tasks = map.tasks ?? [];
  const hrefs = derived.hrefs ?? {};
  const statuses = derived.status ?? {};
  const values = derived.values ?? {};
  const releases = (map.releases ?? []).map((r) => ({
    ...r,
    status: (derived.rows ?? {})[r.id] || 'untraced',
    problems: (derived.rowProblems ?? {})[r.id] || [],
  }));

  // A caption NAMES the table; it does not teach the reader how to use one.
  //
  // This used to run: "N journey activities across the top; M release bands down
  // the side. Read a row left to right for everything that ships in one release.
  // A cell with no cards means that activity ships nothing in that release."
  // Every clause of that was already somewhere better. The lead paragraph says
  // how to read the map, in the map's own terms rather than in generic grid
  // terms. Each empty cell already carries its own visually-hidden sentence, so
  // the last clause explained something the reader meets in place.
  //
  // What survives is the part a caption is for: a name, and the dimensions —
  // which a screen-reader user gets BEFORE entering the table, and which are not
  // stated anywhere else.
  const caption = map.caption ||
    `${map.title ?? map.storyMapId} — ${backbone.length} journey activities across ${releases.length} releases`;

  let out = '<div class="scroll" tabindex="0" role="region" aria-label="Story map grid">';
  out += `<table class="map"><caption>${esc(caption)}</caption>`;
  out += '<thead><tr><td class="corner"></td>';
  for (const a of backbone) {
    // Explicit boundary: without it the accessible name concatenates as
    // "A. NoticeJTBD-008". The spaces the other sites rely on come from
    // display:block, which the accessible-name spec does not mandate.
    out += `<th class="act" scope="col">${esc(a.title || '')}`;
    if (a.note) out += ` <span class="jtbd">${esc(a.note)}</span>`;
    out += '</th>';
  }
  out += '</tr></thead><tbody>';

  for (const rel of releases) {
    const cls = badgeClass(rel);
    out += '<tr><th class="slice" scope="row">';
    out += badge(cls, rowLabel(rel));
    out += ' ' + link(hrefs, rel.rfc, `<span class="s-name">${esc(rel.name || '')}</span>`);
    if (rel.note) out += ` <span class="s-note">${esc(rel.note)}</span>`;
    if (rel.problems.length) {
      out += '<span class="s-problems">closes ' +
        rel.problems.map((p) => link(hrefs, p, esc(p))).join(', ') + '</span>';
    }
    out += '</th>';

    const filled = backbone.map((act) =>
      tasks.filter((t) => t.activity === act.id && t.release === rel.id));

    if (filled.every((h) => h.length === 0)) {
      // A wholly empty band is silent in a screen reader's browse mode while
      // being a loud full-width hatch visually. One spanning cell states it
      // once — per-cell text would bury a sparse map's few cards.
      out += `<td class="cell empty" colspan="${backbone.length || 1}"><span class="vh">No stories in this release band.</span></td>`;
    } else {
      for (const [i, here] of filled.entries()) {
        if (!here.length) {
          out += `<td class="cell empty"><span class="vh">No stories for ${esc(backbone[i]?.title || 'this activity')} in ${esc(rel.name || rel.id || 'this release')}.</span></td>`;
          continue;
        }
        out += '<td class="cell"><ul class="tasks" role="list">';
        for (const t of here) {
          out += '<li>' + cardHtml(t, statuses[t.storyId], values[t.storyId], hrefs) + '</li>';
        }
        out += '</ul></td>';
      }
    }
    out += '</tr>';
  }
  return out + '</tbody></table></div>';
}

/* The legend and the map-level problems line are BOTH gone, deliberately.
 *
 * The legend listed every row with its badge, name and note — which is exactly
 * what the first column of the grid shows, in the same order, three lines
 * further down. It had stopped being a legend (a key to the glyphs) and become
 * a second index of the rows. The glyphs need no key: each badge carries its
 * own text, and the glyph is the redundant non-colour channel beside it.
 *
 * The map-level problems line was the union of what every row already shows in
 * its own header. It was added when problems became derived, and it duplicated
 * the thing it was derived into.
 *
 * Both are the ADR-104 rule applied to presentation rather than to data: do not
 * show in two places what one place already says. The maintainer caught this as
 * the seventh instance, introduced while fixing the sixth.
 */

/** The traces, as one line of links, built from the island's `traces` object.
 *
 *  This replaces five paragraphs of hand-written `traceProse` — persona, jobs
 *  mapped, problems closed, decisions rested on, open questions — every one of
 *  which restated something already on the page or already in the island. The
 *  persona is the island's own field and the lead's first sentence; the jobs are
 *  glossed on the backbone columns; the problems are derived onto each row, so
 *  the authored version drifted from them by construction; the decisions are
 *  `traces.adrs`; and "open questions" was a changelog entry, not a trace.
 *
 *  Rendering the ids directly means there is no prose to keep in step. It is the
 *  ADR-104 rule again: show what is authored once, derive the rest, write
 *  nothing twice.
 */
function renderTrace(map, derived) {
  const hrefs = derived.hrefs ?? {};
  const tr = map.traces ?? {};
  // Jobs only. `Decisions` went with `traces.adrs` (ADR-106 — a map carries no
  // decision trace). `RFCs` went too rather than being derived: it would have
  // restated the row badges immediately beside it, which is the duplication
  // deleted from the map-level problems line for the same reason.
  const groups = [
    ['Jobs', tr.jtbd],
  ].filter(([, v]) => Array.isArray(v) && v.length);
  if (!groups.length) return '';
  const body = groups.map(([label, ids]) =>
    `<span class="tr-group"><strong>${esc(label)}:</strong> ` +
    ids.map((id) => link(hrefs, id, esc(id))).join(', ') + '</span>'
  ).join('');
  return `<p class="traces" id="story-map-traces">${body}</p>`;
}

/** Refuse a map whose cards have no stories behind them.
 *
 *  A card IS a story's position in a journey. Without one it is a sketch wearing
 *  map vocabulary — and nine rows across two maps were exactly that, rendering
 *  as a tidy status rather than as the defect they were. "If the story doesn't
 *  exist, then it shouldn't even be in the map."
 *
 *  This is also what makes an untraced row unreachable on a valid map: every
 *  card has a story, and ADR-060 I6 hard-blocks a story that traces no problem,
 *  so every row traces something.
 *
 *  Only fires when a story corpus is present. Rendering from the published
 *  package resolves nothing at all, and refusing there would reject every valid
 *  map for lacking a tree that was never there (ADR-104's degrade-gracefully
 *  consequence).
 */
/** Archived work is separated from live work.
 *
 *  `archived` means closed WITHOUT completion — scope shifted, or superseded.
 *  A card for one sitting among live rows reads as abandoned capability: map
 *  003 showed a working throttle marked Archived, because the card pointed at
 *  the record of the deleted first implementation rather than at the story
 *  that shipped the replacement. The reader cannot tell "this was dropped"
 *  from "this shipped, under a different story".
 *
 *  So an archived story is off the map, or it is in a row that says what it
 *  holds. The rule runs both ways: a graveyard row takes nothing else, or it
 *  becomes a quiet place to park live work.
 */
/** A story ships in exactly one release.
 *
 *  Two cards for one story across two ACTIVITIES is the grid working — one
 *  piece of work can serve two steps of a journey. Across two ROWS it is a
 *  contradiction, because a row is a release. This fired for real: a card was
 *  repointed at a story that already had one on the same map, putting it in
 *  both the pre-RFC row and an RFC row, and the map was ratified before anyone
 *  noticed.
 */
/** Refuse a map carrying a value statement the renderer cannot split.
 *
 *  The fallback path renders an unsplittable statement as one undifferentiated
 *  block. On a map where every other card shows three labelled clauses, that
 *  is indistinguishable from a story written badly — so the parser's failure
 *  gets read as the author's, by a reader who has no way to tell them apart.
 *
 *  This is the second time the class has fired. The first cost 15 stories
 *  their three lines; the fix was to loosen the pattern, and the pattern will
 *  always be narrower than the ways people write, so the class stayed open and
 *  STORY-060 walked into it. Loosening cannot close it. Refusing can: the
 *  renderer is the last point where anyone still knows a split was attempted.
 *
 *  Silent only when there is genuinely nothing to check — no stories tree, or
 *  a story with no value section. A story that HAS one and will not split is
 *  either written outside the house shape or has found the pattern's next
 *  edge, and both are worth an edit rather than a wall of text.
 */
function assertValueStatementsSplit(map, storiesDir) {
  if (!storiesDir || !existsSync(storiesDir)) return;
  const bad = [];
  for (const id of new Set((map.tasks ?? []).map((t) => t.storyId).filter(Boolean))) {
    const v = resolveStoryValue(storiesDir, id);
    if (v && v.raw) bad.push([id, v.raw.map((r) => r.t).join('')]);
  }
  if (!bad.length) return;
  const lines = ['this map has a story whose value statement will not split into its clauses.'];
  for (const [id, text] of bad) {
    lines.push(`    - ${id}: ${text.length > 120 ? text.slice(0, 117) + '...' : text}`);
  }
  lines.push('');
  lines.push('  A card renders the statement as three lines — the value, who it is');
  lines.push('  for, and what they want. One that will not split renders as a single');
  lines.push('  block, which on a map of three-line cards reads as a badly written');
  lines.push('  story rather than a parser that gave up.');
  lines.push('');
  lines.push('  Write it as: In order to <value>, as <who>, I want <capability>.');
  lines.push('  If it IS in that shape, the pattern has found a new edge — widen it');
  lines.push('  in splitValue rather than reword the story to suit the regex.');
  throw new Error(lines.join('\n'));
}

function assertOneReleasePerStory(map) {
  const rows = new Map();
  for (const t of map.tasks ?? []) {
    if (!t.storyId) continue;
    if (!rows.has(t.storyId)) rows.set(t.storyId, new Set());
    rows.get(t.storyId).add(t.release);
  }
  const split = [...rows].filter(([, r]) => r.size > 1);
  if (!split.length) return;
  const lines = ['this map ships a story in more than one release.'];
  for (const [id, r] of split) lines.push(`    - ${id} appears in rows: ${[...r].join(', ')}`);
  lines.push('');
  lines.push('  A story may span activities — one piece of work can serve two');
  lines.push('  steps of a journey — but a row is a release, and a story ships');
  lines.push('  once. Keep the card in the row that actually delivers it.');
  throw new Error(lines.join('\n'));
}

function assertArchivedIsSeparated(map, storiesDir) {
  if (!storiesDir || !existsSync(storiesDir)) return;
  const graveyard = new Set((map.releases ?? []).filter((r) => r.graveyard).map((r) => r.id));
  const strays = [];
  const intruders = [];
  for (const t of map.tasks ?? []) {
    if (!t.storyId) continue;
    const archived = resolveStoryStatus(storiesDir, t.storyId) === 'archived';
    const inGraveyard = graveyard.has(t.release);
    if (archived && !inGraveyard) strays.push(`${t.storyId} ("${t.title ?? ''}") in row "${t.release}"`);
    if (!archived && inGraveyard) intruders.push(`${t.storyId} ("${t.title ?? ''}")`);
  }
  if (!strays.length && !intruders.length) return;

  const lines = [];
  if (strays.length) {
    lines.push('this map places archived stories among live work.');
    for (const x of strays) lines.push(`    - ${x}`);
    lines.push('');
    lines.push('  Archived means closed without completion. Among live rows it reads');
    lines.push('  as abandoned capability, and a reader cannot tell that from work');
    lines.push('  that shipped under a different story. Either take the card off the');
    lines.push('  map, or move it to a graveyard row — a release carrying');
    lines.push('  "graveyard": true, which says what it holds.');
  }
  if (intruders.length) {
    if (lines.length) lines.push('');
    lines.push('  A graveyard row holds archived stories only. These are not archived:');
    for (const x of intruders) lines.push(`    - ${x}`);
    lines.push('  Otherwise it becomes a quiet place to park live work.');
  }
  throw new Error(lines.join('\n'));
}

function assertEveryCardHasAStory(map, storiesDir) {
  if (!storiesDir || !existsSync(storiesDir)) return;
  const orphans = [];
  const dangling = [];
  for (const t of map.tasks ?? []) {
    if (!t.storyId) { orphans.push(t.title ?? '(untitled card)'); continue; }
    if (!readStoryBody(storiesDir, t.storyId)) dangling.push(`${t.storyId} ("${t.title ?? ''}")`);
  }
  if (!orphans.length && !dangling.length) return;

  const lines = ['this map has cards with no story behind them.'];
  if (orphans.length) {
    lines.push(`  ${orphans.length} card(s) name no story at all:`);
    for (const o of orphans) lines.push(`    - "${o}"`);
  }
  if (dangling.length) {
    lines.push(`  ${dangling.length} card(s) name a story that does not exist:`);
    for (const d of dangling) lines.push(`    - ${d}`);
  }
  lines.push('');
  lines.push('  Fix each one: capture the story (/wr-itil:capture-story, which');
  lines.push('  hard-blocks a story that traces no problem — ADR-060 I6), or');
  lines.push('  remove the card. A card is a story\'s position in a journey; a');
  lines.push('  card without one is a sketch, and the map should not carry it.');
  throw new Error(lines.join('\n'));
}

function render(map, storiesDir, mapPath) {
  if (!Array.isArray(map.backbone) || map.backbone.length === 0) {
    throw new Error('story map needs a non-empty "backbone" array (the journey activities)');
  }
  if (!Array.isArray(map.releases) || map.releases.length === 0) {
    throw new Error('story map needs a non-empty "releases" array (the horizontal slices)');
  }

  assertEveryCardHasAStory(map, storiesDir);
  assertArchivedIsSeparated(map, storiesDir);
  assertOneReleasePerStory(map);
  assertValueStatementsSplit(map, storiesDir);

  const title = map.title ?? map.storyMapId;
  // Everything derived from outside the island is resolved ONCE and shared by
  // the island payload and the grid, so the two cannot disagree about a status,
  // a value or a link.
  const statusBlock = renderStatus(map, storiesDir, mapPath);
  const derived = parseDerived(statusBlock);
  const tokens = {
    TITLE: esc(title),
    TITLE_FULL: esc(`${map.storyMapId}: ${title}`),
    DATA: serialiseIsland(map),
    META: renderMeta(map, derived),
    STATUS: statusBlock,
    ORIENT: renderOrient(map),
    GRID: renderGrid(map, derived),
    TRACE: renderTrace(map, derived),
  };

  let out = readFileSync(TEMPLATE, 'utf8');
  for (const [key, value] of Object.entries(tokens)) {
    out = out.split(`{{${key}}}`).join(value);
  }
  return out;
}

/** Keep the shared stylesheet beside the maps. It is one copy for a whole
 *  corpus, so a restyle touches one file rather than every map — which was the
 *  duplication worth removing. The grid itself IS committed into each map, so
 *  that a map can be read with no script engine; the stylesheet staying shared
 *  is what keeps that affordable. */
function ensureSharedAssets(mapPath) {
  const dest = dirname(dirname(mapPath));
  // Stylesheet only. The client script is gone: the grid is rendered into the
  // file, so nothing needs to run at view time.
  for (const name of ['story-map.css']) {
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
