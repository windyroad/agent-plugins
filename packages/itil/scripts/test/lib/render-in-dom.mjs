#!/usr/bin/env node
// Usage: render-in-dom.mjs <map.html>   → the document, parsed, on stdout
//
// Assertions about header association, cell count and card placement need a
// parsed DOM rather than a grep over bytes. Nothing is executed: the grid is
// rendered into the file by wr-itil-render-story-map, so there is no script to
// run and `runScripts` is deliberately left off. If a future change reintroduces
// a client script, this harness will show its absence rather than hide it.
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { JSDOM } from 'jsdom';

const map = resolve(process.argv[2]);
const dom = new JSDOM(readFileSync(map, 'utf8'), { url: 'file://' + map });
process.stdout.write(dom.serialize());
