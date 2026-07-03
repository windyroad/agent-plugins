# Problem 412: RFC / Story / Story-map framework tiers are invisible to adopters — no scaffold, no nudge, no discoverable entry point

**Status**: Open
**Reported**: 2026-07-03
**Priority**: 6 (Medium) — Impact: 3 x Likelihood: 3 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

An adopter project (**bbstats**, itil 0.56.0, all windyroad plugins enabled)
uses the plugin's problem + ADR + JTBD tiers actively (7 problems, 63 ADRs, 7
jobs) but has **never entered the RFC / Story / Story-map tiers** — the
`docs/rfcs/`, `docs/stories/`, and `docs/story-maps/` directories do not exist
at all. The maintainer noticed: *"It's using the new plugin, but I'm not
seeing user story maps or RFCs."*

**Root observation (2026-07-03):** the capability is present — cached itil
0.56.0 ships `capture-rfc`, `manage-rfc`, `capture-story`, `manage-story`,
`capture-story-map`, `manage-story-map`, `list-story-maps`,
`reconcile-story-maps`. But the tiers are:

1. **Created lazily on first skill invocation** — the directories only appear
   when the adopter runs one of the capture/manage skills. There is no
   scaffolding step on plugin adoption that creates them or seeds a README.
2. **Un-nudged** — nothing tells an adopter these tiers exist. The problem
   skeleton even emits an unchecked task `- [ ] Create INVEST story for
   permanent fix` (observed on bbstats problem 001), which *points at* the
   story tier but nothing scaffolds it, prompts it, or fails visibly when it
   is skipped. The task just sits unchecked forever.
3. **Silent on an empty tree** — `list-story-maps` / `list-stories` /
   `list-rfcs` on a project that never entered the tier render nothing, so an
   adopter exploring the surface sees no signal that the tier is available.

The net effect: the RFC-first / Problem-RFC-Story framework (the plugin's
flagship governance model) is effectively **opt-in-by-insider-knowledge**. An
adopter who does not already know to run `/wr-itil:capture-rfc` never
discovers the tier, and the problem-skeleton's story-trace tasks become dead
checkboxes.

**Scope boundary:** the windyroad repo's own "every fix goes through an RFC"
(ADR-071) is this plugin repo's *internal* governance and is intentionally NOT
auto-enforced on adopters (adopters get skills, not windyroad's ADRs). This
ticket is NOT about forcing RFC-first on adopters — it is about **making the
tier discoverable** so an adopter who wants it can find and start it, and so
the problem-skeleton's story-trace tasks are actionable rather than dangling.

## Symptoms

- bbstats: `docs/rfcs/`, `docs/stories/`, `docs/story-maps/` all absent despite
  the itil plugin being enabled and actively used for problems + ADRs.
- Problem-skeleton `- [ ] Create INVEST story` tasks sit unchecked with no
  scaffolding/nudge to action them.

## Workaround

Run `/wr-itil:capture-rfc` / `/wr-itil:capture-story-map` / `/wr-itil:capture-story`
manually in the adopter project — the first invocation creates the directory.
Requires the adopter to already know the skills exist.

## Impact Assessment

- **Who is affected**: plugin adopters (bbstats and any downstream project); the flagship RFC/Story framework goes unused.
- **Frequency**: every adopter project that hasn't been told about the tiers.
- **Severity**: (deferred to investigation)
- **Analytics**: bbstats — 3 of 3 framework tiers (RFC/Story/Story-map) empty after active plugin use.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Decide the surfacing mechanism: SessionStart nudge (compose with P297's scaffold-as-SessionStart-hook direction) vs. a scaffold step vs. a list-skill empty-state pointer vs. problem-skeleton task hyperlinking the skill
- [ ] Reconcile with the "adopters get skills not ADRs" boundary — the surface must invite, not enforce (contrast ADR-071 RFC-first which is windyroad-internal)
- [ ] Consider whether `list-story-maps`/`list-stories`/`list-rfcs` should render an empty-state "no entries yet — run /wr-itil:capture-rfc to start" hint

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P297 (governance-artefact scaffold as SessionStart hook — same "adopter doesn't get the artefact/tier automatically" class); P375 (named re-entry ≠ self-firing cadence — the story-trace task names a re-entry nothing fires); P395 (silently-dormant capability with no nudge)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- **Silent/no-surface class siblings:** P297 (`docs/problems/open/297-...`), P375 (`docs/problems/known-error/375-...`), P395 (`docs/problems/open/395-...`).
- **P170** (`docs/problems/known-error/170-...`) — RFC framework driver; the tier this ticket wants surfaced.
- **ADR-060** — Problem-RFC-Story framework (the tiers in question).
- **ADR-071** — every-fix-through-an-RFC (windyroad-internal; the enforcement this ticket explicitly does NOT extend to adopters).
- **Origin evidence:** bbstats (`/Users/tomhoward/Projects/bbstats`) — itil 0.56.0, problems/jtbd/decisions populated, rfcs/stories/story-maps absent; problem 001 carries a dangling `Create INVEST story` task.


## Reframe — folded into the ADR-073/P399 work-problems rework (2026-07-03)

**User correction (2026-07-03):** *"The work problems process is supposed to
create the RFC and the story map if it's missing... RFC and USM creation should
not need 'activation'. Just follow the fucking work problems process."*

The initial fix attempt (RFC-040 — a build-time "declare-discoverability-surface"
invariant + a runtime governance-surface-activation nudge) was **over-engineered
and withdrawn** (`git rm`, 2026-07-03). It invented a new mechanism instead of
following/fixing the existing process.

**Root cause (confirmed by investigation):** the `/wr-itil:work-problems` process
IS already supposed to create the RFC — **and an RFC is stories in a user story
map** (ADR-060/089/090) — when a fix begins on an RFC-less Known Error (ADR-071 +
the I13 propose-fix gate). But that auto-create mechanism is **HELD, not shipped**:
ADR-073 was rewritten + re-confirmed 2026-06-29 ("an RFC is stories in a user
story map, NOT a Scope+Tasks blob; 'auto-create at fix-time and never block' is
rejected; the P399 `capture-rfc --fix-time` mechanism is held pending rework"),
and the lockstep amendment (ADR-072 gate placement + ADR-060 I13 + the
`wr-itil-check-fix-rfc-trace` gate code) has NOT landed. So bbstats ran
work-problems but the RFC/story-map auto-create could not fire — that is why its
`docs/rfcs/`, `docs/stories/`, `docs/story-maps/` are empty. Same path the P357
iter hit this session.

**Fix vehicle (folded per user direction, option B):** complete the held
**ADR-073 / P399** rework so the work-problems process reliably creates the RFC
(as a story map) when missing. P412 is the adopter-facing symptom of that same
gap — NOT a separate discoverability feature. No new invariant, no activation
nudge.

- **Composes with**: P399 (ADR-073 auto-create emits skeleton RFC — should author full RFC / story map), P357 (I13 fix-time RFC blocked on the ADR-073 story-map lockstep), the ADR-072/ADR-060-I13 lockstep amendment.
- **Superseded approach**: RFC-040 (withdrawn 2026-07-03).
