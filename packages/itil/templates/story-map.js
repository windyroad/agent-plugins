/* Story-map rendering, shared by every map. One copy.
   Generated into a repo beside the maps by wr-itil-render-story-map; edit the
   copy shipped in @windyroad/itil, not this one.

   A map file carries its authored data in <script id="story-map-data"> and,
   when it was rendered inside a repository, a derived story-status lookup in
   <script id="story-map-status">. This script builds the grid from those at
   view time, so no generated markup is committed.

   The markup below deliberately mirrors what the server-side renderer used to
   emit, attribute for attribute: scope="col"/scope="row" header association, a
   spanning cell with visually-hidden text for a wholly empty band, one <li> per
   task card, and an aria-hidden badge glyph as a non-colour channel. Changing
   it changes the accessibility properties that were reviewed. */
(function () {
  'use strict';

  var BADGE_GLYPH = { 'b-live': '✓', 'b-next': '→', 'b-later': '◇' };

  function el(tag, attrs, text) {
    var n = document.createElement(tag);
    if (attrs) Object.keys(attrs).forEach(function (k) { n.setAttribute(k, attrs[k]); });
    if (text != null) n.textContent = text;
    return n;
  }

  function readJSON(id) {
    var node = document.getElementById(id);
    if (!node) return null;
    try { return JSON.parse(node.textContent); } catch (e) { return null; }
  }

  /* R1 is the band being built now; Live is shipped; everything else is later.
     Keyed off the declared badge rather than list position — position gave two
     bands the same colour and glyph on any two-band map. */
  /* Keyed off DERIVED status, not an authored badge. A hand-written R1/R2
     ordinal duplicated the RFC identity and collided with it — two different
     RFCs both reading "R1" is what made rows and RFCs look like different
     things (ADR-103: a row IS an RFC). */
  /* What a row is CALLED. Under ADR-103 a row IS an RFC, so wherever a problem
     has proposed the row it carries an RFC id and that id is the label.

     There is deliberately no "RFC not yet allocated" state. If a row is an RFC,
     drawing it is what allocates the identity — a pending-allocation label
     describes a step that does not exist and re-teaches the two-tier model this
     decision removed. A row without an id is not waiting for one; it is either
     speculative (nobody has asked for it, so there is nothing to propose) or it
     predates RFC numbering. */
  function rowLabel(release) {
    if (release.rfc) return release.rfc;
    return String(release.status || '').toLowerCase() === 'delivered'
      ? 'Delivered, pre-RFC'
      : 'Speculative';
  }

  function badgeClass(release) {
    switch (String(release.status || '').toLowerCase()) {
      case 'delivered':  return 'b-live';
      case 'proposed':   return 'b-next';
      default:           return 'b-later';   /* unproposed */
    }
  }

  function badge(cls, text) {
    var span = el('span', { class: 'badge ' + cls });
    span.appendChild(el('span', { class: 'b-glyph', 'aria-hidden': 'true' }, BADGE_GLYPH[cls] || ''));
    span.appendChild(document.createTextNode(text));
    return span;
  }

  /* Hrefs come from the derived island: the renderer resolved them against the
     docs tree, because only it knows which lifecycle directory an artefact
     currently sits in. No href — a map opened outside a repository, or an id
     that does not resolve — degrades to the plain text it wraps. */
  var HREFS = {};

  function link(id, node) {
    var href = id && HREFS[id];
    if (!href) return node;
    var a = el('a', { href: href, class: 'ref-link' });
    a.appendChild(node);
    return a;
  }

  /* Turn every artefact id in a run of text into a link, leaving the rest of
     the text alone. */
  function linkify(parent, text) {
    var re = /\b(?:ADR|JTBD|RFC|STORY-MAP|STORY|P)-?\d+\b/g;
    var last = 0, m;
    while ((m = re.exec(text)) !== null) {
      if (m.index > last) parent.appendChild(document.createTextNode(text.slice(last, m.index)));
      parent.appendChild(link(m[0], document.createTextNode(m[0])));
      last = m.index + m[0].length;
    }
    if (last < text.length) parent.appendChild(document.createTextNode(text.slice(last)));
  }

  /* Append a run list — {t, em} pairs from the renderer — as text nodes and
     <strong> elements. Data in, DOM out: nothing here parses or injects markup,
     so a story body cannot become HTML. */
  function appendRuns(parent, list) {
    (list || []).forEach(function (r) {
      var node = document.createTextNode(r.t);
      parent.appendChild(r.em ? el('strong', null, r.t) : node);
    });
  }

  /* A value statement, as three lines rather than one paragraph.
     It is written "In order to X, as a Y, I want Z"; run together it reads as a
     wall of text at card width, and the shape that makes it scannable is the
     shape it was written in.

     Emphasis is whatever the STORY marks. An earlier version guessed at a
     persona to bold; across the corpus authors emphasise the capability and
     never the persona, so guessing overrode what they had already said
     mattered. The persona line still reads as its own line — that is
     structural, and it does not require inventing bold nobody wrote. */
  function valueBlock(v) {
    var wrap = el('span', { class: 't-value' });
    if (v.raw || !v.value) {
      var only = el('span', { class: 'v-line' });
      appendRuns(only, v.raw || []);
      wrap.appendChild(only);
      return wrap;
    }
    [['In order to ', v.value, 'v-inorder'],
     ['as a ',        v.who,   'v-asa'],
     ['I want ',      v.want,  'v-iwant']].forEach(function (part) {
      var line = el('span', { class: 'v-line ' + part[2] });
      line.appendChild(el('span', { class: 'v-lead' }, part[0]));
      appendRuns(line, part[1]);
      wrap.appendChild(line);
    });
    return wrap;
  }

  function card(task, status, value) {
    var attrs = { class: 'task' };
    if (task.storyId) attrs['data-story-id'] = task.storyId;
    if (task.rfc) attrs['data-rfc'] = task.rfc;
    if (task.jtbd) attrs['data-jtbd'] = task.jtbd;
    if (status) attrs['data-status'] = status;
    var div = el('div', attrs);
    div.appendChild(link(task.storyId, el('span', { class: 't-title' }, task.title || '')));
    /* Value is DERIVED from the story's own `## User value` section, never
       authored on the card — a stored copy drifts, and every one on this map
       had drifted into a paraphrase while the stories carried proper
       value-first statements. */
    if (value) div.appendChild(valueBlock(value));
    if (task.ref) {
      var ref = el('span', { class: 't-ref' });
      ref.appendChild(document.createTextNode('Traces: '));
      linkify(ref, task.ref);
      div.appendChild(ref);
    }
    return div;
  }

  function build(data, derived) {
    var backbone = data.backbone || [];
    var releases = data.releases || [];
    var tasks = data.tasks || [];
    derived = derived || {};
    var statuses = derived.status || {};
    var values = derived.values || {};
    /* Row status is derived by the renderer, which can read story files; the
       browser cannot. An unrendered map shows every row as unproposed, which is
       the honest answer rather than a stale stored one. */
    var rowStatuses = derived.rows || {};
    releases = releases.map(function (r) {
      var c = {}; for (var k in r) if (Object.prototype.hasOwnProperty.call(r, k)) c[k] = r[k];
      c.status = rowStatuses[r.id] || 'unproposed';
      return c;
    });

    var table = el('table', { class: 'map' });
    table.appendChild(el('caption', null, data.caption ||
      backbone.length + ' journey activities across the top; ' +
      releases.length + ' release bands down the side. ' +
      'Read a row left to right for everything that ships in one release. ' +
      'A cell with no cards means that activity ships nothing in that release.'));

    var thead = el('thead');
    var hrow = el('tr');
    hrow.appendChild(el('td', { class: 'corner' }));
    backbone.forEach(function (a) {
      var th = el('th', { class: 'act', scope: 'col' }, a.title || '');
      // Explicit boundary: without it the accessible name concatenates as
      // "A. NoticeJTBD-008". The spaces the other sites rely on come from
      // display:block, which the accessible-name spec does not mandate.
      if (a.note) { th.appendChild(document.createTextNode(' ')); th.appendChild(el('span', { class: 'jtbd' }, a.note)); }
      hrow.appendChild(th);
    });
    thead.appendChild(hrow);
    table.appendChild(thead);

    var tbody = el('tbody');
    releases.forEach(function (rel) {
      var tr = el('tr');
      var cls = badgeClass(rel);
      var th = el('th', { class: 'slice', scope: 'row' });
      /* The row IS the RFC (ADR-103), so its id is the headline. A row nothing
         has proposed yet says so plainly rather than borrowing an ordinal. */
      th.appendChild(badge(cls, rowLabel(rel)));
      th.appendChild(document.createTextNode(' '));
      th.appendChild(link(rel.rfc, el('span', { class: 's-name' }, rel.name || '')));
      if (rel.note) { th.appendChild(document.createTextNode(' ')); th.appendChild(el('span', { class: 's-note' }, rel.note)); }
      tr.appendChild(th);

      var filled = backbone.map(function (act) {
        return tasks.filter(function (t) { return t.activity === act.id && t.release === rel.id; });
      });

      /* A wholly empty band is silent in a screen reader's browse mode while
         being a loud full-width hatch visually. One spanning cell states it
         once — per-cell text would bury a sparse map's few cards. */
      if (filled.every(function (h) { return h.length === 0; })) {
        var span = el('td', { class: 'cell empty', colspan: String(backbone.length || 1) });
        span.appendChild(el('span', { class: 'vh' }, 'No stories in this release band.'));
        tr.appendChild(span);
      } else {
        filled.forEach(function (here) {
          if (!here.length) { tr.appendChild(el('td', { class: 'cell empty' })); return; }
          var td = el('td', { class: 'cell' });
          var ul = el('ul', { class: 'tasks', role: 'list' });
          here.forEach(function (t) {
            var li = el('li');
            li.appendChild(card(t, statuses[t.storyId], values[t.storyId]));
            ul.appendChild(li);
          });
          td.appendChild(ul);
          tr.appendChild(td);
        });
      }
      tbody.appendChild(tr);
    });
    table.appendChild(tbody);
    return { table: table, releases: releases };
  }

  function render() {
    var data = readJSON('story-map-data');
    var mount = document.getElementById('story-map');
    if (!mount) return;
    if (!data) {
      mount.textContent =
        'This map could not be drawn: its data block is missing or is not valid JSON.';
      return;
    }
    var derived = readJSON('story-map-status') || {};
    HREFS = derived.hrefs || {};
    var built;
    try {
      built = build(data, derived);
    } catch (e) {
      mount.textContent = 'This map could not be drawn from its data block: ' + e.message;
      return;
    }
    mount.textContent = '';

    var fullTitle = (data.storyMapId ? data.storyMapId + ': ' : '') + (data.title || '');
    if (fullTitle.trim()) document.title = fullTitle;
    var h1 = document.getElementById('story-map-title');
    var heading = data.title || data.storyMapId || '';
    if (h1 && heading) h1.textContent = heading;
    var lead = document.getElementById('story-map-lead');
    if (lead && data.lead) { lead.textContent = ''; linkify(lead, data.lead); }

    var legend = document.getElementById('story-map-legend');
    if (legend) {
      built.releases.forEach(function (rel) {
        var li = el('li');
        li.appendChild(badge(badgeClass(rel), rowLabel(rel)));
        li.appendChild(document.createTextNode(' ' + (rel.name || '')));
        if (rel.note) li.appendChild(document.createTextNode(' — ' + rel.note));
        legend.appendChild(li);
      });
    }

    var scroll = el('div', {
      class: 'scroll', tabindex: '0', role: 'region', 'aria-label': 'Story map grid'
    });
    scroll.appendChild(built.table);
    mount.appendChild(scroll);

    var trace = document.getElementById('story-map-trace');
    var prose = data.traceProse || {};
    var traceSection = document.getElementById('story-map-trace-section');
    if (trace) {
      var wrote = false;
      [['Persona', prose.persona], ['Jobs mapped', prose.jobs],
       ['Problems this closes', prose.problems],
       ['Decisions the journey rests on', prose.decisions],
       ['Open questions', prose.open]].forEach(function (pair) {
        if (!pair[1]) return;
        var p = el('p');
        p.appendChild(el('strong', null, pair[0] + ':'));
        p.appendChild(document.createTextNode(' '));
        linkify(p, pair[1]);
        trace.appendChild(p);
        wrote = true;
      });
      // A named landmark with nothing in it, under a visible heading, is worse
      // than no landmark. Reveal it only once it holds something.
      if (wrote && traceSection) traceSection.removeAttribute('hidden');
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', render);
  } else {
    render();
  }
})();
