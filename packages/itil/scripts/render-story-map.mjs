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
// @adr ADR-101 (AFK-accept carve-out — story cards must be single-line)

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
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

/** Badge class for a release band. Live-ish → green, first upcoming → blue,
 *  everything later → amber. Beyond the third band we stay amber rather than
 *  inventing colours, so an R4+ map degrades predictably. */
function badgeClass(release) {
  const badge = String(release.badge ?? '').toLowerCase();
  if (badge === 'live' || release.shipped === true) return 'b-live';
  // R1 is the band being built now; R2 and beyond are planned. Keyed off the
  // declared badge rather than list position — position gave two bands the same
  // colour and glyph on any two-band map.
  return badge === 'r1' ? 'b-next' : 'b-later';
}

const BADGE_GLYPH = { 'b-live': '\u2713', 'b-next': '\u2192', 'b-later': '\u25C7' };

/** A release badge. The glyph is a second VISUAL channel so release state is
 *  never carried by colour alone, and is aria-hidden because the text label
 *  already carries it for assistive tech. It is real markup rather than CSS
 *  generated content: under forced-colors the badge backgrounds all collapse to
 *  Canvas, and the glyph becomes the only thing telling the states apart. */
function renderBadge(cls, text) {
  const glyph = BADGE_GLYPH[cls] ?? '';
  return `<span class="badge ${cls}"><span class="b-glyph" aria-hidden="true">${glyph}</span>${esc(text)}</span>`;
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

function renderLegend(releases) {
  return releases
    .map((r) => {
      const cls = badgeClass(r);
      const note = r.note ? ` ${esc(r.note)}` : '';
      return `    <li>${renderBadge(cls, r.badge ?? r.name)}${note}</li>`;
    })
    .join('\n');
}

function renderActivities(backbone) {
  return backbone
    .map((a) => {
      const note = a.note ? ` <span class="jtbd">${esc(a.note)}</span>` : '';
      return `          <th class="act" scope="col">${esc(a.title)}${note}</th>`;
    })
    .join('\n');
}

/** One task card, emitted on a SINGLE line.
 *  story-oversight.sh filters whole lines when computing the ADR-101
 *  AFK-accept hash; a pretty-printed multi-line card leaves its other lines
 *  in the filtered output and silently makes the carve-out unsatisfiable. */
function renderTask(task) {
  const attrs = [
    task.storyId ? ` data-story-id="${esc(task.storyId)}"` : '',
    task.rfc ? ` data-rfc="${esc(task.rfc)}"` : '',
    task.jtbd ? ` data-jtbd="${esc(task.jtbd)}"` : '',
    task.storyStatus ? ` data-status="${esc(task.storyStatus)}"` : '',
  ].join('');
  const value = task.value ? ` <span class="t-value">${esc(task.value)}</span>` : '';
  const ref = task.ref ? ` <span class="t-ref">Traces: ${esc(task.ref)}</span>` : '';
  return `<div class="task"${attrs}><span class="t-title">${esc(task.title)}</span>${value}${ref}</div>`;
}

function renderRows(map) {
  const { backbone, releases, tasks = [] } = map;
  return releases
    .map((release, ri) => {
      const cls = badgeClass(release);
      const note = release.note ? ` <span class="s-note">${esc(release.note)}</span>` : '';
      const head =
        `        <tr>\n` +
        `          <th class="slice" scope="row">` +
        `${renderBadge(cls, release.badge ?? release.name)}` +
        ` <span class="s-name">${esc(release.name)}</span>${note}</th>`;

      const filled = backbone.map((activity) =>
        tasks.filter((t) => t.activity === activity.id && t.release === release.id)
      );

      // A wholly empty band is silent in a screen reader's browse mode while
      // being a loud full-width hatch visually. One spanning cell carries the
      // statement once — cheap, unlike per-cell text, which would bury three
      // cards under six identical announcements on a sparse map.
      const cells = filled.every((here) => here.length === 0)
        ? [`          <td class="cell empty" colspan="${backbone.length}">` +
           `<span class="vh">No stories in this release band.</span></td>`]
        : filled.map((here) => {
            if (here.length === 0) return `          <td class="cell empty"></td>`;
            // <li> per card keeps each card one line (the ADR-101 whole-line
            // hash filter) while giving the group a countable boundary.
            const cards = here
              .map((t) => `            <li>${renderTask(t)}</li>`)
              .join('\n');
            return `          <td class="cell">\n            <ul class="tasks" role="list">\n${cards}\n            </ul>\n          </td>`;
          });

      return [head, ...cells, `        </tr>`].join('\n');
    })
    .join('\n\n');
}

function renderTrace(map) {
  const p = map.traceProse ?? {};
  const parts = [
    ['Persona', p.persona],
    ['Jobs mapped', p.jobs],
    ['Problems this closes', p.problems],
    ['Decisions the journey rests on', p.decisions],
    ['Open questions', p.open],
  ];
  return parts
    .filter(([, v]) => v)
    .map(([label, v]) => `    <p><strong>${esc(label)}:</strong> ${esc(v)}</p>`)
    .join('\n');
}

/** The data island's opening tag, matched when reading a map back in. */
const ISLAND_OPEN = '<script id="story-map-data" type="application/json">';

/** Pull the authored data back out of a rendered map. This is the only thing
 *  the renderer ever reads from an existing map — never its shape. */
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
  const raw = html.slice(from, end).replace(/\\u003c/g, '<');
  return JSON.parse(raw);
}

/** Serialise the island deterministically, so re-rendering an unchanged map is
 *  byte-identical and a content fingerprint over it is stable. `<` is escaped
 *  so a title containing `</script>` cannot break out of the block. */
function serialiseIsland(map) {
  return JSON.stringify(map, null, 2).replace(/</g, '\\u003c');
}

function render(map) {
  if (!Array.isArray(map.backbone) || map.backbone.length === 0) {
    throw new Error('story map needs a non-empty "backbone" array (the journey activities)');
  }
  if (!Array.isArray(map.releases) || map.releases.length === 0) {
    throw new Error('story map needs a non-empty "releases" array (the horizontal slices)');
  }

  const caption =
    map.caption ??
    `${map.backbone.length} journey activities across the top; ` +
      `${map.releases.length} release bands down the side. ` +
      `Read a row left to right for everything that ships in one release. ` +
      `A cell with no cards means that activity ships nothing in that release.`;

  const title = map.title ?? map.storyMapId;
  const tokens = {
    TITLE: esc(title),
    TITLE_FULL: esc(`${map.storyMapId}: ${title}`),
    LEAD: esc(map.lead ?? ''),
    CAPTION: esc(caption),
    DATA: serialiseIsland(map),
    META: renderMeta(map),
    LEGEND: renderLegend(map.releases),
    ACTIVITIES: renderActivities(map.backbone),
    ROWS: renderRows(map),
    TRACE: renderTrace(map),
  };

  let out = readFileSync(TEMPLATE, 'utf8');
  for (const [key, value] of Object.entries(tokens)) {
    out = out.split(`{{${key}}}`).join(value);
  }
  return out;
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
    html = render(map);
  } catch (err) {
    console.error(`render-story-map: ${src} — ${err.message}`);
    return 1;
  }

  writeFileSync(srcPath, html);
  return 0;
}

process.exit(main(process.argv.slice(2)));
