---
status: "proposed"
date: 2026-04-20
human-oversight: confirmed
oversight-date: 2026-05-25
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-20
---

# Cross-project problem-reporting contract — `report-upstream` skill in `@windyroad/itil`

## Amendments

- **2026-06-09 (P080)** — Decision Outcome extended with a **bidirectional lifecycle-update contract** authorising a new sibling skill `/wr-itil:update-upstream` (packaged at `packages/itil/skills/update-upstream/`). Reciprocal sibling to `/wr-itil:report-upstream` per [ADR-010](./010-rename-wr-problem-to-wr-itil.proposed.md) amended Skill Granularity (initial-filing and lifecycle-update are distinct user intents with distinct autocomplete surfaces). User direction ratified verbatim 2026-04-26 (interactive AskUserQuestion resolution recorded inline in the P080 ticket body, `docs/problems/<state>/080-no-bidirectional-update-of-upstream-reported-problems.md`): (a) **new sibling skill**, NOT a mode flag on report-upstream; (b) **risk + voice-tone external-comms gated, then auto-comment within appetite; above-appetite triggers AskUserQuestion (interactive) or halt-with-report (AFK)** — the same dual-gate composition the post-P270 amendment uses for the initial-filing path; (c) **same external-comms gate composition pattern as inbound** (matches P079's assessment pipeline). The contract: when a local ticket carries a `## Reported Upstream` section (per Confirmation criterion 3a) and transitions through its lifecycle (Open → Known Error, Known Error → Verification Pending, Verification Pending → Closed), the sibling skill drafts a transition-specific lifecycle-update comment, scores the draft via `wr-risk-scorer:external-comms` and routes it through `wr-voice-tone:external-comms`, posts via `gh issue comment <n>` when both gates pass within appetite (and on Verifying → Closed also runs `gh issue close <n>` so the upstream tracker matches local `.closed.md` state), and back-writes an append-only `## Upstream Lifecycle Updates` log entry recording the transition + matched URL + posted comment URL + disclosure path. Above-appetite handling matches the post-P270 amendment shape: silent risk-reduce + re-score (per [ADR-042](./042-auto-apply-scorer-remediations-open-vocabulary.proposed.md) within-axis precedent for open-vocabulary risk-reducing measures generalised to the external-comms class), then if still above appetite queue an `outstanding_questions` entry (category: `deviation-approval`) and save the drafted comment to a new `## Queued Upstream Update` section (distinct from the initial-filing `## Queued Upstream Report` per the 2026-06-04 second-amendment leaf (c) — distinct sections so a single ticket can carry both without collision). The orchestrator continues per P352 queue-and-continue; do NOT halt the transition on an above-appetite upstream update. Trigger surface: `/wr-itil:transition-problem` Step 7b (new advisory subsection, fires unconditionally after the rename + README refresh and before the Step 8 commit; the sibling skill's no-op exit absorbs the common case of tickets with no `## Reported Upstream` section); `/wr-itil:manage-problem` in-skill Step 7's "Bidirectional upstream lifecycle update (P080 — advisory, copy-not-move from transition-problem Step 7b)" subsection (the ADR-010 amended "copy, not move" sibling for in-skill callers: Step 9b auto-transition, Step 9d closure inside review, the Parked path). [ADR-014](./014-governance-skills-commit-their-own-work.proposed.md) single-commit grain: the upstream comment + back-write + ticket rename + README refresh ride the same commit when fired from `transition-problem` Step 7b. R009 prose-floor discharge per [ADR-075](./075-promptfoo-agent-prose-verdict-eval-harness.proposed.md) Amendment 2026-06-02 + [ADR-061](./061-dogfood-graduation-criteria.proposed.md) Rule 4 evidence-floor: paired promptfoo Tier-A/B eval at `packages/itil/skills/update-upstream/eval/promptfooconfig.yaml` ships in the same commit as the SKILL prose. Behavioural bats at `packages/itil/skills/update-upstream/test/update-upstream-contract.bats` cover the contract surface. Confirmation extension: `## Reported Upstream` (criterion 3a) remains the load-bearing source-of-truth surface this contract reads from; the new `## Upstream Lifecycle Updates` section is the lifecycle-update audit-trail surface this contract writes to; both surfaces are append-only. JTBD coverage: JTBD-301 (reporter feedback loop closes end-to-end), JTBD-001 (no manual policing of upstream issues), JTBD-201 (symmetric local/upstream audit trail), JTBD-101 (downstream adopters inherit the bidirectional contract via the published SKILL surface). Reciprocal sibling: P079 closes the inbound-discovery leg (new upstream-filed reports visible to maintainer); together P079 + P080 make the reporter experience end-to-end. Confirmation §1 / §2 do not need rewriting — this amendment EXTENDS the contract without superseding earlier clauses (unlike the 2026-04-21 / 2026-06-04 amendments which superseded Steps 3+5 / Steps 4–6 AFK semantics respectively).
- **2026-04-21** — Decision Outcome Steps 3 and 5 superseded by [ADR-033](./033-report-upstream-classifier-problem-first.proposed.md) (Report-upstream classifier is problem-first). The classifier's preference order and the structured default body shape are now governed by ADR-033. The rest of ADR-024's Decision Outcome (Steps 1, 2, 4, 6, 7, 8), all Consequences, all Confirmation clauses, and the `## Reported Upstream` appendage contract remain in force. ADR-033 follows ADR-022's precedent for partial-lifecycle-language supersession.
- **2026-05-03 (P128)** — ADR-033's amendment of the same date reshapes Step 5's structured default body: replace the freeform `## Environment` section with a labelled `## Versions` section carrying a fixed five-field schema (Local plugin, Upstream package, Claude Code CLI, Node, OS). Missing fields render as `"not detected"` (normative MUST). Mirrored in `.github/ISSUE_TEMPLATE/problem-report.yml` and `packages/itil/skills/scaffold-intake/templates/problem-report.yml.tmpl` so inbound and outbound shapes match. Authority for the new body shape sits in [ADR-033's `## Amendments`](./033-report-upstream-classifier-problem-first.proposed.md#amendments) — this entry is the forward pointer from the partially-superseded predecessor.
- **2026-06-04 (P270, second amendment — leaf-substance ratification)** — User ratified verbatim 2026-06-04 the three leaf-substance questions queued as `outstanding_questions` against P270 by the same-day first-amendment entry below. **(a) Risk-reducing measures vocabulary = OPEN-ENDED LLM judgement** (not a bounded enumeration). Above-appetite branch composes risk-reducing measures case-by-case via the `wr-risk-scorer:external-comms` agent's own scoring — the same agent's judgement that produced the above-appetite verdict picks the remedy. Within-axis precedent: ADR-042's open-vocabulary `action-class` clause (auto-apply scorer remediations chose open vocabulary over closed enumeration for the analogous risk-class). **(b) Security routing under AFK external-comms gate**: if upstream has `SECURITY.md` AND below-appetite → file via the SECURITY.md-declared channel (Step 6 routing unchanged); if upstream has no `SECURITY.md` but another disclosure channel exists (mailbox, third-party programme) → run the external-comms risk assessment considering impact to (i) **our repository**, (ii) **our reputation**, (iii) **the party we are reporting to**. The missing-`SECURITY.md` sub-case is NOT always-queue-regardless — it stays external-comms-gated per the principle the user ratified 2026-06-02 (the gate's judgement on the three impact axes determines send vs queue, same shape as the public-issue and SECURITY.md-present branches). **(c) Rename `## Drafted Upstream Report` → `## Queued Upstream Report`** in the SKILL.md prose (both the static section name and any prose references) and in all tickets carrying the section. Same shape; new name reflects post-amendment semantics (queue-for-review-on-return, not loop-stopping halt-and-save). Trace: P355 (the scorer/agent failed to leverage promptfoo to discharge the R009 prose floor — the floor that justified holding the P270 changeset is no longer load-bearing once a promptfoo Tier-A/B eval is paired to the SKILL.md prose); RFC-019 (new — the P355 RFC trace per ADR-071 no-carve-out). Per ADR-074 substance-confirm-before-build: the three substances were named in the first-amendment entry below, queued as `outstanding_questions` against P270, surfaced for ratification, and confirmed BEFORE this dependent work landed — the canonical happy path.
- **2026-06-04 (P270)** — Consequences amendment + new orchestrator-layer Decision Outcome step authorising **external-comms-risk-gated AFK auto-fire for ALL upstream reports including security-classified tickets**. Reverses the conservative blanket-defer for security tickets previously authoritative in Consequences line 137 ("AFK orchestrators should never auto-report a security-classified ticket") and Consequences line 129 ("In AFK mode, the skill must fall through to ... halt the orchestrator"). User-direction ratified verbatim 2026-06-02 at principle level: *"I wanted to order file all upstream reports including security but it should be doing an external communication risk assessment. If the risk is below appetite then send. If it's above appetite then take risk reducing measures if that brings it into appetite great send otherwise queue it for my review."* New mechanism (orchestrator-side pre-fire gate on external-root-cause detection): (1) Compose the upstream-report draft via Steps 1–5 (or 4b dedup / 5c comment path / 6 security path) as the skill would otherwise. (2) Score the drafted prose via the `wr-risk-scorer:external-comms` agent (shipped per [ADR-028](./028-voice-tone-gate-external-comms.proposed.md) — the agent the 2026-04-25 (P070) amendment named as the lift-condition for the "interim static heuristic in force" clause is now met). (3) **Below-appetite** → Step 5 (or 5c / 6) proceeds; commit + back-write per Step 7 / Step 8. (4) **Above-appetite** → take risk-reducing measures (per the [ADR-042](./042-auto-apply-scorer-remediations-open-vocabulary.proposed.md) within-axis precedent generalised to the external-comms risk class — the measures vocabulary is **deferred substance** queued as outstanding_question (a) below); re-score; if within appetite → send; else → **queue** an `outstanding_questions` entry (category: `direction`) naming the local ticket ID + the drafted report path + the risk-reduce attempts taken + the residual band + remedy ("review the queued report at `/wr-itil:report-upstream <NNN> <upstream-repo-url>` on return"). Do NOT halt the orchestrator loop (per P352 queue-and-continue); the queued question surfaces at the existing batched-`AskUserQuestion` end-of-loop gate (work-problems Step 2.4 / Step 2.5b cross-halt routing). The `## Drafted Upstream Report` halt-and-save fallback (introduced by the 2026-04-25 (P070) amendment for the dedup branch + Consequences line 129 for the security branch) remains as the **content-substrate** for the queued question's "drafted report path" reference — its meaning changes from "loop-stopping halt save" to "queued-report save"; the orchestrator continues. **Deferred substance** (per [ADR-074](./074-confirm-decision-substance-before-building-dependent-work.proposed.md) substance-confirm-before-build — these three leaf-substance questions are NOT covered by the 2026-06-02 principle and MUST NOT be invented inline): (a) what constitutes "risk-reducing measures" for an above-appetite upstream report — alternative disclosure channel? content redaction? defer-to-security-advisory path? bounded vocabulary (analogous to ADR-042's `move-to-holding` enumeration) or open-ended LLM judgement (analogous to the `wr-risk-scorer:external-comms` agent's own scoring)? (b) security-disclosure-channel routing when auto-filing security in AFK — default to GitHub Security Advisories per Step 6 if upstream has `SECURITY.md` declaring them? halt on missing-`SECURITY.md` per existing Step 6 prose? always-queue-for-review when classification is security regardless of risk band? (c) whether the existing `## Drafted Upstream Report` halt-and-save section name + shape is the right substrate for the queued question's content reference, or whether a new `## Queued Upstream Report` section name better reflects the changed semantics. These three queue as `outstanding_questions` against P270 itself (recorded in the P270 ticket body) — return-presentation surfaces them as direction-setting decisions per [ADR-044](./044-decision-delegation-contract.proposed.md) category 1. The same-day implementation lands the per-classification branching prose in `packages/itil/skills/work-problems/SKILL.md` Step 4 classifier table + decision-table row, `packages/itil/skills/manage-problem/SKILL.md` Step 6 external-root-cause detection AFK fallback, and `packages/itil/skills/report-upstream/SKILL.md` AFK behaviour summary table (the security-path-halt row and the dedup-halt row are both re-cast as external-comms-gated; the public-issue path row gains the explicit external-comms gate reference). Confirmation §1 line 146 ("Security-path branch explicitly forbids auto-opening a public issue for security-classified tickets"), Confirmation §2 line 152 (the `grep -i 'never.*auto.*public'` test), and Confirmation §2 line 155's "interim static heuristic in force per ADR-028 line 117 until that subagent ships" clause all become false post-amendment and are rewritten in the same commit to cite the external-comms gate result instead of the blanket ban / interim-static-heuristic deferral. RFC trace: [RFC-018](../rfcs/RFC-018-p270-external-comms-gated-upstream-report-afk-auto-fire.proposed.md) per [ADR-071](./071-every-fix-goes-through-an-rfc.proposed.md) no-carve-out. [ADR-042](./042-auto-apply-scorer-remediations-open-vocabulary.proposed.md) within-axis precedent is the load-bearing analogue — the risk-reduce-then-queue shape generalises ADR-042's `move-to-holding` auto-apply pattern to the external-comms risk axis. [ADR-013](./013-structured-user-interaction-for-governance-decisions.proposed.md) Rule 6 fail-safe compatibility: queue-rather-than-silently-choose is the Rule 6 "defer the decision" branch, not the "auto-resolve" branch.
- **2026-04-25 (P070)** — Decision Outcome extended with **Step 4b (dedup check)** and **Step 5c (comment path)**. Step 4b runs after Step 4 (security-path routing) and before Steps 5 / 6 (the outbound `gh` calls); two branches share the insertion point — own re-run (grep local ticket for an existing `## Reported Upstream` URL) and third-party search (`gh issue list --repo <upstream> --state all --search "<keywords>"` followed by an **inline LLM semantic match** on each candidate's body via `gh issue view <n> --json body,title`). Per the P070 Direction decision (2026-04-21), the inline LLM judgement runs in the skill's main-agent context with NO subagent dispatch — the gh-search pre-filter trims input to ~5-10 candidates so inline reads stay bounded; promotion to a `wr-itil:dedup-check` subagent is a future amendment if architect review later flags context-isolation concerns. Step 5c adds a comment path (`gh issue comment <n>` with cross-reference body) for the case where Step 4b finds a match and the user picks "comment instead". The Step 7 back-write disclosure-path enumeration is extended with the new value `commented-on-existing-issue` (see Step 7 below). The own-re-run "Out of scope" deferral (line ~100 of the original Decision Outcome) is now in-scope; the residual "Out of scope" item is the broader `update-mode` (re-running the skill against the same upstream issue to refresh content, not just to acknowledge the existing report). The maintainer-annoyance risk evaluator named in the P070 Direction decision is **deferred** to compose with the `wr-risk-scorer:external-comms` subagent declared in ADR-028 (per ADR-028 line 117 — third-evaluator extension point); the AFK auto-comment branch is on an **interim static heuristic** (halt-and-save the drafted report; never auto-comment) until that evaluator lands. The static-heuristic interim path is bounded — the bundling commit when ADR-028's evaluator ships re-wires the AFK branch to the policy-authorised gate combination.

## Context and Problem Statement

Every downstream project (addressr, bbstats, any consumer of `@windyroad/*` or other npm packages) that notices a defect in an upstream dependency has to invent its own "report a problem to a dependency" workflow. The agent can call `gh issue create` against an upstream repo, but there is no Windy Road plugin, skill, or convention that scaffolds the flow. In practice, upstream issues are opened as free-form prose, the local `docs/problems/<NNN>` ticket is not cross-referenced back into the upstream record, and the audit trail is one-way (downstream knows the upstream was contacted; upstream has no structured link back to the downstream context).

Upstream problem: P055 part (B) (No standard problem-reporting channel for plugin users, and no reusable pattern for downstream projects to report to their upstream dependencies). The reciprocal part (A) — this repo's own intake scaffolding — is not in scope for this ADR; it is addressed by shipping `.github/ISSUE_TEMPLATE/`, `CONTRIBUTING.md`, `SUPPORT.md`, and `SECURITY.md` as standard OSS hygiene files without a separate ADR. The templates this repo ships become the reference intake shape that (B)'s skill can target deterministically.

Four structural gaps combine to produce the miss:

1. No skill contract exists for "report this problem upstream" — every agent reinvents the invocation.
2. Upstream issue templates are not discovered or targeted — the agent free-forms, losing the curated required-fields upstream maintainers have defined.
3. Local ↔ upstream cross-referencing is missing — the downstream ticket's Related section does not get the upstream issue URL written back into it, and the upstream issue does not carry a structured link to the downstream ticket.
4. Security disclosure has no routing — an agent noticing a security-sensitive upstream defect has no structured path to the upstream's `SECURITY.md`; free-forming a public issue would be an exposure incident.

This ADR closes all four.

## Decision Drivers

- **JTBD-004** (Connect Agents Across Repos to Collaborate) — the cross-repo coordination axis that this skill sits on top of. Upstream reporting is a cross-repo handoff; JTBD-004's outcomes ("agent in repo A can cleanly hand context to agent in repo B") are the direct motivator. Per the jtbd-lead's review of this ADR.
- **JTBD-001** (Enforce Governance Without Slowing Down) — the solo-developer persona's "without slowing down" axis demands the agent have a structured pattern for upstream-reporting rather than ad-hoc prose; manually policing free-form upstream issues is exactly the pain the persona wants to avoid.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — bi-directional downstream ↔ upstream linkage is the auditability core of this JTBD; one-way audit trails fail the "restore fast with an audit trail" promise on any incident that involves an upstream fix.
- **JTBD-101** (Extend the Suite with Clear Patterns) — plugin-developer persona; the reusable pattern is "clear patterns, not reverse-engineering" applied to cross-project flows. Partial-fit here (primary fit is JTBD-004); JTBD-101 applies to downstream developers building on top of the report-upstream skill.
- **P055** — the upstream problem ticket this ADR resolves (part B).
- **Security-disclosure latency risk** — auto-opening a public issue for a security-sensitive upstream defect is the worst-case failure mode. The contract must eliminate this path by construction.
- **Upstream heterogeneity** — some upstreams have curated `.github/ISSUE_TEMPLATE/*.yml` templates; others have none. The skill cannot assume a uniform target and must fall through gracefully.
- **P037** (JTBD reviewer output contract) — precedent for "skill output contracts are explicit, structured, and have a fallback when the expected shape is missing". This ADR applies the same principle to cross-project reporting.
- **ADR-022** (problem lifecycle Verification Pending) — the local ticket's lifecycle is the canonical source of state; the skill writes back into it and respects its status transitions.

## Considered Options

1. **Discover + fall through to structured default, skill lives in `@windyroad/itil`** (chosen) — a new `report-upstream` skill in the existing itil plugin reads upstream `.github/ISSUE_TEMPLATE/` if present, picks the best-match template (bug/feature/question) based on the local ticket's shape, and emits a structured default derived from the local ticket's sections when no template exists. Security-sensitive tickets route to upstream `SECURITY.md` or halt and surface to the user.
2. **New dedicated plugin `@windyroad/dependency-reporting`** — same contract, but isolated in its own published package so consumers can install it without itil's full problem-management surface.
3. **Always use a Windy-Road-structured default, ignore upstream templates** — simpler implementation; loses upstream maintainers' curated required-fields.
4. **Only report when upstream has templates, refuse otherwise** — most conservative; likely too restrictive given upstream heterogeneity.
5. **Always open GitHub Security Advisories for security-sensitive tickets on GitHub-hosted upstreams** — simpler; conflicts with upstreams that explicitly route elsewhere in their `SECURITY.md`.

## Decision Outcome

Chosen option: **"Discover + fall through to structured default, skill lives in `@windyroad/itil`"**, because it respects upstream maintainers' curated intake shape when they have one (Option 1 over Option 3), doesn't abandon downstreams whose upstreams never invested in templates (Option 1 over Option 4), and locates the skill where problem-management lives today without adding a new package to publish (Option 1 over Option 2).

`report-upstream` is an **action skill** (mutates the local ticket, opens an upstream issue or advisory), not an assessment skill. It is a `manage-*`-family peer alongside `manage-problem` and `manage-incident` under the ADR-010 naming pattern and the ADR-011 skill-wrapping precedent — NOT an application of ADR-015 (which governs read-only `assess-*` / `review-*` skills).

### Scope

**In scope (this ADR):**

- **New skill**: `packages/itil/skills/report-upstream/SKILL.md`. Invocation: `/wr-itil:report-upstream <local-problem-id> <upstream-repo-url>` (additional optional args: `--severity`, `--classification`, `--evidence-url`). The skill's steps:
  1. Read the local problem ticket (`docs/problems/<status>/<NNN>-<title>.md` per ADR-031 per-state-subdirectory encoding accepted 2026-05-12; amended 2026-05-12 — was `docs/problems/<NNN>-<title>.<status>.md` under the prior filename-suffix encoding) to extract Description, Symptoms, Root Cause Analysis, Workaround, Impact Assessment. If the ticket is not found, halt with a clear error.
  2. Read `.github/ISSUE_TEMPLATE/*.yml` and `.github/ISSUE_TEMPLATE/*.md` on the upstream repo via `gh api repos/<owner>/<repo>/contents/.github/ISSUE_TEMPLATE`. If the directory is 404, treat as no-templates.
  3. Classify the local ticket's shape (bug vs feature vs question) from its title and description. Pick the best-matching upstream template by name or `name:` frontmatter field, preferring `bug` / `bug-report` for defects and `feature` / `feature-request` for enhancements.
  4. **Security-path routing**: if the local ticket's Priority has `security` in its label or the ticket body contains a Security classification section, route to the security path (step 6) instead of opening a public issue.
  4b. **Dedup check** (added 2026-04-25, P070): runs after Step 4 (security-path routing) and before Step 5 (public-issue path). Two branches share the insertion point:
     - **4b.1 Own re-run check**: grep the local ticket for an existing `## Reported Upstream` section. If present, halt-and-surface the existing URL — the skill has already reported (or commented) for this ticket.
     - **4b.2 Third-party search**: extract keywords from the local ticket's title + description, then run `gh issue list --repo <upstream> --state all --search "<keywords>" --json number,title,state,url --limit 10` to retrieve candidate matches. For each candidate, fetch full body via `gh issue view <n> --json title,body,state,url` and run an **inline LLM semantic match** in the skill's main-agent context (NO subagent dispatch — per the P070 Direction decision 2026-04-21, the gh-search pre-filter trims input to ~5-10 candidates so inline reads stay bounded; promotion to a `wr-itil:dedup-check` subagent is a future amendment if architect review later flags context-isolation concerns). Verdicts: `same-problem` / `different-problem` / `uncertain`.
     - Both branches use `AskUserQuestion` per ADR-013 Rule 1 in interactive mode (options: halt / comment on existing match (Step 5c) / file new anyway / cancel). In AFK / non-interactive mode (per ADR-013 Rule 6), the **interim static heuristic** applies: halt-and-save the drafted report to the local ticket's `## Drafted Upstream Report` section. The static heuristic stands until `wr-risk-scorer:external-comms` ships (per ADR-028 line 117 — third-evaluator extension point) and the AFK auto-comment branch is wired to the policy-authorised maintainer-annoyance + leak-gate combination.
  5. **Public-issue path**: fill the matched template's required fields from the local ticket's sections (plugin name, version, reproduction steps, expected/actual). If no template exists, emit a structured default of the form:
     ```
     ## Summary
     <one-paragraph description of the problem>

     ## Steps to reproduce
     <bullet list or numbered steps from the local ticket's Symptoms>

     ## Expected behaviour
     <from local ticket>

     ## Actual behaviour
     <from local ticket>

     ## Environment
     - Package: <from local ticket>
     - Version: <detected via npm ls or local ticket>

     ## Cross-reference
     Reported from <downstream repo URL>/<local-ticket-path>
     ```
  5c. **Comment path** (added 2026-04-25, P070): used when Step 4b's dedup check finds a match AND the user / static heuristic picks "comment on existing" instead of filing a new issue. Skips `gh issue create` and runs `gh issue comment <n> --repo <upstream> --body <comment-body>` instead, where `<comment-body>` is a condensed cross-reference body (downstream repo URL + local ticket reference + any net-new evidence not in the matched issue's body). The Step 7 back-write records the comment URL with disclosure-path value `commented-on-existing-issue`. The voice-tone gate per ADR-028 also fires on `gh issue comment` — same delegate-and-retry pattern as Step 5.
  6. **Security path**: fetch upstream `SECURITY.md` via `gh api repos/<owner>/<repo>/contents/SECURITY.md`. If present, parse it for a disclosure channel (GitHub Security Advisories link, `security@` mailbox, Tidelift URL, or other documented route). Follow that channel:
     - **GitHub Security Advisories** (most common): call `gh api repos/<owner>/<repo>/security-advisories` with the structured report.
     - **security@ mailbox**: halt and surface the mailbox to the user with the structured report drafted — do NOT auto-send email (out of scope; no infra).
     - **Other documented channel**: halt and surface the channel + drafted report to the user.
     If upstream has NO `SECURITY.md`: halt and surface the dilemma with `AskUserQuestion` (per ADR-013 Rule 1) — options: (a) open a private GitHub Security Advisory against the upstream if it's on GitHub, (b) contact the maintainer out-of-band first, (c) downgrade the classification (user judgement) and report via the public-issue path. Never auto-open a public issue for a security-classified ticket.
  7. **Cross-reference back-write**: after the upstream issue (or Advisory) is created, append to the local ticket's `## Related` section: `- **Reported upstream**: <upstream issue URL> (<date>)`. Append to the local ticket a new optional `## Reported Upstream` section with the upstream issue number, URL, template used (or "structured default"), and disclosure path (public issue or security-advisory or out-of-band-mailbox or **commented-on-existing-issue** — the last value added by the 2026-04-25 (P070) amendment for Step 5c comment-path back-writes). The section is appended, never inserted — existing ticket structure is preserved.
  8. **Commit per ADR-014**: the back-write to the local ticket is a governance doc change; follow the ADR-014 ordering `work → score via wr-risk-scorer:pipeline → commit`. Commit message: `docs(problems): P<NNN> reported upstream — <one-line summary>`. If risk is above appetite and `AskUserQuestion` is unavailable, apply the ADR-013 Rule 6 non-interactive fail-safe — skip the commit and report the uncommitted state rather than auto-committing.

- **Skill contract documentation**: `packages/itil/skills/report-upstream/SKILL.md` is the authoritative definition, consistent with the existing itil skills' pattern (`manage-problem`, `manage-incident`, `work-problems`).
- **Bats test**: `packages/itil/skills/report-upstream/test/report-upstream-contract.bats` asserts SKILL.md wording (template-discovery step, security-path routing, cross-reference back-write, commit convention, ADR-024 cross-reference).
- **`manage-problem` SKILL.md update**: add an explicit note that the `## Reported Upstream` section is an allowed optional appendage to a problem ticket, so the two skills don't drift. Keeping this in the same commit as ADR-024 acceptance documentation.
- **ADR-002 inventory update**: update ADR-002's `itil/` package inventory line to list `report-upstream` alongside `manage-problem` / `manage-incident` / `work-problems`.

**Out of scope (follow-up tickets or future ADRs):**

- Auto-sending email for the `security@` mailbox case — no infra, halt-and-surface is the safe default.
- Bi-directional sync (when upstream updates its issue, does the local ticket auto-update?). Possible future extension; the initial contract is one-shot report.
- **Update-mode for own-re-run** — re-running the skill against the same local ticket to *refresh* an existing upstream report (edit the upstream issue body, push new evidence into a structured update field) is still out of scope. The 2026-04-25 (P070) amendment moved **detection** of the own-re-run case (Step 4b.1) and the **comment-on-existing-issue** path (Step 5c) into scope; the residual gap is the broader edit-the-existing-issue workflow that requires `gh issue edit` + a structured "update history" appendage shape — covered by a future amendment if demand emerges.
- The intake scaffolding half of P055 (CONTRIBUTING.md, SUPPORT.md, SECURITY.md, `.github/ISSUE_TEMPLATE/` in THIS repo) — standard OSS hygiene, ships without its own ADR.

## Consequences

### Good

- Agents operating in downstream projects gain a structured pattern for upstream reporting, matching the "clear patterns, not reverse-engineering" promise.
- Bi-directional audit trails: local ticket references upstream issue, upstream issue body references downstream origin, and JTBD-201's restore-fast-with-audit-trail promise is honoured.
- Security disclosures cannot be accidentally opened as public issues — the contract routes security-classified tickets through SECURITY.md-declared channels or halts safely.
- Upstream maintainers' curated intake (structured required-fields in their templates) is respected when they have one; default is reasonable when they don't.
- Placement in `@windyroad/itil` reuses the plugin that already owns problem management — no new package publish, no ADR-002 dependency-graph churn, no split between "manage your problems" and "tell someone else about them" surfaces.

### Neutral

- The skill's template-discovery step makes one API call to the upstream repo per invocation. Network-bound; acceptable for a manually-invoked skill.
- The security-path halt-and-surface branch is interactive (requires `AskUserQuestion` for the no-`SECURITY.md` case). In AFK mode, the skill must fall through to "save the drafted report and halt the orchestrator" rather than auto-route — AFK orchestrators should never auto-report a security-classified ticket.
- Cross-reference back-writes modify `docs/problems/<status>/<NNN>-<title>.md` files (per ADR-031 per-state-subdirectory encoding; amended 2026-05-12 — was `docs/problems/<NNN>.<status>.md`), which are excluded from pipeline risk hash per the doc exclusions rule. Reporting is a docs-only local operation from the risk-scorer's perspective.
- Voice-tone gate per ADR-028 fires on the skill's `gh issue create` (Step 5) and `gh api .../security-advisories` (Step 6) calls. The skill should treat the transient deny-plus-delegate as expected and proceed on the retry; the voice-tone agent reviews only the prose body, not structural template fields.

### Bad

- Downstream projects that install only `@windyroad/itil` get the full problem-management surface (manage-problem, work-problems, manage-incident, and now report-upstream). Consumers who wanted only reporting pay for the full plugin. Accepted trade-off — avoiding a new plugin keeps the dependency graph simple; if future usage shows demand for a standalone reporting package, the reassessment criterion below triggers a split.
- Template-matching heuristics (bug vs feature vs question) are brittle. If the upstream has unusual template names, the match may pick the wrong one. Mitigated by logging the matched template name in the Reported Upstream section so the user can verify; worst-case the report is still filed, just against the wrong template.
- Security-path halt-and-surface requires an interactive user. In truly autonomous contexts (AFK orchestrators), the skill MUST NOT auto-resolve the dilemma; it halts the orchestrator and waits for the user, which is a loop-stopping event. This is the correct conservative default (consistent with JTBD-006's "does not trust the agent to make judgement calls"), but it means security reports cannot be batched without user attendance.

## Confirmation

Compliance is verified by:

1. **Source review:**
   - `packages/itil/skills/report-upstream/SKILL.md` exists and documents the steps above.
   - The skill's steps include template discovery, classification, security-path routing, and cross-reference back-write.
   - **(2026-06-04 amendment, P270)** Security-path branch in AFK no longer forbids auto-filing — instead it gates the file/comment/advisory call via the `wr-risk-scorer:external-comms` agent (ADR-028) and routes per the risk band: below-appetite → proceed; above-appetite → risk-reduce then re-score → send-or-queue. The blanket "never auto-open a public issue for a security-classified ticket" rule that previously fell out of Consequences line 137 + the SKILL.md Step 6 first-clause prose is **superseded** by the per-classification external-comms gate. The 2026-04-25 (P070) "interim static heuristic in force until that subagent ships" deferral is **lifted** — the subagent has shipped (`packages/risk-scorer/agents/external-comms.md`).
   - The commit-gate ordering cites ADR-014 (`work → score via wr-risk-scorer:pipeline → commit`) and the ADR-013 Rule 6 non-interactive fail-safe for the above-appetite branch. The above-appetite branch under the 2026-06-04 (P270) amendment is queue-not-halt per P352 + ADR-013 Rule 6 "defer the decision" branch (the queue IS the defer; not silent-choose).

2. **Test:** bats test in `packages/itil/skills/report-upstream/test/` asserts:
   - SKILL.md contains the template-discovery step (`grep 'ISSUE_TEMPLATE'`).
   - SKILL.md contains the security-path routing with the SECURITY.md fallback (`grep -i 'SECURITY.md'` + branch for missing).
   - **(2026-06-04 amendment, P270)** SKILL.md AFK behaviour summary table cites the `wr-risk-scorer:external-comms` external-comms gate as the per-classification routing authority (`grep -i 'external-comms'` in the AFK summary table + `grep -i 'wr-risk-scorer:external-comms'` in the security-path-row and dedup-path-row cells). The legacy `grep -i 'never.*auto.*public'` assertion (which guarded the pre-2026-06-04 blanket ban) is **superseded** — its replacement asserts the external-comms-gated branching, NOT the blanket ban.
   - SKILL.md contains the cross-reference back-write step (`grep 'Reported Upstream'` section).
   - SKILL.md cross-references ADR-024 so readers can trace the contract's origin.
   - **(2026-04-25 amendment, P070; clauses about `wr-risk-scorer:external-comms` deferral amended 2026-06-04, P270)** SKILL.md contains the Step 4b dedup check (`grep -E '^### 4b\.'`); Step 4b.2 third-party search uses `gh issue list --search` with inline-LLM judgement (no subagent dispatch); Step 5c comment path is documented (`grep -E '^### 5c\.'` + `grep 'gh issue comment'`); the new disclosure-path string `commented-on-existing-issue` appears in the SKILL.md Step 7 back-write template; the AFK behaviour summary table includes the dedup-path branch routed via the **`wr-risk-scorer:external-comms` gate** (the 2026-04-25 "interim static heuristic in force until that subagent ships" clause is **lifted** — the subagent has shipped per the 2026-06-04 (P270) amendment).

3. **Cross-reference confirmation in neighbouring docs:**
   - `packages/itil/skills/manage-problem/SKILL.md` names the optional `## Reported Upstream` section as an allowed appendage.
   - `docs/decisions/002-monorepo-per-plugin-packages.proposed.md`'s `itil/` inventory line includes `report-upstream`.
   - `packages/itil/package.json` plugin manifest reflects the new skill if the marketplace manifest enumerates them.

4. **Behavioural replay**: exercise the skill on a real scenario. Candidate fixtures:
   - Upstream with `.github/ISSUE_TEMPLATE/bug-report.yml` — verify the skill picks that template and fills its fields.
   - Upstream without templates (a sample repo) — verify structured default is emitted.
   - Upstream with `SECURITY.md` declaring GitHub Security Advisories — verify routing.
   - Upstream without `SECURITY.md`, security-classified ticket — verify the `AskUserQuestion` halt-and-surface.

5. **End-to-end cross-reference confirmation**: after a real upstream report, verify the downstream ticket has `## Reported Upstream` section and its `## Related` section has the `Reported upstream: <URL>` line. Verify the upstream issue body has the `Cross-reference: <downstream URL>` line.

   **(2026-05-18 amendment, P249 Phase 1)** The `## Reported Upstream` back-link section's `- **URL**:` line is now a **load-bearing contract surface for two skills**, not one. `/wr-itil:report-upstream` writes the section at Step 7. `/wr-itil:check-upstream-responses` (P249 Phase 1) reads the URL field to enumerate outbound reports for response polling — see [ADR-062](062-inbound-upstream-report-discovery-assessment-pipeline.proposed.md)'s symmetric inbound counterpart. Any future change to the section's shape (additional fields, renaming the URL key, alternative format) MUST be applied in coordination with both skills in the same commit. The reader's contract is documented in `packages/itil/skills/check-upstream-responses/SKILL.md` § Confirmation (#2) and tested via `packages/itil/scripts/test/check-upstream-responses.bats`. This amendment lands within ADR-024's existing reassessment window — no new ADR.

6. **Downstream adoption** (advisory, non-blocking): at least one downstream project (addressr or bbstats) dogfoods the skill for a real upstream report within 3 months. Non-blocking for this ADR's acceptance; flagged in Reassessment Criteria below.

## Pros and Cons of the Options

### Option 1: Discover + fall through to structured default, skill in `@windyroad/itil` (chosen)

- Good: respects upstream templates when present.
- Good: never leaves a downstream without a reporting path.
- Good: no new plugin — reuses itil's problem-management scope; no ADR-002 graph churn.
- Good: security-path halt-and-surface is safe by default (JTBD-006-aligned).
- Neutral: network call to discover templates; acceptable for manual invocation.
- Bad: template-matching heuristics may pick the wrong template; mitigated by logging.

### Option 2: New `@windyroad/dependency-reporting` plugin

- Good: clean separation of concerns — consumers can install reporting without itil.
- Good: isolates the skill's dependency surface (needs `gh` API calls) from itil's.
- Bad: new package to publish, version, and document.
- Bad: ADR-002 dependency graph update required.
- Bad: problems ARE in itil's scope; splitting the "manage" surface from the "report" surface of the same concept creates an odd seam.

### Option 3: Always use Windy-Road-structured default, ignore upstream templates

- Good: simplest implementation — no template discovery, no match heuristics.
- Bad: ignores upstream maintainers' curated required-fields (which is rude).
- Bad: uniform-looking reports regardless of target; upstream triage gets harder.

### Option 4: Only report when upstream has templates, refuse otherwise

- Good: most conservative — never fills in for a missing intake.
- Bad: abandons downstreams whose upstreams never invested in templates (the majority case in the npm ecosystem).
- Bad: violates the "clear patterns" promise — downstreams have to fall back to free-form anyway.

### Option 5: Always use GitHub Security Advisories for GitHub-hosted upstreams

- Good: simple and security-sound for the GitHub subset.
- Bad: conflicts with upstreams whose `SECURITY.md` explicitly routes elsewhere (e.g., Tidelift, security@ mailbox with a specific triage flow).
- Bad: doesn't handle non-GitHub-hosted upstreams (GitLab, self-hosted, Codeberg).

## Reassessment Criteria

Revisit this decision if:

- **A second skill that reads upstream repo content lands in the suite.** That signals "reading external repo content" is a recurring pattern and the template-discovery heuristic should be extracted into its own cross-cutting ADR rather than living only in this skill.
- Two or more downstream projects adopt the skill and start requesting reporting-specific features that would inflate itil's scope (e.g. bi-directional sync, cross-upstream aggregation dashboards). That would trigger moving the skill into its own `@windyroad/dependency-reporting` plugin (Option 2).
- Template-matching heuristics prove unreliable in practice — agents repeatedly pick the wrong template, requiring manual intervention. That would signal a need for a more structured template-classification mechanism (e.g., LLM-classify the local ticket and upstream templates jointly).
- The security-path halt-and-surface branch fires so often that it becomes loop-stopping noise in AFK orchestrators. That would signal either (a) a policy change allowing certain security routes to be policy-authorised, or (b) a separate AFK-safe security path that batches disclosures for later user review.
- GitHub changes its security-advisory API in a breaking way, or an alternative security-disclosure primitive emerges (e.g., OpenSSF-standardised disclosure) that becomes the preferred target.
- P037's verdict-contract pattern needs to be reused verbatim here — the skill's output contract may need the same "inline primary, file internal signal" structure for consistency across governance agents.

## Related

- **P055** — upstream problem ticket (part B) this ADR resolves.
- **P070** — driver ticket for the 2026-04-25 amendment that adds Step 4b (dedup check) + Step 5c (comment path) + the AFK static-heuristic interim behaviour. Carries the user's 2026-04-21 Direction decision pinning gh-search + inline-LLM as the dedup mechanism.
- **P037** — JTBD reviewer output contract; precedent for explicit fallback-shaped skill contracts.
- **ADR-002** — monorepo with per-plugin packages; the "skill in itil vs new plugin" decision is made against this graph, and ADR-002's `itil/` inventory is updated by this ADR.
- **ADR-010** — rename `wr-problem` to `wr-itil`; the `<verb>-<object>` naming pattern (`report-upstream`) compliance.
- **ADR-011** — manage-incident skill-wrapping precedent; `report-upstream` follows the same action-skill shape.
- **ADR-013** — structured user interaction; Rule 1 governs the security-path `AskUserQuestion`, Rule 6 governs the non-interactive fail-safe.
- **ADR-014** — governance skills commit their own work; the back-write to the local ticket follows this ordering.
- **ADR-015** — on-demand assessment skills; explicitly NOT an application (this is an action skill), but neighbouring precedent for skill-contract shape.
- **ADR-022** — problem lifecycle Verification Pending; the skill reads the local ticket's Status field.
- **ADR-031** — per-state-subdirectory encoding for `docs/problems/` (accepted 2026-05-12). Reference paths in this ADR amended in-place where they reference local ticket locations.
- **JTBD-001**, **JTBD-004**, **JTBD-101**, **JTBD-201** — the four personas whose needs drive this ADR (JTBD-004 is primary fit per jtbd-lead review).
- **JTBD-006** — AFK persona constraint that the security-path halt-and-surface branch is designed against.
- **addressr** — downstream project whose session-memory workaround for upstream reporting motivates this ADR; candidate dogfood site.
- **bbstats** — sibling downstream candidate.
