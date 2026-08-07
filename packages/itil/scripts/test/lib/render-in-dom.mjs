#!/usr/bin/env node
// Test harness: load a story map, run the shared client-side script against a
// real DOM, and print the resulting document.
//
// Under ADR-102 the grid is built in the browser, so asserting on the file's
// bytes would only ever check the data island. The properties that matter —
// header association, cell count, empty-band handling, the single-line card
// constraint — live in what the script produces, so the tests have to run it.
//
// Usage: render-in-dom.mjs <map.html>   → rendered document on stdout
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { JSDOM } from 'jsdom';

const map = resolve(process.argv[2]);
const html = readFileSync(map, 'utf8');
// The map links ../story-map.js; jsdom will not fetch it from file://, so the
// shared script is injected directly from the same place a repo copy comes from.
const script = readFileSync(
  join(dirname(new URL(import.meta.url).pathname), '..', '..', '..', 'templates', 'story-map.js'),
  'utf8'
);

const dom = new JSDOM(html.replace(/<script src="[^"]*story-map\.js"[^>]*><\/script>/, ''), {
  runScripts: 'outside-only',
  url: 'file://' + map,
});
// A browser runs a deferred script with readyState already "interactive", so
// the script takes its SYNCHRONOUS branch. jsdom leaves readyState "loading"
// after parsing, which would send the harness down the DOMContentLoaded
// listener instead — a branch that ships to nobody. Force the real one.
Object.defineProperty(dom.window.document, 'readyState', { value: 'interactive', configurable: true });
dom.window.eval(script);
// Belt and braces: if the guard is ever reworked to listen regardless, still
// deliver the event so the harness does not silently render nothing.
dom.window.document.dispatchEvent(new dom.window.Event('DOMContentLoaded'));
process.stdout.write(dom.serialize());
