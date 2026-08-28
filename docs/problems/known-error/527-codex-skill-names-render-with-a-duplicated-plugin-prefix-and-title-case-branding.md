# Problem 527: Codex skill names render with a duplicated plugin prefix and title-case branding

**Status**: Known Error
**Reported**: 2026-08-29
**Priority**: 15 (High) — Impact: 3 × Likelihood: 5 — derived at capture. Impact 3: the name Codex shows a user is not a name they can type. `$wr-itil:wr-itil:work-problems` fails as an invocation, and the display form `Wr Itil:wr Itil:work Problems` misspells the product name in the one place an adopter reads it most. This is discovery and invocation friction on the published surface, not data loss — no ticket, decision, or repository state is corrupted by it. Likelihood 5: it is a property of the projection output, not of any particular session, so it holds for every skill in every Codex install of the plugin.
**Origin**: internal
**Effort**: S — derived at capture. The generated frontmatter `name:` is one field written by one transform; the fix is to decide the single form Codex should receive (bare `work-problems` so Codex namespaces it once, or a display-cased `WR ITIL: Work Problems`) and stop emitting the other. Add one check that parses every generated frontmatter `name:` and asserts the prefix appears at most once. Sized alongside P526, which touches the same file for the same reason — cf. P526.
**WSJF**: 15 — (15 × 1.0) / 1
**JTBD**: JTBD-302
**Persona**: plugin-user

## Description

The installed Codex surface renders WR ITIL skill invocations and cards with a duplicated plugin prefix and title-case branding — for example `$wr-itil:wr-itil:work-problems` as the invocation string and `Wr Itil:wr Itil:work Problems` as the card title.

Neither form is correct. The surface must render either the invocation form `wr-itil:work-problems` or the human display form `WR ITIL: Work Problems`, with no duplicate prefix and no `Wr Itil` capitalization.

## Symptoms

- Skill invocation strings shown in Codex carry the plugin prefix twice: `wr-itil:wr-itil:<skill>`.
- Skill cards title-case the whole name, producing `Wr Itil:wr Itil:work Problems` — the product name renders as `Wr Itil` rather than `WR ITIL`.
- The displayed invocation cannot be typed as shown.

## Workaround

Invoke the skill by its single-prefix name (`wr-itil:work-problems`) rather than the string the card displays. Codex resolves the single-prefix form even while it advertises the doubled one, so no skill is unreachable — only mis-advertised.

## Impact Assessment

- **Who is affected**: Codex users of every `@windyroad/*` plugin that ships skills — not `@windyroad/itil` alone.
- **Frequency**: every Codex session, on every skill, for every install.
- **Severity**: High — the published invocation surface is wrong for all skills, and the branding is wrong on every card.
- **Analytics**: measured 2026-08-29 against a live Codex install via `codex debug prompt-input` (see Evidence). **56 of 56** windyroad skills carry the doubled prefix, across **10 of 10** windyroad plugins that ship skills for Codex: wr-itil 28, wr-risk-scorer 10, wr-architect 4, wr-jtbd 3, wr-retrospective 3, wr-c4 2, wr-connect 2, wr-voice-tone 2, wr-style-guide 1, wr-tdd 1. **Zero** of the unaffected third-party plugins in the same list are affected — 11 skills across two of them, every one single-prefix.

## Root Cause Analysis

**Confirmed 2026-08-29.** Codex uses the plugin manifest's `name` as the component namespace and prepends it to each skill's own frontmatter `name:`. Its bundled `plugin-creator` skill states this directly in `references/plugin-json-spec.md`: `name` is *"Required if `plugin.json` is provided and used as manifest name and component namespace."* The unaffected third-party skills in the same list all follow that contract with a bare frontmatter `name:` — their SKILL.md carries the skill name alone, and Codex renders it with exactly one prefix.

The windyroad skill sources instead carry the plugin-qualified form (`packages/itil/skills/work-problems/SKILL.md` line 2 is `name: wr-itil:work-problems`), and the Codex projection copies that field through unchanged. Codex therefore namespaces an already-namespaced name and the display layer title-cases the result word-by-word, yielding `Wr Itil:wr Itil:work Problems`.

Claude Code tolerates the same source because it normalises a redundant `<plugin>:` prefix rather than doubling it — which is why the defect never surfaced on the runtime the sources were authored against. Two runtimes disagree about who owns the prefix, and the projection asserts neither answer.

The correct form for the Codex-facing frontmatter is therefore the **bare skill name**; the human-readable branding is already carried, correctly, by each skill's `agents/openai.yaml` `display_name` (`WR ITIL: Work Problems`). Those values are correct and must not be touched.

### Evidence

`codex debug prompt-input` renders the exact model-visible skill list from the installed artefact — the same names the invocation surface offers:

```text
- <third-party>:<skill>: ...                        (bare source name, single prefix)
- wr-itil:wr-itil:work-problems: ...                (prefixed source name, doubled)
- wr-architect:wr-architect:create-adr: ...         (prefixed source name, doubled)
- wr-risk-scorer:wr-risk-scorer:assess-release: ... (prefixed source name, doubled)
```

Installed artefact inspected: the Codex plugin cache copy of `skills-codex/work-problems/SKILL.md` at the currently installed version, which carries `name: wr-itil:work-problems` alongside a correct sibling `agents/openai.yaml` (`display_name: "WR ITIL: Work Problems"`).

### Investigation Tasks

- [x] Confirm the double prefix originates in Codex namespacing a `name:` that already carries the prefix, rather than in the projection transform itself. **Confirmed** — see Evidence; Codex's own spec documents `name` as the component namespace.
- [x] Decide the single form the generated frontmatter should carry — bare skill name (let Codex namespace once) or explicit display form. **Decided: bare skill name.** It is the documented Codex contract, it is what every unaffected third-party plugin does, and the display form is already carried separately and correctly by `agents/openai.yaml` `display_name`.
- [ ] Apply the same decision to the `architect` and `risk-scorer` projections, which run the same script shape.
- [ ] Add a behavioural check that parses every generated frontmatter `name:` and asserts the plugin prefix appears at most once. It must exercise the generator and assert on its output rather than grep the sources (ADR-052).
- [ ] Verify against a clean Codex installation that cards and invocation strings render the chosen form. The **invocation half** is now measurable here — `codex debug prompt-input` renders the model-visible list from the installed artefact — so it can be re-run after the fix ships. The **card-title half is not locally observable**; see Residual scope.

## Fix Strategy

RFC-074 — *The name on the card is the name that works* — a release row on STORY-MAP-008 (*Have a plugin behave like a guest in my repository*) under activity B *Read what it claims*, carrying one delivery story, STORY-068 (*Invoke a Codex skill by the name the card shows*, accepted). Neither is implemented yet.

The shape the row carries: rewrite the Codex-facing frontmatter `name:` to the bare skill directory name inside the projection transform of each package that has one. The runtime-neutral sources under `packages/*/skills/` keep their prefixed `name:` — Claude Code normalises it, roughly twenty existing contract tests assert it, and nothing about the Claude surface changes.

## Residual scope

Two things the fix above will not reach, recorded here rather than as sibling tickets:

1. **Seven packages will have no projection to fix.** `c4`, `connect`, `jtbd`, `retrospective`, `style-guide`, `tdd`, and `voice-tone` point `.codex-plugin/plugin.json` `skills` straight at the shared `./skills/` directory, so the only lever on their Codex-facing `name:` is the source field both runtimes read. That is 14 of the 56 doubled skills. Closing them needs either a per-package projection directory or a source-name change that reddens the existing contract tests — a design decision, not an `S`-sized edit.
2. **The card-title capitalization is runtime-only and will stay unverifiable from here.** `codex debug prompt-input` exposes the model-visible name, not the UI card label, so the title-casing half of this ticket can only be confirmed by looking at a Codex card. The plugin already ships the correct `display_name` in the documented location (`<skill>/agents/openai.yaml`, exactly where Codex's own `plugin-creator` skill puts it), and the card still title-cased the namespaced id — which suggests the card composes the id rather than reading `display_name`. If the card still reads `Wr Itil:work Problems` once the fix ships, the remaining defect is in Codex's display layer, not in this repository, and the next step is an upstream report rather than another local change.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P526 — same generator, same published build.

## Related

- **P526** (`docs/problems/open/526-codex-projection-sanitizer-corrupts-yaml-frontmatter.md`) — the other live defect in `packages/itil/scripts/sync-codex-skills.mjs`. Captured separately rather than folded in: P526 is the whole-file `sanitize()` pass injecting unescaped prose into YAML scalars, whereas this ticket is the `name:` field being correct YAML that carries a prefix the consuming runtime adds again. Different transform, different fix, and P526's fix (keep frontmatter out of prose sanitisation) does not touch the prefix. They should land together if both are worked in one pass.
- **P477** (`docs/problems/known-error/477-codex-interrupt-agent-completion-bypasses-risk-marker-bridge.md`) — separate Codex-runtime defect; no shared mechanism.
- **P298** (`docs/problems/open/298-published-artifacts-should-not-reference-internal-ids-at-all-not-just-prefix-them.md`) — adjacent published-artefact-surface concern; different axis (internal IDs, not skill names).

(captured via /wr-itil:capture-problem; investigated to Known Error 2026-08-29 — no fix landed yet)


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-068 | STORY-068: Invoke a Codex skill by the name the card shows | accepted |
