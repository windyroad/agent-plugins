# Voice and Tone Guide

## Purpose

This project (`windyroad-claude-plugin`) is a plugin-development monorepo publishing `@windyroad/*` Claude Code plugins covering governance, risk management, ITIL, TDD, JTBD, retrospectives, and delivery quality.

The audience for HTML / copy-bearing content in this repo is **internal**: plugin maintainers, contributors, and adopters reading reference documentation. Story maps (`docs/story-maps/**/*.html`), README files, and CHANGELOG entries are the primary surfaces.

## Audience

- **Solo developers** building plugins, consuming the framework's primitives day-to-day.
- **Plugin developers / tech leads** extending the suite — atomic-fix-adopters and multi-commit-coordination-adopters.
- **Plugin users** reading shipped plugin READMEs and intake template prompts.

## Voice principles

1. **Precise over flowery** — engineering primitives have exact meanings; use the right word, not the prettier word. `RFC` is `RFC`, not `change proposal`.
2. **Active over passive** — `the skill writes the file` not `the file is written by the skill`. Names the actor; reveals responsibility.
3. **Specific over abstract** — cite ADR / problem / story IDs by number in **source-internal** documents (`docs/**`). **Never in shipped artefacts** — anything under `packages/**` that reaches an adopter, including template copy and any text a renderer emits into an adopter's repository. There, state the substance inline: `the renderer overwrites this file`, not `per ADR-102`. In source-internal docs, `Per ADR-060 line 252` beats `Per the architecture decision`. Prefixed forms (`WR-ADR-102`) do not satisfy the shipped-artefact rule; that mechanism was rejected (P298).
4. **Plain over jargon-rich** — explain ITIL / Patton / WSJF terms when they first appear; assume the reader knows code but not the framework yet.
5. **Honest about deferral** — when work is partial or blocked, say so explicitly. `Slice 14 blocked on marketplace release` not `Slice 14 in progress`.

## Tone guidance

- **Conversational where appropriate** — SKILL.md prose addresses an LLM agent reading the contract; "you" / "the agent" / "the skill" forms are clear.
- **Authoritative for invariants** — `I7 hard-blocks at accepted` is a contract; the prose says so directly.
- **Neutral on choices** — when two paths exist (e.g. atomic-RFC fallback vs. story-decomposed), name both without preferring one; let the reader's context drive selection.

## Banned patterns

- **Marketing speak**: "powerful", "seamless", "robust", "industry-leading", "best-in-class" — meaningless for engineering primitives; remove.
- **Hedging without payoff**: "might", "could potentially", "may help" without naming the condition; replace with `When <condition>, <outcome>` or remove.
- **Apologetic prose**: "unfortunately", "sadly", "we regret" — neutral facts are better than apologies. The user prefers honest deferral over performative apology.
- **Implicit second-person commands without subject**: "Just run this" — name what `just` modifies, name the actor.

## Word list

| Prefer | Avoid |
|--------|-------|
| `problem` | `bug`, `issue`, `defect` (in framework contexts; reserve for specific surfaces) |
| `RFC` | `change proposal`, `change request` |
| `story` | `task`, `ticket`, `card` (in story-tier contexts; tasks are Phase 1 placeholder) |
| `traceable to` | `owned by`, `belongs to`, `under` |
| `hard-block` | `prevent`, `disallow`, `forbid` (when the invariant is gate-enforced) |
| `lightweight aside` / `heavyweight intake` | `simple skill` / `full skill` |
| `JTBD` (acronym) | `Job To Be Done` (acronym is universally understood in the framework) |
| `fail-open` / `fail-closed` | `permissive` / `strict` (when describing gate behaviour) |

## HTML content (story-maps)

Story maps are generated. Each map carries its own data in a `<script id="story-map-data" type="application/json">` island and is rendered by `wr-itil-render-story-map`; presentation and the template's own fixed copy live in `packages/itil/templates/story-map.html`. **Voice review reads the data island** — the surrounding HTML is a build artefact and is never hand-edited.

- **Map title** (`title` in the island; rendered as `<title>` and `<h1>`): short noun phrase naming the journey, not the change. `Ship through a scored path`, not `Fix the push gate`.
- **Backbone activity titles** (`backbone[].title`; rendered as `<th class="act" scope="col">`): imperative or verb phrase in the persona's voice, naming a step they walk through — `Get it assessed`, `Release it`. The backbone must read as a sequence; a column of invariants is not a journey. *(Amended 2026-08-04: the original rule demanded bare nouns — `Capture` / `Validate` / `Verify` — which contradicted every map then authored and was flagging the whole compliant corpus.)*
- **Task titles** (`tasks[].title`; rendered in `<div class="task">`): what the persona can now do, in their voice. Pair with `value`, which states why it matters to them and opens `Value:`.
- **Lead paragraph** (`lead`; rendered as `<p class="lead">`): opens `A story map for the <persona> who …`, and **must name both grid axes** — read across the top for the journey, down the rows for release bands. A lead that says "read the ribs top to bottom" is describing the superseded encoding.
- **Trace prose** (`traceProse.*`; rendered into `<section class="trace">`): editorial third person, author speaking to a future maintainer. Carries provenance, scope and honest deferral. Record facts rather than directing a future editor's conclusion. Internal IDs are fine here — a map is source-internal.
- **Empty bands**: a map may legitimately render with columns and rows but few filled cells. Say so in the lead; an almost-empty grid otherwise reads as a rendering failure.
- **One name per actor** across a map: pick `the gate` or `the tool`, not both. Prefer `hard-block` over `prevent` / `disallow` / `forbid` where the invariant is gate-enforced; plain `block` is fine in narrative prose. Lead a task with the outcome, not the mechanism.
- **No marketing speak** in the title or `<meta>` blocks; same banned patterns as Markdown surfaces. This includes unsupported ranking claims — `the gate family every commit and push traverses`, not `the most load-bearing gate family in the suite`.
- **Plain language**, and explain framework vocabulary on first use — `within the risk appetite set in RISK-POLICY.md`, not a bare `within appetite`.
- **Template fixed copy is adopter-facing.** The generated-file banner, the legend label and section headings ship in the plugin and are rendered into adopter repositories. **No internal IDs there** (see principle 3) — state the substance instead.
- **Re-read the island's prose fields end to end** after editing, not just the changed sentence. These accrete across review rounds, and the recurring defect is a clean inserted sentence with a broken seam around it — a dangling pronoun, or a coordination that reattaches. Diffs hide it; a continuous read surfaces it.

## Scope

This guide applies to:
- Story maps — the `<script id="story-map-data">` island inside `docs/story-maps/**/*.html`, which is the authored surface; the surrounding markup is generated
- `packages/itil/templates/story-map.html` — the shipped template's own fixed copy, and every string it renders into an adopter's repository
- JSX / TSX / Vue / Svelte components if any UI ships from this repo (currently none — plugin-development monorepo)
- ejs / hbs templates if any ship (currently none)
- Changesets (`.changeset/*.md`) per ADR-028 — author-time gate on `PreToolUse:Write/Edit`. Both voice-tone + risk-scorer evaluators fire; voice-tone catches AI-tells / brand-voice drift before the body reaches CHANGELOG.md / Release PRs / GitHub Releases / published npm tarballs. Closed under P073.

It does NOT apply to:
- Markdown documentation (covered by per-skill SKILL.md guidance + project CLAUDE.md)
- Commit messages (covered by ADR-014 + ADR-018)

## Related

- **ADR-051** — JTBD-anchored README rule; voice guide composes with that.
- **ADR-060 amendment 2026-05-12**, as amended by **ADR-102** (2026-08-05) — story maps are a rendered grid whose data lives in an island; this guide names voice rules for that surface.
- **CLAUDE.md** — project guidance; voice rules echo the MANDATORY rules there (e.g. "act on obvious, AskUserQuestion for ambiguous, NEVER prose-ask").
- **JTBD-302** — Trust That the README Describes the Plugin I Just Installed; voice rules support that trust by keeping prose honest about deferral and explicit about contracts.
- **JTBD-101** — Plugin developer extends the suite; voice rules favour the plain-language + plain-imperative shape that helps adopters extend confidently.
