#!/usr/bin/env node
// Card-level editing for a story map, so nobody hand-edits the data island.
//
// A map's data lives in a JSON island inside a several-hundred-line HTML file,
// with `<` escaped as <. Editing that with an exact-match string tool is
// error-prone enough that it does not get done: during ADR-102's own authoring
// every island change went through a throwaway load-mutate-save script rather
// than the editing tool an agent normally reaches for. This command is that
// script, made a first-class surface — state the operation, never open the JSON.
//
// Every operation validates against the map's own backbone and bands before
// writing, and re-renders afterwards, so the grid and the data cannot disagree.
// A rejected operation leaves the file untouched.
//
// Usage:
//   story-map-edit.mjs <map.html> add-card     --story ID --activity ID --release ID
//                                              --title T [--ref R] [--rfc ID] [--jtbd ID]
//   story-map-edit.mjs <map.html> move-card    --story ID [--activity ID] [--release ID]
//   story-map-edit.mjs <map.html> remove-card  --story ID
//   story-map-edit.mjs <map.html> add-band     --id ID --name N [--rfc RFC-NNN] [--note N]
//   story-map-edit.mjs <map.html> add-activity --id ID --title T [--note N]
//
// Nothing the story file already says is settable here — status, the value
// statement, and the problems a story closes are all read from the story at
// render time (ADR-104). A card carries what identifies it and where it sits;
// a row carries its RFC identity and its name. There are no --status, --value
// or --badge flags, and a row's status and problems are derived from the
// stories in it.
//
// @adr ADR-102 (story maps render from JSON through a canonical template)
// @adr ADR-095 (story-map membership enforced at capture — drives add-card)

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const HERE = dirname(fileURLToPath(import.meta.url));
const RENDERER = join(HERE, 'render-story-map.mjs');
const ISLAND_OPEN = '<script id="story-map-data" type="application/json">';

function parseFlags(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    out[key] = next && !next.startsWith('--') ? next : true;
    if (out[key] !== true) i += 1;
  }
  return out;
}

function readIsland(path) {
  const html = readFileSync(path, 'utf8');
  const start = html.indexOf(ISLAND_OPEN);
  if (start === -1) {
    throw new Error(
      `${path} carries no <script id="story-map-data"> block — not a story map.`
    );
  }
  const from = start + ISLAND_OPEN.length;
  const end = html.indexOf('</script>', from);
  if (end === -1) throw new Error(`${path}: data block is not closed.`);
  return { html, from, end, data: JSON.parse(html.slice(from, end).replace(/\\u003c/g, '<')) };
}

function writeIsland(path, { html, from, end }, data) {
  const island = JSON.stringify(data, null, 2).replace(/</g, '\\u003c');
  writeFileSync(path, html.slice(0, from) + '\n' + island + '\n  ' + html.slice(end));
}

function need(flags, name, op) {
  const v = flags[name];
  if (!v || v === true) throw new Error(`${op} needs --${name}`);
  return String(v);
}

/** Reject an id that is not on the map, naming what IS available — a bare
 *  "invalid activity" sends the caller back to open the island, which is the
 *  thing this command exists to avoid. */
function requireId(list, id, what) {
  const ids = list.map((x) => x.id);
  if (!ids.includes(id)) {
    throw new Error(`no ${what} "${id}" on this map. Available: ${ids.join(', ')}`);
  }
}

const OPS = {
  'add-card'(data, flags) {
    const story = need(flags, 'story', 'add-card');
    const activity = need(flags, 'activity', 'add-card');
    const release = need(flags, 'release', 'add-card');
    const title = need(flags, 'title', 'add-card');
    requireId(data.backbone ?? [], activity, 'activity');
    requireId(data.releases ?? [], release, 'release band');
    data.tasks = data.tasks ?? [];
    if (data.tasks.some((t) => t.storyId === story)) {
      throw new Error(`${story} is already on this map — use move-card to relocate it.`);
    }
    const card = { activity, release, title };
    if (flags.rfc && flags.rfc !== true) card.rfc = String(flags.rfc);
    if (flags.jtbd && flags.jtbd !== true) card.jtbd = String(flags.jtbd);
    card.storyId = story;
    if (flags.ref && flags.ref !== true) card.ref = String(flags.ref);
    data.tasks.push(card);
    return `added ${story} at ${activity} × ${release}`;
  },

  'move-card'(data, flags) {
    const story = need(flags, 'story', 'move-card');
    const card = (data.tasks ?? []).find((t) => t.storyId === story);
    if (!card) throw new Error(`${story} is not on this map.`);
    if (flags.activity && flags.activity !== true) {
      requireId(data.backbone ?? [], String(flags.activity), 'activity');
      card.activity = String(flags.activity);
    }
    if (flags.release && flags.release !== true) {
      requireId(data.releases ?? [], String(flags.release), 'release band');
      card.release = String(flags.release);
    }
    return `moved ${story} to ${card.activity} × ${card.release}`;
  },

  'remove-card'(data, flags) {
    const story = need(flags, 'story', 'remove-card');
    const before = (data.tasks ?? []).length;
    data.tasks = (data.tasks ?? []).filter((t) => t.storyId !== story);
    if (data.tasks.length === before) throw new Error(`${story} is not on this map.`);
    return `removed ${story}`;
  },

  'add-band'(data, flags) {
    const id = need(flags, 'id', 'add-band');
    const name = need(flags, 'name', 'add-band');
    data.releases = data.releases ?? [];
    if (data.releases.some((r) => r.id === id)) {
      throw new Error(`release band "${id}" already exists on this map.`);
    }
    const band = { id, name };
    // A row IS an RFC (ADR-103). Where a problem has proposed the row it carries
    // that identity; where nothing has, it renders as speculative and says so.
    if (flags.rfc && flags.rfc !== true) band.rfc = String(flags.rfc);
    if (flags.note && flags.note !== true) band.note = String(flags.note);
    data.releases.push(band);
    return `added release band ${id}`;
  },

  'add-activity'(data, flags) {
    const id = need(flags, 'id', 'add-activity');
    const title = need(flags, 'title', 'add-activity');
    data.backbone = data.backbone ?? [];
    if (data.backbone.some((a) => a.id === id)) {
      throw new Error(`activity "${id}" already exists on this map.`);
    }
    const act = { id, title };
    if (flags.note && flags.note !== true) act.note = String(flags.note);
    data.backbone.push(act);
    return `added activity ${id}`;
  },
};

function usage() {
  console.error('usage: story-map-edit.mjs <map.html> <operation> [flags]');
  console.error('');
  console.error('  add-card     --story ID --activity ID --release ID --title T');
  console.error('               [--ref R] [--rfc ID] [--jtbd ID]');
  console.error('  move-card    --story ID [--activity ID] [--release ID]');
  console.error('  remove-card  --story ID');
  console.error('  add-band     --id ID --name N [--rfc RFC-NNN] [--note N]');
  console.error('  add-activity --id ID --title T [--note N]');
  console.error('');
  console.error('Or pass the operation as JSON on stdin, which needs no shell escaping:');
  console.error('  echo \'{"op":"add-card","story":"STORY-1","activity":"a","release":"r1","title":"He said \\"go\\" — then left"}\' \\');
  console.error('    | story-map-edit.mjs <map.html> --json -');
  console.error('');
  console.error('Status, value and problems are derived from the story files at');
  console.error('render time and are not settable here (ADR-104).');
}

/** Read an operation as a JSON object on stdin.
 *
 *  The escaping problem this closes: a card title or value carrying quotes, an
 *  em-dash or a newline is painful to pass through a shell command line and
 *  trivial to pass as JSON. Validation is the same code path as the flag form —
 *  the object is simply converted to the flag map the operations already take.
 *
 *  NOTE: the sibling story-map-query uses stdin for the opposite purpose — it
 *  consumes facts fed in by its own wrapper. Do not assume symmetry. */
function flagsFromStdin() {
  let raw;
  try {
    raw = readFileSync(0, 'utf8');
  } catch {
    throw new Error('--json - expects the operation as a JSON object on stdin');
  }
  let obj;
  try {
    obj = JSON.parse(raw);
  } catch (err) {
    throw new Error(`stdin is not valid JSON — ${err.message}`);
  }
  if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
    throw new Error('stdin must be a JSON object, e.g. {"op":"add-card","story":"STORY-1",...}');
  }
  const { op, ...flags } = obj;
  if (!op) throw new Error('the JSON object needs an "op", e.g. "add-card"');
  return { op: String(op), flags };
}

function main(argv) {
  let [target, op, ...rest] = argv;

  // `--json -` replaces the operation and flags with a JSON object on stdin.
  if (argv.includes('--json')) {
    const path = argv[0];
    let parsed;
    try {
      parsed = flagsFromStdin();
    } catch (err) {
      console.error(`story-map-edit: ${err.message}`);
      return 1;
    }
    return run(path, parsed.op, parsed.flags);
  }

  if (!target || !op) {
    usage();
    return 2;
  }
  return run(target, op, parseFlags(rest));
}

/** The single execution path. Both the flag form and the stdin form land here
 *  with an operation name and a flag map, so validation cannot diverge between
 *  them — an equivalence asserted in prose drifts the first time a branch is
 *  added to one form only. */
function run(target, op, flags) {
  if (!OPS[op]) {
    console.error(`story-map-edit: unknown operation "${op}"`);
    usage();
    return 2;
  }
  const path = resolve(target);
  if (!existsSync(path)) {
    console.error(`story-map-edit: not found: ${target}`);
    return 1;
  }

  let island;
  try {
    island = readIsland(path);
  } catch (err) {
    console.error(`story-map-edit: ${err.message}`);
    return 1;
  }

  // Mutate a copy, so a rejected operation cannot leave the file half-edited.
  const draft = JSON.parse(JSON.stringify(island.data));
  let summary;
  try {
    summary = OPS[op](draft, flags);
  } catch (err) {
    console.error(`story-map-edit: ${err.message}`);
    return 1;
  }

  writeIsland(path, island, draft);
  try {
    execFileSync(process.execPath, [RENDERER, path], { stdio: 'pipe' });
  } catch (err) {
    console.error(`story-map-edit: wrote the data but re-render failed — ${err.message}`);
    return 1;
  }
  console.error(`story-map-edit: ${summary}`);
  return 0;
}

process.exit(main(process.argv.slice(2)));
