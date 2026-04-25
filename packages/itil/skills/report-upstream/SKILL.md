---
name: wr-itil:report-upstream
description: Report a local problem ticket as a structured issue against an upstream repository, with bidirectional cross-references and SECURITY.md-aware routing for security-classified tickets. Implements the contract in ADR-024, with ADR-033 governing problem-first classifier + default body shape.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill, Agent
---

# Report Upstream — Cross-Project Problem-Reporting Skill

File a local `docs/problems/<NNN>` ticket as an issue (or private security advisory) against an upstream repository. Discover upstream issue templates, fall through to a structured default when none exist, route security-classified tickets via the upstream's `SECURITY.md`, and back-write a cross-reference into the local ticket.

This skill implements the contract documented in [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) (Cross-project problem-reporting contract). All step numbering below maps 1:1 to ADR-024 Decision Outcome.

[ADR-033](../../../docs/decisions/033-report-upstream-classifier-problem-first.proposed.md) (Report-upstream classifier is problem-first) partially supersedes ADR-024 Decision Outcome **Steps 3 and 5 only** — the classifier is problem-first with best-fit backward-compat fallback (per Step 3 below), and the structured default body is problem-shaped (per Step 5 below). ADR-024 Steps 1, 2, 4, 6, 7, 8 and all Consequences / Confirmation clauses remain in force unchanged.

The **ADR-024 amendment of 2026-04-25 (P070)** adds Step 4b (dedup check — own re-run + third-party search via `gh issue list --search` + inline LLM semantic match) and Step 5c (comment path — `gh issue comment` with cross-reference body when dedup match found). The maintainer-annoyance risk evaluator named in the P070 Direction decision is deferred to compose with the `wr-risk-scorer:external-comms` subagent declared in ADR-028 (per ADR-028 line 117 — third-evaluator extension point); the AFK auto-comment branch is on the interim **static heuristic** described in Step 4b until that evaluator lands. See Step 4b below.

## Invocation

```
/wr-itil:report-upstream <local-problem-id> <upstream-repo-url> [--severity <level>] [--classification <kind>] [--evidence-url <url>]
```

- `<local-problem-id>`: the `NNN` of the local ticket (e.g. `058`).
- `<upstream-repo-url>`: GitHub URL of the upstream repo (e.g. `https://github.com/anthropics/claude-code`).
- `--severity`: optional, overrides the local ticket's severity inference.
- `--classification`: optional, one of `bug`, `feature`, `question`, `security`. Inferred when absent.
- `--evidence-url`: optional, an external link (transcript, screenshot, gist) to include in the report.

## Step-0 deferral (ADR-027)

This skill **does NOT** implement ADR-027's Step-0 auto-delegation pattern. Per ADR-027 Scope, `report-upstream` is held for reassessment with the explicit note: *"narrow workflow; decided at implementation time for that skill"*. Reasons for deferring Step-0 here:

- The skill's main-agent context is the right place to read the local ticket, evaluate the security-path branch, and surface the missing-`SECURITY.md` `AskUserQuestion` to the user. Wrapping the flow in a subagent adds a hop without reducing main-agent context cost (the local ticket and ADR-024 contract still need to be in main-agent context for the user's interactive decisions).
- The interactive `AskUserQuestion` for the missing-SECURITY.md case (Step 6 below) is a per-decision turn the user owns; a subagent would have to bubble it back up anyway.
- The skill's footprint is small (one local doc edit + one or two `gh` API calls per invocation).

**Trigger to revisit**: if a second skill that reads upstream repo content lands (per ADR-024's Reassessment Criteria), reconsider whether the cross-cutting "read upstream" pattern should move into a Step-0-delegated subagent that this skill calls.

## Voice-tone gate interaction (ADR-028)

The skill's `gh issue create` (Step 5) and `gh api repos/.../security-advisories` (Step 6) calls are **on the gated surface list per [ADR-028](../../../docs/decisions/028-voice-tone-gate-external-comms.proposed.md)** (Voice-tone gate on external communications). Expected behaviour during these tool calls:

1. The voice-tone gate fires `PreToolUse:Bash` with a deny-plus-delegate response.
2. The hook delegates to `wr-voice-tone:agent` to review the drafted body for brand-voice + tone alignment against `docs/VOICE-AND-TONE.md`.
3. Once the agent's marker lands, the same `gh issue create` or `gh api` call retries and proceeds.

The skill should treat this transient deny-plus-delegate as the expected path, not as an error. The voice-tone agent's review covers only the prose body of the upstream report (issue body, advisory body); structural fields (template field IDs, plugin name, version) are not in voice-tone scope.

If `wr-voice-tone:agent` is not installed in the project, the gate is dormant and the skill proceeds without delegation.

## Steps

### 1. Read the local problem ticket

```bash
LOCAL_TICKET=$(ls docs/problems/${LOCAL_ID}-*.{open,known-error,verifying,closed}.md 2>/dev/null | head -1)
[ -n "$LOCAL_TICKET" ] || { echo "Error: local ticket P${LOCAL_ID} not found in docs/problems/"; exit 1; }
```

Extract:
- Title (from H1).
- Status (from frontmatter Status field — Open / Known Error / Verification Pending / Closed).
- Description, Symptoms, Workaround, Impact Assessment, Root Cause Analysis sections.
- Priority and severity classification (look for a `security` label or a `## Security classification` section — see Step 4).

If the ticket is not found, halt with a clear error: `Error: local ticket P<NNN> not found in docs/problems/. Did you mean a different ID?`

### 2. Discover upstream issue templates

```bash
UPSTREAM_OWNER_REPO=$(echo "$UPSTREAM_URL" | sed -E 's|https?://github.com/([^/]+/[^/]+)(/.*)?|\1|')
TEMPLATES_JSON=$(gh api "repos/${UPSTREAM_OWNER_REPO}/contents/.github/ISSUE_TEMPLATE" 2>/dev/null)
```

Parse the response:
- HTTP 200 with a JSON array → upstream has templates. List the names + types (`.yml` for forms, `.md` for legacy markdown templates).
- HTTP 404 → upstream has no `.github/ISSUE_TEMPLATE/` directory; treat as no-templates (proceed to structured default in Step 5).
- Other HTTP error (rate-limit, network) → halt with a clear error and the response body so the user can retry.

For each `.yml` template found, fetch the file via `gh api repos/<owner>/<repo>/contents/.github/ISSUE_TEMPLATE/<filename>` and parse the `name:` frontmatter field plus the `body:` field-IDs that have `validations.required: true`.

### 3. Classify the local ticket and pick the best-matching template

This step is governed by [ADR-033](../../../docs/decisions/033-report-upstream-classifier-problem-first.proposed.md) (Report-upstream classifier is problem-first), which partially supersedes ADR-024 Decision Outcome Step 3. Classification is **problem-first with best-fit backward-compat fallback** — upstream repos that have adopted the problem-first intake shape (per `@windyroad/itil`) are targeted first; older repos that still ship bug/feature/question templates are served via a fallback.

**Preference order** (first match wins):

1. **`problem` shape (primary)** — any of the tokens `problem`, `issue`, `concern`, `defect`, `gap` appear in the local ticket title or body; or the body contains a scoped-npm package reference (`@scope/name`); or the body contains any of `root cause`, `reproduction`, `workaround`. This is the default for tickets authored via `/wr-itil:manage-problem`.
2. **`bug` shape (backward-compat fallback)** — no primary tokens match, and the prose is defect-like (contains `broken`, `fails`, `error`, `bug`, `regression`, or a specific observed-vs-expected contrast). Produces a bug-shaped body only when the upstream has no `problem-report.yml`.
3. **`feature` shape (backward-compat fallback)** — no primary tokens match, and the prose is proposal-like (contains `would be nice`, `enhancement`, `feature request`, `could we`, `wish`).
4. **`question` shape (backward-compat fallback)** — trailing fallback when the prose is a genuine question (ends in `?`, contains `how do I`, `is there a way`).

The CLI `--classification` argument overrides the heuristic. The security-path check in Step 4 fires **before** this classifier — security-classified tickets bypass the classifier entirely.

**Template-discovery preference order** (extends ADR-024 Step 1; search the upstream `.github/ISSUE_TEMPLATE/` directory in this order, first match wins):

1. `problem-report.yml` — preferred; the Windy-Road problem-first shape.
2. `problem.yml` — alternate naming for problem-shaped templates.
3. `problem-report.md` / `problem.md` — legacy markdown variants of the problem-shaped template.
4. `bug-report.yml` / `bug.yml` / `bug-report.md` / `bug.md` — if primary classifier picked `bug` shape OR no problem template exists and fallback is `bug`.
5. `feature-request.yml` / `feature.yml` / `feature-request.md` — `feature` shape fallback.
6. `question.yml` / `question.md` — `question` shape fallback. If absent, the upstream's `config.yml` likely routes questions elsewhere (Discussions); halt and surface the routing target.
7. Structured default body per Step 5 below — if no template matches.

Log the matched template name (or `structured default`) in the Step 7 back-write. If no template matches the classification, fall through to the structured default in Step 5.

### 4. Security-path routing check

The local ticket is **security-classified** if any of:
- Its title contains `security`, `vulnerability`, `CVE`, `disclosure`, `RCE`, `injection`, `XSS`, or `auth bypass`.
- Its frontmatter `Priority:` line contains a `security` label.
- The ticket body has a `## Security classification` section.
- The CLI `--classification security` argument was passed.

If security-classified, route to Step 6. Otherwise, route to Step 4b (dedup check) before Step 5 (public-issue path).

### 4b. Dedup check (P070)

This step is governed by the [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) 2026-04-25 amendment, which adds dedup checking to the Decision Outcome step list (P070). Two duplication windows close at the same insertion point: own re-run (4b.1) and third-party search (4b.2). Both branches share the same AskUserQuestion surface and the same AFK halt-and-save behaviour.

> **Serves**: JTBD-004 (cross-repo coordination — dedup is the difference between coordination and spam), JTBD-001 (solo developer "without slowing down" — dedup protects the user from policing upstream duplicates manually), JTBD-006 (AFK persona — halt-and-surface protects loops from duplicate-firing), JTBD-101 (clear pattern — pattern ships without a duplication hole).

#### 4b.1. Own re-run check

Detect whether the local ticket already records a previous upstream report. The `## Reported Upstream` section is written by Step 7 (cross-reference back-write) on a successful prior invocation; its presence means the skill has already filed (or commented) for this local ticket.

```bash
LOCAL_URL=$(grep -A5 '^## Reported Upstream' "$LOCAL_TICKET" | grep -oE 'https?://[^ )]+' | head -1)
if [ -n "$LOCAL_URL" ]; then
  echo "Local ticket P${LOCAL_ID} already records an existing upstream report: $LOCAL_URL"
  # Branch interactive vs AFK below.
fi
```

**Interactive branch** — use `AskUserQuestion` per ADR-013 Rule 1:

- `header: "Existing upstream report"`
- `multiSelect: false`
- Options:
  1. `Halt — local ticket already records ${LOCAL_URL}` (Recommended) — abort the invocation; the existing report is current.
  2. `Comment on the existing upstream report` — route to Step 5c with the existing URL's issue number; appropriate when new evidence has emerged since the previous report.
  3. `File a new upstream issue anyway (override)` — explicit override after user has reviewed the existing record and judged the second filing warranted (e.g. previous report was closed without resolution and a fresh tracker is needed).

**AFK / non-interactive branch** — apply the **interim static heuristic** (no subagent dispatch; the maintainer-annoyance risk evaluator is deferred per ADR-028 line 117 — see "AFK static heuristic" below). Default action: halt and save the drafted report to the local ticket's `## Drafted Upstream Report` section; do NOT auto-comment. The static heuristic remains in place until `wr-risk-scorer:external-comms` ships, at which point the AFK branch wires the gate combination (maintainer-annoyance + leak gate, both within appetite) per the ticket Direction decision (2026-04-21).

#### 4b.2. Third-party search

Detect whether a different reporter (or another agent in a parallel session) has already filed a similar issue against the upstream. The Direction decision (2026-04-21) pins a two-stage mechanism: a `gh issue list --search` pre-filter that trims candidates to ~5-10, followed by an **inline LLM semantic match** that judges each candidate's body against the proposed report.

```bash
# Stage 1: gh-search pre-filter on title keywords (cheap, ~500ms-2s).
KEYWORDS=$(extract_3-5_keywords_from "$LOCAL_TICKET_TITLE + $LOCAL_TICKET_DESCRIPTION")
MATCHES=$(gh issue list \
  --repo "$UPSTREAM_OWNER_REPO" \
  --state all \
  --search "$KEYWORDS" \
  --json number,title,state,url \
  --limit 10)
```

For each candidate returned by Stage 1, fetch the full body and run **Stage 2 — inline LLM semantic judgement**:

```bash
# Stage 2: per-candidate body fetch + inline classification.
for n in $(echo "$MATCHES" | jq -r '.[].number'); do
  CANDIDATE=$(gh issue view "$n" --repo "$UPSTREAM_OWNER_REPO" --json title,body,state,url)
  # Inline LLM judgement: read {local ticket Description + Symptoms, candidate title + body}
  # and return one of: same-problem | different-problem | uncertain.
  # No subagent dispatch — Direction decision 2026-04-21 pins inline classification
  # for simplicity. Promotion to a `wr-itil:dedup-check` subagent is a future
  # ADR amendment if architect review later flags context-isolation concerns.
done
```

Notes on inline LLM classification:

- **No subagent dispatch.** The skill's main-agent context already has the local ticket loaded (Step 1) and the candidate body in scope after `gh issue view`. The Direction decision (2026-04-21) pins inline classification to keep the dedup affordable; the gh-search pre-filter trims input to ~5-10 candidates so the inline reads stay bounded.
- **Verdicts**: `same-problem` (route to AskUserQuestion with the matched URL); `different-problem` (skip, continue); `uncertain` (always surface to user — never auto-resolve).
- **Heuristic for "same problem"**: same root cause described, overlapping symptoms, same affected component or scoped npm package. Different reproduction environment alone does NOT downgrade to `different-problem` — environment heterogeneity is normal.

If Stage 2 produces one or more `same-problem` matches, surface them to the user in interactive mode:

- `header: "Existing upstream issue may match"`
- `multiSelect: false`
- Options:
  1. `Comment on #<N> (Recommended) — <title>` — one option per `same-problem` match; routes to Step 5c with that issue number.
  2. `File a new upstream issue anyway (override)` — explicit override; user has reviewed the matches and judged them distinct.
  3. `Cancel` — abort without filing or commenting.

`uncertain` matches surface alongside `same-problem` matches with their verdict labelled, so the user can review. The skill never auto-resolves an `uncertain` verdict.

**AFK / non-interactive branch** — apply the same interim static heuristic as 4b.1: halt and save the drafted report to the local ticket's `## Drafted Upstream Report` section. The third-party-match auto-comment path requires the deferred `wr-risk-scorer:external-comms` gate (maintainer-annoyance + leak), so the AFK branch must NOT auto-comment under the static heuristic.

#### AFK static heuristic (interim, until `wr-risk-scorer:external-comms` ships)

The Direction decision (2026-04-21) pins the AFK auto-comment branch on **two gates passing together**: the maintainer-annoyance risk evaluator AND the P064 external-comms leak gate, both within RISK-POLICY.md's commit-layer appetite (Low, ≤4/25). Neither gate exists yet — ADR-028 declares the `wr-risk-scorer:external-comms` subagent type but P064's implementation is open at WSJF 3.0 (Effort L), and the maintainer-annoyance evaluator was deferred by architect review on P070 to compose with the same subagent rather than ship as a separate evaluator (per ADR-028 line 117 — *"Third evaluator (licence-compliance, etc.) adding to the same gate — when it emerges, amend this ADR's evaluator list and the composite marker's `evaluator_set` component; no new ADR expected."*).

**Static heuristic, valid until both gates ship**: in AFK mode, both 4b.1 and 4b.2 default to **halt and save the drafted report**. No auto-comment, no auto-file. The drafted report is appended to the local ticket's `## Drafted Upstream Report` section so the user can review and act manually on return. This matches JTBD-006's "does not trust the agent to make judgement calls" stance — the conservative default is the right interim behaviour.

**Re-wire trigger**: when `wr-risk-scorer:external-comms` lands (ADR-028 implementation, P064 closure), amend this section to invoke both evaluators and proceed with auto-comment ONLY when both verdicts return PASS within appetite. Update the AFK behaviour summary table accordingly. Until then, the static heuristic stands.

**Drafted Upstream Report save format** (used by both 4b.1 and 4b.2 AFK halts; mirrors the security-path halt pattern from Step 6 per ADR-024 Consequences lines 116, 123):

```markdown
## Drafted Upstream Report

- **Drafted**: <YYYY-MM-DD>
- **Target upstream**: <upstream-repo-url>
- **Halt reason**: dedup match (own re-run | third-party `same-problem`) — interim static heuristic awaiting `wr-risk-scorer:external-comms` (ADR-028 / P064)
- **Matched URL(s)**: <existing-issue-or-report-URL(s)>
- **Drafted body**:

  <the body that would have been posted as a `gh issue comment` or `gh issue create`, ready for manual copy-paste review>
```

The halt is a loop-stopping event for AFK orchestrators — same pattern as the security-path halt-and-surface branch — so the user sees the dedup match on return rather than the orchestrator silently auto-commenting.

### 5. Public-issue path

This step is governed by [ADR-033](../../../docs/decisions/033-report-upstream-classifier-problem-first.proposed.md) (Report-upstream classifier is problem-first), which partially supersedes ADR-024 Decision Outcome Step 5. The primary structured default body is **problem-shaped** and mirrors the `/wr-itil:manage-problem` ticket shape; the bug-shaped / feature-shaped / question-shaped bodies are retained as fallback-only templates for the backward-compat branches of the Step 3 classifier.

If the upstream had a matching template (Step 3), fill its required fields from the local ticket. Field-mapping table for the problem-first case (problem-report.yml template):

| Upstream template field (typical) | Local ticket source |
|---|---|
| `plugin` / `package` / `module` | Inferred from upstream repo name or local ticket's "Affected plugin / component" |
| `version` | Local ticket's environment notes; or `npm view <pkg> version` for the latest if ambiguous |
| `claude-code-version` | `claude --version` if the report originates from a Claude Code session |
| `os` | Local ticket's environment notes; or `uname -srm` of the reporting host |
| `description` | Local ticket's `## Description` section |
| `symptoms` | Local ticket's `## Symptoms` section |
| `workaround` | Local ticket's `## Workaround` section (or "None identified yet.") |
| `frequency` | Local ticket's `## Impact Assessment` Frequency line |
| `evidence` | Commit SHAs, test output, transcript excerpts from Investigation Tasks |

For upstream repos whose matched template is `bug-report.yml` / `feature-request.yml` / `question.yml` (Step 3 backward-compat fallback), the skill fills the corresponding field set: `reproduction` ← `## Symptoms`; `expected` / `actual` ← observed-vs-expected contrast lines under `## Description`; `proposal` (for features) ← `## Description`.

#### Structured default body — problem-shaped (primary, per ADR-033)

Use this body when the Step 3 classifier picked `problem` shape AND the upstream has no `problem-report.yml` / `problem.yml` / `problem-report.md` / `problem.md`:

```markdown
## Description

<one-paragraph synthesis of the local ticket's Description>

## Symptoms

<bullet list from local ticket's Symptoms>

## Workaround

<from local ticket's Workaround section; "None identified yet." if absent>

## Affected plugin / component

<inferred from the local ticket's Impact Assessment or inferred from context>

## Frequency

<from the local ticket's Impact Assessment "Frequency" line>

## Environment

- Package: <inferred from upstream repo>
- Version: <detected via npm ls or local ticket's notes>
- Claude Code version: <claude --version>
- OS: <uname -srm>

## Evidence

<commit SHAs, test output, transcript excerpts — drawn from the local ticket's Investigation Tasks>

## Cross-reference

Reported from <downstream-repo-url>/<local-ticket-relative-path>

This issue is tracked locally as P<NNN> in the downstream project's `docs/problems/` directory.
```

The body MUST include the `## Cross-reference` section so Step 7's back-write contract works (the downstream ticket's `## Reported Upstream` section records the upstream URL; the upstream issue body records the downstream reference).

#### Structured default body — bug-shaped (fallback-only)

Use this body only when the Step 3 classifier picked `bug` shape as backward-compat fallback (no primary `problem` tokens matched) AND the upstream has no matching template:

```markdown
## Summary

<one-paragraph synthesis of the local ticket's Description>

## Steps to reproduce

<bullet list or numbered steps from local ticket's Symptoms>

## Expected behaviour

<from local ticket>

## Actual behaviour

<from local ticket>

## Environment

- Package: <inferred from upstream repo>
- Version: <detected via npm ls or local ticket's notes>
- Claude Code version: <claude --version>
- OS: <uname -srm>

## Cross-reference

Reported from <downstream-repo-url>/<local-ticket-relative-path>

This issue is tracked locally as P<NNN> in the downstream project's `docs/problems/` directory.
```

#### Structured default body — feature-shaped (fallback-only)

Use this body only when the Step 3 classifier picked `feature` shape as backward-compat fallback AND the upstream has no matching template:

```markdown
## Proposal

<one-paragraph synthesis of the local ticket's Description>

## Motivation

<why this matters, from local ticket's Impact Assessment>

## Alternatives considered

<from local ticket's Root Cause Analysis or Candidate fix options>

## Cross-reference

Reported from <downstream-repo-url>/<local-ticket-relative-path>

This issue is tracked locally as P<NNN> in the downstream project's `docs/problems/` directory.
```

#### Structured default body — question-shaped (fallback-only)

Use this body only when the Step 3 classifier picked `question` shape as backward-compat fallback AND the upstream has no matching template (and no `config.yml` re-routing to Discussions):

```markdown
## Question

<the question itself, from the local ticket's title or Description>

## Context

<what prompted the question, from local ticket's Description or Symptoms>

## Cross-reference

Reported from <downstream-repo-url>/<local-ticket-relative-path>

This issue is tracked locally as P<NNN> in the downstream project's `docs/problems/` directory.
```

Open the issue:

```bash
gh issue create \
  --repo "${UPSTREAM_OWNER_REPO}" \
  --title "${TITLE_PREFIXED_BY_TEMPLATE}" \
  --body "${FILLED_BODY}" \
  --label "${MATCHED_TEMPLATE_LABEL_IF_ANY}"
```

Capture the returned issue URL. The voice-tone gate per ADR-028 may delegate-and-retry; treat this as expected (see "Voice-tone gate interaction" above). Proceed to Step 7 once the issue is created.

### 5c. Comment path (P070)

Used when Step 4b's dedup check (own re-run or third-party search) finds a match AND the user picks the "comment instead" option. Skips `gh issue create` and posts a cross-reference comment on the existing upstream issue:

```bash
gh issue comment "${EXISTING_ISSUE_NUMBER}" \
  --repo "${UPSTREAM_OWNER_REPO}" \
  --body "${COMMENT_BODY}"
```

The comment body is a condensed cross-reference, not a full report restatement. Required structure:

```markdown
Seeing this from <downstream-repo-url>/<local-ticket-relative-path>.

## Additional context

- **Local ticket**: P<NNN> (<one-line title>)
- **Reproduction**: <if local has a fresh repro path the existing issue lacks; otherwise omit>
- **Environment**: <if differs materially from the existing issue; otherwise omit>
- **Hypothesis**: <if local has a contradictory or extending root-cause hypothesis; otherwise omit>

This issue is tracked locally as P<NNN> in the downstream project's `docs/problems/` directory.
```

Empty subsections are skipped — the comment should add information, not restate what the existing issue already records. If none of the four "additional context" subsections has content, the comment defaults to a one-line acknowledgement: `Seeing this from <downstream-repo-url>/<local-ticket-relative-path>. Tracked locally as P<NNN>.` This is still useful — it tells the upstream maintainer they have a downstream witness — without spamming the thread with redundant content.

The voice-tone gate per ADR-028 also fires on `gh issue comment` (per the canonical hook's regex list at ADR-028 line 61); treat the deny-plus-delegate-and-retry as expected, same as Step 5.

Capture the returned comment URL (gh prints `https://github.com/<owner>/<repo>/issues/<n>#issuecomment-<id>`). The Step 7 back-write records this as the cross-reference URL with disclosure path `commented-on-existing-issue`. Proceed to Step 7.

### 6. Security path

Fetch the upstream's `SECURITY.md`:

```bash
SECURITY_MD=$(gh api "repos/${UPSTREAM_OWNER_REPO}/contents/SECURITY.md" --jq '.content' 2>/dev/null | base64 -d)
```

Parse for a disclosure channel:

- **GitHub Security Advisories** (most common — link looks like `github.com/<owner>/<repo>/security/advisories/new` or the body says "use Security Advisories"):
  ```bash
  gh api "repos/${UPSTREAM_OWNER_REPO}/security-advisories" --method POST \
    --input - <<EOF
  {
    "summary": "${TITLE}",
    "description": "${STRUCTURED_BODY}",
    "severity": "${SEVERITY}",
    "vulnerabilities": []
  }
  EOF
  ```
- **`security@` mailbox** (or any `mailto:` link): **halt** and surface the mailbox + drafted report to the user. Do NOT auto-send email — out of scope, no infra. Save the drafted report to `docs/problems/<NNN>-<title>.<status>.md`'s `## Drafted Upstream Report` appendage section so the user can copy + send.
- **Other documented channel** (Tidelift, HackerOne, vendor-specific URL): halt and surface the channel + drafted report.

If upstream has **NO `SECURITY.md`** (404):
- **Interactive context**: use `AskUserQuestion` per ADR-013 Rule 1 with options:
  - `(a) Open a private GitHub Security Advisory` — uses `gh api repos/.../security-advisories` against the upstream if it's GitHub-hosted.
  - `(b) Contact the maintainer out-of-band first` — halt, no automated action.
  - `(c) Downgrade the classification (your judgement)` — re-route via the public-issue path in Step 5.
- **AFK / non-interactive context**: do NOT auto-resolve. Save the drafted report to the local ticket's `## Drafted Upstream Report` section and **halt the orchestrator** — this is a loop-stopping event per ADR-024 Consequences. AFK orchestrators must never auto-report a security-classified ticket.

**Never auto-open a public issue for a security-classified ticket.**

### 7. Cross-reference back-write

After the upstream issue or advisory is created (or drafted-and-saved in the security-path halt cases), append two things to the local ticket:

1. To the existing `## Related` section (or create one if absent):
   ```markdown
   - **Reported upstream**: <upstream-issue-or-advisory-url> (<YYYY-MM-DD>)
   ```

2. A new `## Reported Upstream` section appended after the existing sections (never inserted mid-document — preserve existing structure):
   ```markdown
   ## Reported Upstream

   - **URL**: <upstream-issue-or-advisory-url>
   - **Reported**: <YYYY-MM-DD>
   - **Template used**: <template-name-or-"structured default">
   - **Disclosure path**: <public issue | security advisory | drafted-and-saved (mailbox / out-of-band) | commented-on-existing-issue (Step 5c, P070)>
   - **Cross-reference confirmed**: <yes/no — true once the upstream issue body contains the local ticket reference>
   ```

### 8. Commit per ADR-014

Follow the ADR-014 ordering:

1. `git add docs/problems/<NNN>-<title>.<status>.md` (and any `## Drafted Upstream Report` appendage if security-path halt fired).
2. Score commit/push/release risk via `wr-risk-scorer:pipeline` subagent (or fall back to `/wr-risk-scorer:assess-release` skill per ADR-015).
3. `git commit -m "docs(problems): P<NNN> reported upstream — <one-line summary>"`.

If the cumulative pipeline risk lands above appetite and `AskUserQuestion` is unavailable, apply the [ADR-013 Rule 6](../../../docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) non-interactive fail-safe: skip the commit and report the uncommitted state. Do NOT auto-commit above appetite without the user's call.

## AFK behaviour summary

Five distinct AFK branches per the architect reviews of ADR-024, ADR-013 Rule 6, and the P070 dedup amendment:

| Branch | AFK behaviour | Authority |
|---|---|---|
| Public-issue path (Step 5) | Proceeds. Voice-tone gate per ADR-028 may delegate-and-retry; that is the expected extra turn. | ADR-028 line 126 |
| Dedup match — Step 4b halt (own re-run OR third-party `same-problem`) | Save drafted report to local ticket's `## Drafted Upstream Report` section. **Halt the orchestrator** — loop-stopping event. Interim static heuristic; auto-comment branch deferred until `wr-risk-scorer:external-comms` ships (ADR-028 line 117). | ADR-024 amendment 2026-04-25 (P070); Direction decision 2026-04-21 |
| Security path with declared channel (Step 6, GitHub Advisories) | Proceeds via `gh api .../security-advisories`. | ADR-024 Decision Outcome step 6 |
| Security path with `security@` / other / missing-SECURITY.md (Step 6) | Save drafted report to local ticket's `## Drafted Upstream Report` section. **Halt the orchestrator** — loop-stopping event. AFK orchestrators must never auto-report a security-classified ticket. | ADR-024 Consequences lines 116, 123 |
| Above-appetite commit (Step 8) | Skip the commit, report uncommitted state. | ADR-013 Rule 6 |

## References

- [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) — primary contract this skill implements. Steps 1, 2, 4, 6, 7, 8 and all Consequences remain authoritative; the 2026-04-25 amendment adds Step 4b (dedup) + Step 5c (comment path) for P070.
- [ADR-033](../../../docs/decisions/033-report-upstream-classifier-problem-first.proposed.md) — partially supersedes ADR-024 Decision Outcome Steps 3 + 5; governs the problem-first classifier and problem-shaped structured default body.
- [P070](../../../docs/problems/) — driver ticket for the Step 4b dedup check + Step 5c comment path; carries the 2026-04-21 Direction decision (gh search + inline LLM, no subagent dispatch) and the AFK static-heuristic interim behaviour.
- [ADR-027](../../../docs/decisions/027-governance-skill-auto-delegation.proposed.md) — Step-0 deferral rationale (held for reassessment).
- [ADR-028](../../../docs/decisions/028-voice-tone-gate-external-comms.proposed.md) — voice-tone gate on `gh issue create` and `gh api .../security-advisories`.
- [ADR-013](../../../docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) — interaction policy; Rule 1 governs Step 6 missing-SECURITY.md `AskUserQuestion`; Rule 6 governs the commit-gate AFK branch.
- [ADR-014](../../../docs/decisions/014-governance-skills-commit-their-own-work.proposed.md) — work → score → commit ordering.
- [ADR-015](../../../docs/decisions/015-on-demand-assessment-skills.proposed.md) — fallback path for `wr-risk-scorer:assess-release`.
- [P055](../../../docs/problems/055-no-standard-problem-reporting-channel.open.md) — upstream problem ticket (Part B).
- **P066** — intake templates in this repo adopted the problem-first shape (must ship before P067 so the skill's preference order matches the reference shape).
- **P067** — driver ticket for the problem-first classifier reform implemented via ADR-033.
- `packages/itil/skills/manage-problem/SKILL.md` — names the optional `## Reported Upstream` section as an allowed appendage to a problem ticket.

$ARGUMENTS
