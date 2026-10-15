import assert from 'node:assert/strict';
import { readFile, readdir, mkdir } from 'node:fs/promises';
import { createServer } from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';
import { chromium, webkit, devices } from 'playwright';
import axe from 'axe-core';

const output = path.resolve(fileURLToPath(new URL('../dist/', import.meta.url)));
const artifacts = fileURLToPath(new URL('../artifacts/', import.meta.url));
const base = '/agent-plugins/';
let server;
let browser;
let origin;
let routes;

async function htmlFiles(dir) {
  const result = [];
  for (const item of await readdir(dir, { withFileTypes: true })) {
    const target = path.join(dir, item.name);
    if (item.isDirectory()) result.push(...await htmlFiles(target));
    else if (item.name.endsWith('.html') && item.name !== '404.html') result.push(target);
  }
  return result;
}

before(async () => {
  const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript', '.mjs': 'application/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.svg': 'image/svg+xml' };
  server = createServer(async (req, res) => {
    try {
      const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
      if (!pathname.startsWith(base)) { res.writeHead(404).end(); return; }
      const relative = pathname.slice(base.length);
      const target = path.resolve(output, relative.endsWith('/') || !relative ? `${relative}index.html` : relative);
      if (!target.startsWith(output + path.sep)) { res.writeHead(404).end(); return; }
      const bytes = await readFile(target);
      res.writeHead(200, { 'Content-Type': types[path.extname(target)] ?? 'application/octet-stream' }).end(bytes);
    } catch { res.writeHead(404).end(); }
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  origin = `http://127.0.0.1:${server.address().port}`;
  routes = (await htmlFiles(output)).map((f) => base + path.relative(output, f).replace(/index\.html$/, ''));
  browser = await chromium.launch();
  await mkdir(artifacts, { recursive: true });
});

after(async () => {
  await browser?.close();
  await new Promise((resolve) => server?.close(resolve));
});

const keyRoutes = [base, base + 'getting-started/', base + 'outcome-led-planning/', base + 'plugins/planning/', base + 'skills/planning/outcome-led-planning/', base + 'plugins/itil/', base + 'skills/itil/outcome-led-planning/'];

async function checkAxe(page) {
  await page.addScriptTag({ content: axe.source });
  const violations = await page.evaluate(async () => (await window.axe.run(document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] } })).violations);
  const remaining = [];
  for (const violation of violations) {
    const nodes = [];
    for (const node of violation.nodes) {
      if (violation.id === 'label-content-name-mismatch' && node.target.length === 1 && node.target[0] === 'button[data-open-modal=""]') {
        // Independently reviewed: Search is the action label; the key chord is a symbolic hint.
        // https://www.w3.org/WAI/WCAG22/Understanding/label-in-name.html#symbolic-text-characters
        const trigger = page.getByRole('button', { name: 'Search', exact: true });
        assert.equal(await trigger.locator('span').innerText(), 'Search');
        assert.match(await trigger.getAttribute('aria-keyshortcuts'), /^(Meta|Control)\+K$/);
        assert.match(await trigger.locator('kbd').first().innerText(), /^(⌘|Ctrl)\s*K$/);
      } else nodes.push(node.target);
    }
    if (nodes.length) remaining.push({ id: violation.id, targets: nodes });
  }
  return remaining;
}

test('every generated page has working base-path links, assets and one descriptive page heading', { timeout: 180_000 }, async () => {
  const page = await browser.newPage();
  const failures = [];
  page.on('response', (r) => { if (r.url().startsWith(origin) && r.status() >= 400) failures.push(r.url()); });
  const titles = new Set();
  for (const route of routes) {
    assert.equal((await page.goto(origin + route)).status(), 200, route);
    assert.equal(await page.locator('h1').count(), 1, route);
    assert.equal(await page.locator('html').getAttribute('lang'), 'en');
    const title = await page.title();
    assert.ok(!titles.has(title), `duplicate title: ${title}`);
    titles.add(title);
    const links = await page.locator('a[href]').evaluateAll((anchors) => anchors.map((a) => a.href));
    for (const href of new Set(links.filter((s) => s.startsWith(origin)))) {
      const url = new URL(href);
      assert.ok(url.pathname.startsWith(base), `escaped base: ${route} -> ${href}`);
      const result = await page.request.get(url.origin + url.pathname);
      assert.equal(result.status(), 200, `${route} -> ${href}`);
      if (url.hash && url.pathname === route) assert.ok(await page.locator(`[id=${JSON.stringify(decodeURIComponent(url.hash.slice(1)))}]`).count(), href);
    }
  }
  assert.deepEqual([...new Set(failures)], []);
  assert.ok(routes.includes(base + 'skills/itil/outcome-led-planning/'));
  await page.close();
});

test('key journeys reflow and pass targeted axe checks in both themes on mobile and desktop', { timeout: 180_000 }, async () => {
  for (const colorScheme of ['light', 'dark']) {
    for (const width of [320, 390, 1280]) {
      const context = await browser.newContext({ colorScheme, viewport: { width, height: 900 } });
      const page = await context.newPage();
      for (const route of keyRoutes) {
        await page.goto(origin + route);
        assert.deepEqual(await checkAxe(page), [], `${route} ${colorScheme} ${width}`);
        assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), true, `${route}: page overflow at ${width}`);
      }
      await page.goto(origin + base);
      await page.screenshot({ path: path.join(artifacts, `home-${colorScheme}-${width}.png`), fullPage: true });
      await context.close();
    }
  }
});

test('keyboard search finds the planning skill, reports no results and returns focus', { timeout: 60_000 }, async () => {
  const page = await browser.newPage();
  await page.goto(origin + base);
  const open = page.locator('button[data-open-modal]');
  await open.focus();
  await page.keyboard.press('Enter');
  const dialog = page.getByRole('dialog');
  await dialog.waitFor({ state: 'visible' });
  const input = dialog.getByRole('textbox', { name: 'Search', exact: true });
  await input.fill('outcome-led planning');
  const result = dialog.locator('a[href*="outcome-led-planning"]').first();
  await result.waitFor();
  const status = dialog.getByRole('status');
  await status.waitFor({ state: 'attached' });
  assert.equal(await status.getAttribute('aria-live'), 'polite');
  assert.equal(await status.getAttribute('aria-atomic'), 'true');
  await page.waitForFunction(() => {
    const dialog = document.querySelector('site-search dialog');
    return dialog.querySelector('[role="status"]')?.textContent === dialog.querySelector('.pagefind-ui__message')?.textContent;
  });
  assert.match(await status.textContent(), /results?/i);
  assert.equal(await input.evaluate((e) => e === document.activeElement), true);
  assert.deepEqual(await checkAxe(page), []);
  await input.fill('zzznosuchwindyroaddocumentzzz');
  const waitForNoResults = (query) => page.waitForFunction((currentQuery) => {
    const dialog = document.querySelector('site-search dialog');
    const message = dialog.querySelector('.pagefind-ui__message')?.textContent ?? '';
    return /no results/i.test(message) && message.includes(currentQuery) && dialog.querySelector('[role="status"]')?.textContent === message;
  }, query);
  await waitForNoResults('zzznosuchwindyroaddocumentzzz');
  await input.fill('quarantinedpublicationcanary');
  await waitForNoResults('quarantinedpublicationcanary');
  await page.keyboard.press('Escape');
  assert.equal(await open.evaluate((e) => e === document.activeElement), true);
  await open.click();
  await dialog.getByRole('textbox', { name: 'Search', exact: true }).fill('outcome-led planning');
  await dialog.locator('a[href*="outcome-led-planning"]').first().click();
  await page.waitForURL(/outcome-led-planning/);
  await page.close();
});

test('mobile navigation, skip link, no-JavaScript reading and WebKit phone layout work', { timeout: 60_000 }, async () => {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto(origin + base);
  await page.keyboard.press('Tab');
  await page.keyboard.press('Enter');
  assert.ok(await page.evaluate(() => location.hash || document.activeElement?.id));
  const menu = page.getByRole('button', { name: /menu/i });
  await menu.click();
  assert.equal(await page.locator('#starlight__sidebar').evaluate((e) => e.matches(':popover-open')), true);
  await page.locator('#starlight__sidebar').getByRole('link', { name: 'Install your first plugins', exact: true }).click();
  await page.waitForURL(/getting-started/);
  await page.close();
  const nojs = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 390, height: 844 } });
  const plain = await nojs.newPage();
  for (const route of keyRoutes) {
    assert.equal((await plain.goto(origin + route)).status(), 200);
    assert.ok((await plain.locator('main').innerText()).length > 100);
  }
  await nojs.close();
  const safari = await webkit.launch();
  try {
    const phone = await safari.newPage({ ...devices['iPhone 13'] });
    await phone.goto(origin + base + 'getting-started/');
    assert.equal(await phone.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), true);
    assert.equal(await phone.getByRole('heading', { level: 1 }).innerText(), 'Install your first plugins');
    assert.equal(await phone.locator('.expressive-code pre').evaluateAll((blocks) => blocks.every((e) => e.scrollWidth <= e.clientWidth + 1)), true);
    const command = 'npx @windyroad/agent-plugins --plugin architect tdd risk-scorer';
    assert.equal(await phone.locator('.expressive-code pre code').first().textContent(), command);
    assert.equal(await phone.locator('.expressive-code .copy button').first().getAttribute('data-code'), command);
  } finally { await safari.close(); }
});
