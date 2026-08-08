---
status: "proposed"
date: 2026-08-08
human-oversight: confirmed
oversight-date: 2026-08-08
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin adopters]
reassessment-date: 2026-11-08
amends: [ADR-024, ADR-033]
---

# Prefer an upstream pull request over an issue when the upstream accepts pull requests

## Context and Problem Statement

`/wr-itil:report-upstream` ends at `gh issue create`. When a local problem ticket's fix site turns out to be in another repository, the skill files an issue there and the local ticket waits. That is the only outbound artefact the skill knows how to produce.

The user's direction, verbatim, 2026-08-08:

> this should be part of the upstream work problem skill. If the upstream repo accepts pull requests, the skill should prefer submitting a PR over raising an issue. NOTE: same external comms checks apply

A prior attempt to make that change was correctly blocked. [ADR-073](./073-fix-time-gate-auto-creates-missing-rfc.proposed.md) (RFC-first) Decision Outcome clause 3 requires that a fix whose approach-choice falls outside the coverage of the existing decision corpus carry a **new ADR, ratified before implementation**. Nothing in this repo's corpus covers the choice of outbound artefact. [ADR-024](./024-cross-project-problem-reporting-contract.proposed.md) (cross-project problem-reporting contract) enumerates four outbound paths — public issue, comment on an existing issue, security advisory, out-of-band mailbox — and considers a pull request nowhere. [ADR-033](./033-report-upstream-classifier-problem-first.proposed.md) (report-upstream classifier is problem-first) governs the *shape* of the report, not the *kind* of artefact. [ADR-028](./028-voice-tone-gate-external-comms.proposed.md) (external-comms gate) governs the prose review on the surface, not the choice of surface. This decision is therefore genuinely uncovered, and clause 3's "if and only if" test is satisfied.

### Why the downstream decision does not discharge this

The Windy Road delivery repo ratified its own ADR-048 on 2026-08-08, with the same headline rule. That decision is a **read-only reference** here and it does not close the local requirement, because it is not the same decision. ADR-048 records **one downstream project's posture toward its own upstreams** — a project that holds `ADMIN` on the upstream in question and has two working clones of it on the same machine. This ADR records **the plugin's behaviour for every adopter**, and the adopter population is the opposite case: the `plugin-user` persona is documented as "a consumer of the suite, not a contributor" (`docs/jtbd/plugin-user/persona.md:12`), and ADR-024's own Context extends the skill's remit to "any consumer of `@windyroad/*` **or other npm packages**" (ADR-024:31). Most adopters have no write access to the upstreams they report to.

### The predicate is "accepts pull requests", not "we have write access"

Getting this wrong would ship a feature that only works for people who own their upstreams. Fork-and-PR is the ordinary contribution path for a third party and is the majority case for adopters. A write-access predicate would make the skill a no-op for exactly the case ADR-024 was written for.

There is in-family precedent for choosing a capability predicate over an ownership one. ADR-024's Decision Driver "Upstream heterogeneity" (ADR-024:52) states that "some upstreams have curated `.github/ISSUE_TEMPLATE/*.yml` templates; others have none. The skill cannot assume a uniform target and must fall through gracefully", and on that basis it rejected its Option 4, "only report when upstream has templates, refuse otherwise", as "likely too restrictive given upstream heterogeneity" (ADR-024:61). A write-access predicate is that rejected option reincarnated on a new axis: it refuses the majority case to preserve a uniformity assumption.

### A note on ADR numbers

Local and upstream numbering collide, and the collision is a live trap in this subject area. Every `ADR-NNN` in this document resolves against **this repo's** `docs/decisions/`, verified on disk on 2026-08-08. In particular, the Windy Road delivery repo's ADR-048 attributes the unscored-diff gap named below to *its* ADR-008 (action-specific pipeline risk management). That attribution does not transfer: local ADR-008 is the JTBD directory structure. The local home of that gap is identified in the External communications section below.

## Decision Drivers

- **Every edit reviewed against policy before it lands** — JTBD-001 (Enforce Governance Without Slowing Down), Desired Outcome 1, `docs/jtbd/developer/JTBD-001-enforce-governance.proposed.md:19`. A pull request diff is an edit that lands. The only scorer that reads diffs reads them against the *local* risk policy, so this outcome is not currently met on the new surface — which is why the gap is named here rather than assumed away.
- **Adopters are consumers, not owners** — `docs/jtbd/plugin-user/persona.md:12`, plus ADR-024:31. The predicate must work for a dependency the adopter could not possibly hold write access to.
- **A capability predicate has precedent over a refuse-unless-uniform one** — ADR-024:52 and its rejection of Option 4 at ADR-024:61.
- **Reporting is incidental to the reporter** — `docs/jtbd/plugin-user/persona.md:18` ("friction at the reporting surface has a high chance of abandoning the report entirely") and JTBD-301 (Report a Problem Without Pre-Classifying It), `docs/jtbd/plugin-user/JTBD-301-report-problem-without-pre-classifying.proposed.md:31` ("intake must work in under 2 minutes or the report will be abandoned"). A preference for pull requests must never become a floor that raises the reporter's obligation from describe-the-symptom to produce-a-patch.
- **The AFK loop is not trusted with judgement calls** — JTBD-006 (Progress the Backlog While I'm Away), `docs/jtbd/developer/JTBD-006-work-backlog-afk.proposed.md:36`, and its audit-trail expectation at `:37`. Authoring a fix in a codebase we do not maintain is a judgement call by any reading.
- **Per-report token burn is a governed cost** — JTBD-010 (Sustain My Token Quota Across the Week and Across Surfaces), `docs/jtbd/developer/JTBD-010-sustain-token-quota.proposed.md:33`. A clone, branch, patch and push round trip costs materially more than one `gh issue create`.
- **A fix that lands upstream reaches every adopter**, where an issue reaches only the maintainer's queue.

## Considered Options

1. **Prefer a pull request wherever the upstream accepts them, with the agent authoring the patch and the human unchanged as a symptom-reporter (chosen).**
2. **Prefer a pull request only where we hold write access.** Narrower and needs no fork handling; leaves every genuine third-party dependency on the issue path permanently.
3. **Keep the issue-only path.** The status quo; costs nothing to adopt.
4. **Prefer a pull request and let the AFK loop open it unattended,** inheriting ADR-024's 2026-06-04 (P270) auto-fire.

## Decision Outcome

Chosen option: **prefer a pull request over an issue when the upstream accepts pull requests.**

When a local problem ticket's fix site is in an upstream repository, `/wr-itil:report-upstream` prefers opening a pull request over filing an issue, whenever that upstream accepts pull requests. The predicate is the upstream's acceptance of contributions, not our permission on it: fork-and-PR counts.

### Fallbacks — file an issue instead when

1. The upstream does not accept contributions.
2. The fix needs a design decision that is the maintainers' to make.
3. The ticket is security-classified. This branch **routes** per ADR-024 Step 6 and its 2026-06-04 (P270) amendment; it does **not** re-assert the blanket "never auto-open a public issue for a security-classified ticket" ban, which P270 superseded and which survives in `packages/itil/skills/report-upstream/SKILL.md:474` only as a traceability marker.
4. **There is no defensible fix in hand.** A symptom, or even a diagnosis, without a change we can responsibly author in an unfamiliar codebase is an issue, not a pull request. This exit is load-bearing: without it the preference silently raises the reporting floor and inverts JTBD-301.

The preference is a preference. It never converts the reporter into a patch author; the added cost lands on agent time and token budget, not on the reporter's attention.

### The pull request body — what amends ADR-033

ADR-033's structured default is a **problem report**: Description, Symptoms, Workaround, Affected plugin, Frequency, Environment, Evidence, Cross-reference. That shape is incoherent on a pull request, where the diff already resolves the symptoms it would recite.

On the pull-request branch, the body **defers to the upstream's `.github/PULL_REQUEST_TEMPLATE.md` when one is present**, and otherwise uses a reduced shape carrying the rationale and the cross-reference back to the local ticket. This is the direct analogue of ADR-024's chosen posture of respecting the upstream's own curated intake, applied to a second artefact kind. ADR-033's problem-first classifier and its structured default remain unchanged and in force on the issue branch.

### The AFK path does not inherit unattended auto-fire

ADR-024's 2026-06-04 (P270) amendment authorises an unattended loop to file an upstream report once `wr-risk-scorer:external-comms` scores the drafted prose within appetite. That gate reads prose. Carried over unchanged to this branch, it would let an autonomous loop push code into a third party's repository under our name on the strength of a prose review alone — which JTBD-006:36 rules out.

Under AFK, the pull-request branch **degrades to the issue branch**, and the drafted pull request is queued to the ticket's `## Queued Upstream Report` section for the interactive return. This reuses the existing queue-and-continue mechanism rather than inventing one. Interactive sessions open the pull request directly.

### Recording the outcome — what amends ADR-024

ADR-024 Step 7 appends a `## Reported Upstream` section carrying a `- **URL**:` line and a disclosure path. The pull-request branch records a **distinct disclosure-path value**, and every site that branches on that value handles it.

This is a **value-set widening on an enumeration that already ships**, not a change to the section's shape. The branch mechanism is already on disk: `packages/itil/scripts/catchup-scan.sh:136` defines `extract_disclosure_path()`, and the branch arms consume it at `:254` and skip on `out-of-band` / `mailbox` at `:256-258`. The live value set already spans `public issue`, `commented-on-existing-issue`, `posted-comment`, `posted-inbound-comment`, `posted-inbound-comment-and-closed`, `posted-on-closed-issue`, `out-of-band` and `mailbox`. Adding one more value is the ordinary way this enumeration grows.

The reason a discriminator is required at all is that a pull request URL silently breaks readers that assume an issue. Verified on disk:

- `packages/itil/scripts/check-upstream-responses.sh:193` polls with `"$GH_BIN" issue view "$upstream_url" --json comments,state,labels,updatedAt`. Its `extract_upstream_url()` at `:135` reads the URL and nothing else — the script has **no** disclosure-path extraction at all, so it cannot currently tell an issue URL from a pull request URL. The poll errors per ticket.
- `packages/itil/skills/update-upstream/SKILL.md:52` runs `gh issue comment <n>` and, on the Verification-Pending-to-Closed transition, also `gh issue close <n>`. Both are wrong on a pull request: a merged one closes itself, and closing an unmerged one is a hostile act against work we authored.
- `packages/itil/skills/report-upstream/SKILL.md:416` — the Step 5c dedup comment path — calls `gh issue comment` and breaks identically if the dedup check matches an existing upstream pull request.

ADR-024's own lockstep clause is narrower than the problem. At ADR-024:180 the 2026-05-18 (P249) amendment binds "any future change to the section's **shape** (additional fields, renaming the URL key, alternative format)" to "both skills in the same commit" — and that clause is already stale, because `/wr-itil:update-upstream` has read the section since ADR-024's 2026-06-09 (P080) amendment without the count being updated. Since this decision widens a value rather than changing a shape, the obligation it inherits must bind to the sites that **consume** the value, not to the two skills that parse it. The Confirmation criterion below is written that way deliberately: naming a two-file documentation list would let an engineer ship prose saying "branch on disclosure path" over executables that still call `gh issue view` unconditionally — the exact half-migration the lockstep exists to prevent.

One consequence of that missing discriminator is a live cost the skill change must decide rather than discover. **Every ticket written before this decision carries no pull-request-or-issue marker at all** in the polling script's view. Substituting one `gh pr view` for one `gh issue view` on a correctly-marked ticket is a wash — no change in calls per poll cycle. But a naive back-compatible implementation that probes issue-then-pull-request on unmarked tickets doubles the call count for every legacy ticket on every cycle, against a `gh` rate budget nothing currently governs. There is no data on poll cadence, so treat that as a worst case. Decide the legacy-ticket path explicitly.

Confirmed unaffected, no change needed: `packages/itil/lib/check-outbound-responses-staleness.sh` greps only for section presence and is URL-shape agnostic.

### External communications — the same checks apply, and one surface is not covered

The user's direction ends "same external comms checks apply". A pull request carries **two** outbound surfaces where an issue carries one.

**The prose is already covered, with no change needed.** ADR-028's scope list already names `gh pr create`, `gh pr comment` and `gh pr edit`, and the shipped hook carries the matching arms: `packages/shared/hooks/external-comms-gate.sh:162-167` set `SURFACE` to `gh-pr-create`, `gh-pr-comment` and `gh-pr-edit` respectively. Both evaluators — `wr-risk-scorer:external-comms` and `wr-voice-tone:external-comms` — therefore fire on a pull request title and body exactly as they do on an issue body. The evidence for this claim is the hook on disk, not ADR-028's status, which is `human-oversight: unconfirmed`; nothing here leans on ADR-028's substance.

One cost follows and should be expected rather than diagnosed as a bug. At `external-comms-gate.sh:400` the marker key is computed as `compute_external_comms_key "$DRAFT" "$SURFACE"`, and that helper hashes `sha256(normalize(draft) + '\n' + surface)` (`packages/shared/hooks/lib/external-comms-key.sh`). The surface label is part of the key. A draft first reviewed as `gh-issue-create` and then re-routed to `gh-pr-create` misses its marker and pays a **second full review by both evaluators**, even though the prose is byte-identical. Cost: one extra dual-evaluator review per re-routed draft. There is no telemetry on how often re-routing will happen, so this is recorded as a worst-case assumption rather than a measurement. A separate and pre-existing quirk sits nearby: the draft-*extraction* heredoc pattern at `:252` matches only a here-doc whose delimiter is literally `EOF`, so a body composed with any other delimiter extracts differently and keys differently. That one lives in extraction, not in the key, and is noted here only so the next job does not mistake it for a new defect.

**The diff is not covered.** A pull request puts code into someone else's repository, under our name, judged by their conventions. Nothing scores that. The external-comms gate reads prose only. The pipeline scorer does read diffs, but against **our** policy: `packages/risk-scorer/agents/pipeline.md` reads the local `RISK-POLICY.md` for impact levels and the appetite threshold (`:171`, `:180`) and the local `docs/risks/` catalog for standing risks (`:56`). It has no notion of an upstream's policy or contribution standards. Its action taxonomy is fixed as commit, push and release — ADR-015 (on-demand assessment skills) line 90 registers `assess-release` as "Commit/push/release risk score" — with no action for "open a pull request against a repository we do not own". Locally the gap therefore sits across ADR-015's action taxonomy and `RISK-POLICY.md`, not in any single ADR that owns it.

**Naming this surface is part of this decision. Closing it is not.** Closing it needs its own work, informed by what a first real pull request actually hits, and it must not be smuggled into the skill change.

### Two operating hazards found in pilots, 2026-08-08

Both are recorded as evidence for the cost side of this decision. Neither is decided here.

**Operator-gate inheritance.** A user-global `PreToolUse` hook denied `Edit` and `Write` in a target repository that had zero `PreToolUse` hooks of its own. The hook is `~/.claude/hooks/a11y-enforce-edit.sh`, registered in `~/.claude/settings.json` against the matcher `Edit|Write` with no path scoping, and it returns `permissionDecision: "deny"` (hook source line 52). `--permission-mode bypassPermissions` did **not** override it: a permission mode governs permission prompts, not a hook's explicit deny. A contributing session inherits the **operator's** gates, not the target repository's. The pilot cost $15.62 and produced zero commits.

This refines a claim already on the record. ADR-032 (governance skill invocation patterns) line 121 states that `--permission-mode bypassPermissions` "handles non-interactive permission prompts (verified by probe 4)". That remains true as written; the finding is that it does not extend to hook denials. Clarifying ADR-032's wording is an ADR-032 amendment and is out of scope here.

The consequence for this decision is concrete: contributing into a repository we do not own does not mean working under that repository's rules. It means working under whatever gates the operator's machine imposes, on a tree those gates were never scoped for. A contribution session's gate posture is a real cost of this decision and should be planned for, not discovered.

**The idle guard measures the wrong thing for upstream work.** An AFK idle guard sent `SIGTERM` after 60 minutes of legitimate upstream work. The mechanism is ADR-032's 2026-04-26 (P121) amendment: the orchestrator computes `LAST_ACTIVITY_MARK` as `max(DISPATCH_START_EPOCH, git log -1 --format=%at HEAD)` (ADR-032:143, ADR-032:150) and terminates the subprocess when that mark is older than `IDLE_TIMEOUT_S`, default 3600 seconds, env-overridable via `WORK_PROBLEMS_IDLE_TIMEOUT_S` (ADR-032:151; live in `packages/itil/skills/work-problems/SKILL.md:566` and `:637`). Progress is measured by commits. Upstream work reads and designs for far longer before its first commit than local ticket work does, so the signal reads legitimate work as idleness.

ADR-032 already owns both the signal choice and the threshold, and already documents the env override as the escape hatch. The remedy — a different activity signal, or a longer default for contribution work — is an **ADR-032 amendment** and is deliberately not decided here. It is named so the skill change budgets for it.

## Consequences

### Good

- Tickets whose fix site is upstream become workable instead of accumulating as one-way reports.
- A fix that lands in a shared dependency reaches every adopter of it, not just the reporter.
- Third-party dependencies stop being a terminal case, because fork-and-PR needs no permission we have to negotiate for.
- The prose gate applies unchanged on the new surface, so the user's "same external comms checks apply" holds for the surface that is covered.

### Neutral

- Upstreams that do not accept contributions keep the issue path exactly as it is today.
- **The premise that a pull request is worth more to the recipient than an issue is asserted, not evidenced.** There is no `upstream-maintainer` persona in `docs/jtbd/`, and no documented job describes authoring a contribution into a third party's tree. The claim rests on open-source convention rather than on this repo's own evidence base. Authoring that persona is warranted when the follow-on work tries to close the diff-scoring surface, not before.

### Bad

- **The diff surface is unscored** until separately closed. On a repository we own that is survivable. On a third party's, it is how a contribution gets rejected, or worse, accepted and regretted.
- **Per-report token burn rises materially** — a clone, branch, patch, review and push round trip against one `gh issue create` — and JTBD-010:33 names governance surfaces as accumulating a per-week burn the developer cannot see ahead of time. This decision adds to that burn.
- A re-routed draft pays a second dual-evaluator external-comms review, because the surface label is inside the marker key.
- A ticket now spans two repositories, so its audit trail spans two histories, and every site that branches on the disclosure path has to learn one more value. Legacy tickets carry no value at all, so the back-compat path has its own cost.
- Upstream review and release latency sits between a fix and its arrival here. This one is cheap: ADR-024's P080 and P249 machinery already absorbs waiting-on-upstream asynchronously, so the latency does not land on the reporter's attention.
- Contribution sessions inherit the operator's gates and the commit-based idle guard, both of which are mis-shaped for upstream work today.

## Confirmation

- [ ] `/wr-itil:report-upstream` prefers a pull request over an issue when the upstream accepts pull requests, with the predicate keyed on the upstream's acceptance of contributions and not on our permission level.
- [ ] All four fallbacks are implemented and each routes to the issue path: upstream does not accept contributions; the fix needs a maintainers' design decision; the ticket is security-classified (routing per ADR-024 Step 6 and its P270 amendment, not a re-asserted ban); no defensible fix is in hand.
- [ ] The pull-request body defers to the upstream's `.github/PULL_REQUEST_TEMPLATE.md` when present, and otherwise uses a reduced rationale-plus-cross-reference shape rather than ADR-033's problem-report shape. The issue branch still uses ADR-033's structured default unchanged.
- [ ] Under AFK the pull-request branch degrades to the issue branch and queues the drafted pull request to `## Queued Upstream Report`; no unattended session opens a pull request against a repository we do not own.
- [ ] The new disclosure-path value and **every site that consumes it** land in the same commit: `packages/itil/scripts/check-upstream-responses.sh` (which today has no disclosure-path extraction at all and polls `issue view` unconditionally at `:193`), `packages/itil/scripts/catchup-scan.sh` (`extract_disclosure_path()` at `:136`, branch arms at `:254` and `:256-258`), `packages/itil/skills/update-upstream/SKILL.md:52` (**both** the `gh issue comment` and the `gh issue close` call), `packages/itil/skills/report-upstream/SKILL.md:416` (the Step 5c dedup comment path), and the paired bats and promptfoo fixtures for each. Editing only the two SKILL.md files named in ADR-024:180 satisfies that clause literally and still ships the half-migration.
- [ ] The legacy-ticket path is decided explicitly rather than left to a probe: tickets written before this decision carry no disclosure-path value, and an issue-then-pull-request fallback probe doubles the polling call count for each of them on every cycle.
- [ ] `packages/itil/skills/report-upstream/SKILL.md` names `gh pr create` in its gated-surface section. It currently names only `gh issue create` and the security-advisory `gh api` call, at lines 47 and 524, so the skill would otherwise document gate behaviour that no longer matches what it does.
- [ ] The unscored-diff surface is either closed or carries its own problem ticket. It is not closed by the skill change.
- [ ] ADR-024 carries a reciprocal forward-pointer in its `## Amendments` section naming this ADR. **This is a named precondition of the skill-change job, not of this one** — it is deliberately deferred so that authoring this ADR touches exactly one decision file and does not trip the multi-decision-file architect-gate deadlock.
- [ ] A first real pull request is driven end to end under this decision and the local ticket closed on that evidence, with the two pilot hazards above either avoided or re-observed and reported.

## Pros and Cons of the Options

### Prefer a pull request wherever the upstream accepts them (chosen)

- Good, because it unblocks repositories we own and genuine third-party dependencies under one rule.
- Good, because fork-and-PR needs no permission we have to negotiate for.
- Good, because the prose gate already covers the new surface with no change.
- Bad, because it commits the loop to a second repository's gates, conventions and release cadence.
- Bad, because it opens a diff surface nothing currently scores.

### Prefer a pull request only where we hold write access

- Good, because it is the smaller change and needs no fork handling.
- Bad, because it makes the feature a no-op for the majority of adopters, who are documented consumers rather than owners.
- Bad, because it repeats the failure mode ADR-024 already rejected in its Option 4.

### Keep the issue-only path

- Good, because it costs nothing to adopt and the machinery already works.
- Bad, because it is the current behaviour, and the current behaviour is what produced a backlog of one-way reports whose fixes never land.

### Prefer a pull request and let the AFK loop open it unattended

- Good, because it maximises loop throughput and needs no interactive return.
- Bad, because it lets a prose-only gate authorise code into a third party's repository under our name, which JTBD-006:36 rules out. Rejected.

## Reassessment Criteria

Revisit if any of the following holds:

- The two-repo round trip costs more than the tickets it clears, measured against JTBD-010's per-week burn rather than per-report.
- A pull request opened under this decision is rejected or reverted on grounds the unscored-diff surface would have caught, which would promote closing that gap from follow-on work to a precondition.
- Upstream review latency strands tickets longer than the issue path did, despite the P080 and P249 asynchronous machinery.
- Evidence accumulates that upstream maintainers prefer an issue to an unsolicited pull request, which would falsify the asserted premise recorded under Consequences and warrant authoring the missing `upstream-maintainer` persona before going further.

## Related

- [ADR-073](./073-fix-time-gate-auto-creates-missing-rfc.proposed.md) — RFC-first. Its Decision Outcome clause 3 is why this ADR exists and why it must be ratified before the skill change is built.
- [ADR-024](./024-cross-project-problem-reporting-contract.proposed.md) — cross-project problem-reporting contract. Amended: the outbound-artefact choice gains a pull-request branch ahead of Step 5, and Step 7's disclosure-path enumeration gains a value. Its issue path remains in force as the fallback. Its P270 security-path routing binds the skill change, and its P249 lockstep at `:180` is inherited in the broadened form described above.
- [ADR-033](./033-report-upstream-classifier-problem-first.proposed.md) — report-upstream classifier is problem-first. Amended: the structured default body applies to the issue branch; the pull-request branch defers to the upstream's own template.
- [ADR-028](./028-voice-tone-gate-external-comms.proposed.md) — external-comms gate. Cited as needing no change; the evidence is the shipped hook arms at `packages/shared/hooks/external-comms-gate.sh:162-167`, not ADR-028's unratified substance.
- [ADR-015](./015-on-demand-assessment-skills.proposed.md) — on-demand assessment skills. Line 90 fixes the pipeline scorer's action taxonomy as commit, push and release; together with `RISK-POLICY.md` it is the local home of the unscored-diff gap named above.
- [ADR-032](./032-governance-skill-invocation-patterns.proposed.md) — governance skill invocation patterns. Owns both pilot hazards: line 121 on `bypassPermissions`, and the P121 amendment's commit-based idle signal at lines 143, 150 and 151. Both remedies are ADR-032 amendments, out of scope here.
- [ADR-014](./014-governance-skills-commit-their-own-work.proposed.md) — governance skills commit their own work. Hosts the registry of governance-commit subject shapes; the skill change should either reuse the existing "problem reported upstream" row or register one for the pull-request branch.
- [ADR-004](./004-project-scoped-plugin-install.proposed.md) — project-scoped plugin install by default. The operator-gate-inheritance hazard is a live witness for the concern its Context already describes.
- [ADR-077](./077-decisions-compendium-as-token-cheap-load-surface.proposed.md) — the decisions compendium as the routine architect load surface. Its generator harvests relationship edges from `## Related` bullets and from the `supersedes` frontmatter field, and has no `amends` handler — which is why ADR-024 and ADR-033 appear as bullets here and not in frontmatter alone.
- JTBD-001 (Enforce Governance Without Slowing Down), JTBD-006 (Progress the Backlog While I'm Away), JTBD-010 (Sustain My Token Quota), JTBD-301 (Report a Problem Without Pre-Classifying It) — the ratified jobs this decision serves and strains, cited by line above.
- The Windy Road delivery repo's decision number 048, ratified 2026-08-08 — the downstream decision that prompted this one. Read-only reference. It records a downstream project's posture toward its upstreams; this ADR records the plugin's behaviour for every adopter. Its attribution of the unscored-diff gap to that repo's own decision number 008 does not transfer here. Both numbers are written in longhand deliberately: the compendium generator harvests bare `ADR-NNN` tokens from this section as local relationship edges, and in `ADR-NNN` form they would resolve to two unrelated local decisions.
