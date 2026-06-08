---
"@windyroad/architect": minor
---

P354 Phase 1: name the title-as-outcome convention for ADR filenames at the two ADR-authoring SKILL surfaces.

`/wr-architect:create-adr` SKILL prose amended:

- New Step 2a "Title-as-outcome convention (P354)" — ADR titles must name the decision outcome as a short noun phrase (GOOD: `marketplace-only-distribution`, `monorepo-per-plugin-packages`, `behavioural-tests-default-for-skill-testing`), NOT the question / option-pair being decided (BAD: `<X>-vs-<Y>`, `should-<Z>`, `whether-<Z>`, `<X>-or-<Y>`). At intake the derived slug is acceptable in either shape — the convention is enforced post-substance-confirm.
- Step 2 dispatch table Title row points readers at the convention + the Step 5a retitle check.
- New Step 5a mechanical retitle-after-decision check — after the substance-confirm marker write lands, if the on-disk filename slug matches a question-shape pattern (`-vs-`, `should-`, `whether-`, `-or-`), derive the outcome slug from the chosen-option short name via `derive_kebab_slug`, edit the H1, `git mv` the file. ADR-044 category-4 silent-framework — no AskUserQuestion fire (per P132 inverse-P078 guard). Sequence preserves `architect-oversight-marker-discipline.sh` semantics (marker-introducing Edit lands BEFORE `git mv`; subsequent H1 Edit allowed by hook's "old content already had marker" branch).

`/wr-architect:capture-adr` SKILL prose amended:

- Step 1 names the same title-as-outcome convention. At the capture surface the chosen Decision is pinned in `$ARGUMENTS` at invocation time, so the caller SHOULD supply an outcome-shaped Title; if the parsed slug is question-shaped, the skill emits an I2-isomorphic stderr advisory (advisory-only — no halt, no retitle; the canonical-outcome short-name is the caller's to author).

Driver: user direction 2026-06-03 — *"ADR titles are supposed to be the short version of what was decided, so they are skimmable. Titles like this force the reader to read the document to find the details of what was decided."* P354 captures the recurring authoring habit.

Held in `docs/changesets-holding/` per ADR-042 Rule 2 (commit risk score 8/25 Medium above the 4/25 appetite — R009 SKILL-prose floor + R005 no-paired-release-coordination at this commit). Graduates per ADR-061 once Phase 2 paired-coverage (promptfoo Tier-A/B eval + behavioural bats for the title-as-outcome convention) lands and the residual risk drops to within appetite. Corpus currently has zero question-shaped titles (audit 2026-06-08); no historical sweep needed.
