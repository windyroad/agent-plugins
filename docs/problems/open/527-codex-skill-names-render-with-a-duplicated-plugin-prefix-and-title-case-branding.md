# Problem 527: Codex skill names render with a duplicated plugin prefix and title-case branding

**Status**: Open
**Reported**: 2026-08-29
**Priority**: 15 (High) — Impact: 3 × Likelihood: 5 — derived at capture. Impact 3: the name Codex shows a user is not a name they can type. `$wr-itil:wr-itil:work-problems` fails as an invocation, and the display form `Wr Itil:wr Itil:work Problems` misspells the product name in the one place an adopter reads it most. This is discovery and invocation friction on the published surface, not data loss — no ticket, decision, or repository state is corrupted by it. Likelihood 5: it is a property of the projection output, not of any particular session, so it holds for every skill in every Codex install of the plugin.
**Origin**: internal
**Effort**: S — derived at capture. The generated frontmatter `name:` is one field written by one transform; the fix is to decide the single form Codex should receive (bare `work-problems` so Codex namespaces it once, or a display-cased `WR ITIL: Work Problems`) and stop emitting the other. Add one check that parses every generated frontmatter `name:` and asserts the prefix appears at most once. Sized alongside P526, which touches the same file for the same reason — cf. P526.
**WSJF**: 15 — (15 × 1.0) / 1
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

The installed Codex surface renders WR ITIL skill invocations and cards with a duplicated plugin prefix and title-case branding — for example `$wr-itil:wr-itil:work-problems` as the invocation string and `Wr Itil:wr Itil:work Problems` as the card title.

Neither form is correct. The surface must render either the invocation form `wr-itil:work-problems` or the human display form `WR ITIL: Work Problems`, with no duplicate prefix and no `Wr Itil` capitalization.

## Symptoms

- Skill invocation strings shown in Codex carry the plugin prefix twice: `wr-itil:wr-itil:<skill>`.
- Skill cards title-case the whole name, producing `Wr Itil:wr Itil:work Problems` — the product name renders as `Wr Itil` rather than `WR ITIL`.
- The displayed invocation cannot be typed as shown.

## Workaround

Invoke the skill by its single-prefix name (`wr-itil:work-problems`) rather than the string the card displays.

## Impact Assessment

- **Who is affected**: Codex users of `@windyroad/itil`, on every skill the plugin ships.
- **Frequency**: every Codex projection build and every install of it.
- **Severity**: High — the published invocation surface is wrong for all skills, and the branding is wrong on every card.
- **Analytics**: (deferred to investigation — count the generated `skills-codex/*/SKILL.md` frontmatter `name:` values that carry a prefix Codex will duplicate.)

## Root Cause Analysis

Provisional, to confirm at investigation. `packages/itil/scripts/sync-codex-skills.mjs` copies each source skill's frontmatter into `skills-codex/<skill>/SKILL.md` without rewriting `name:`. The source frontmatter already carries the plugin-qualified form — `packages/itil/skills/work-problems/SKILL.md` line 2 is `name: wr-itil:work-problems` — while the generated skill lives in a directory Codex itself namespaces by plugin. Codex therefore prepends `wr-itil:` a second time, and its display layer title-cases the resulting string word-by-word, yielding `Wr Itil:wr Itil:work Problems`.

Two runtimes disagree about who owns the prefix, and the projection asserts neither answer.

### Investigation Tasks

- [ ] Confirm the double prefix originates in Codex namespacing a `name:` that already carries the prefix, rather than in the projection transform itself.
- [ ] Decide the single form the generated frontmatter should carry — bare skill name (let Codex namespace once) or explicit display form.
- [ ] Apply the same decision to the `architect` and `risk-scorer` projections, which run the same script shape.
- [ ] Add a behavioural check that parses every generated frontmatter `name:` and asserts the plugin prefix appears at most once.
- [ ] Verify against a clean Codex installation that cards and invocation strings render the chosen form.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P526 — same generator, same published build.

## Related

- **P526** (`docs/problems/open/526-codex-projection-sanitizer-corrupts-yaml-frontmatter.md`) — the other live defect in `packages/itil/scripts/sync-codex-skills.mjs`. Captured separately rather than folded in: P526 is the whole-file `sanitize()` pass injecting unescaped prose into YAML scalars, whereas this ticket is the `name:` field being correct YAML that carries a prefix the consuming runtime adds again. Different transform, different fix, and P526's fix (keep frontmatter out of prose sanitisation) does not touch the prefix. They should land together if both are worked in one pass.
- **P477** (`docs/problems/known-error/477-codex-interrupt-agent-completion-bypasses-risk-marker-bridge.md`) — separate Codex-runtime defect; no shared mechanism.
- **P298** (`docs/problems/open/298-published-artifacts-should-not-reference-internal-ids-at-all-not-just-prefix-them.md`) — adjacent published-artefact-surface concern; different axis (internal IDs, not skill names).

(captured via /wr-itil:capture-problem; expand at next investigation)
