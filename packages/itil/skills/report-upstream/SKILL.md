---
name: wr-itil:report-upstream
description: Report a local problem ticket as a structured issue against an upstream repository, with bidirectional cross-references and SECURITY.md-aware routing for security-classified tickets. Implements the contract in ADR-024.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Report Upstream — Cross-Project Problem-Reporting Skill

File a local `docs/problems/<NNN>` ticket as an issue (or private security advisory) against an upstream repository. Discover upstream issue templates, fall through to a structured default when none exist, route security-classified tickets via the upstream's `SECURITY.md`, and back-write a cross-reference into the local ticket.

This skill implements the contract documented in [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) (Cross-project problem-reporting contract). All step numbering below maps 1:1 to ADR-024 Decision Outcome.

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

Heuristic:
- Local ticket title contains `bug`, `defect`, `crash`, `error`, `fails to`, `broken`, `regression` → classify as `bug`.
- Local ticket title contains `feature`, `add`, `support for`, `would be nice`, `enhancement` → classify as `feature`.
- Local ticket title is a question → classify as `question`.
- The CLI `--classification` argument overrides the heuristic.

Pick the upstream template whose `name:` (or filename) most closely matches the classification:
- For `bug`: prefer `bug-report.yml`, `bug.yml`, `bug-report.md`, `bug.md`.
- For `feature`: prefer `feature-request.yml`, `feature.yml`, `feature-request.md`.
- For `question`: prefer `question.yml`, `question.md`. If absent, the upstream's `config.yml` likely routes questions elsewhere (Discussions); halt and surface the routing target.

Log the matched template name in the Step 7 back-write. If no template matches the classification, fall through to the structured default in Step 5.

### 4. Security-path routing check

The local ticket is **security-classified** if any of:
- Its title contains `security`, `vulnerability`, `CVE`, `disclosure`, `RCE`, `injection`, `XSS`, or `auth bypass`.
- Its frontmatter `Priority:` line contains a `security` label.
- The ticket body has a `## Security classification` section.
- The CLI `--classification security` argument was passed.

If security-classified, route to Step 6. Otherwise, route to Step 5 (public-issue path).

### 5. Public-issue path

If the upstream had a matching template (Step 3), fill its required fields from the local ticket:

| Upstream template field (typical) | Local ticket source |
|---|---|
| `plugin` / `package` / `module` | Inferred from upstream repo name or local ticket's "Affected plugin" section |
| `version` | Local ticket's environment notes; or `npm view <pkg> version` for the latest if ambiguous |
| `claude-code-version` | `claude --version` if the report originates from a Claude Code session |
| `os` | Local ticket's environment notes; or `uname -srm` of the reporting host |
| `reproduction` | Local ticket's `## Symptoms` section |
| `expected` | Local ticket's "expected behaviour" line under `## Description` |
| `actual` | Local ticket's "actual behaviour" line under `## Description` |

If no template matches, emit the **structured default** body:

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

Open the issue:

```bash
gh issue create \
  --repo "${UPSTREAM_OWNER_REPO}" \
  --title "${TITLE_PREFIXED_BY_TEMPLATE}" \
  --body "${FILLED_BODY}" \
  --label "${MATCHED_TEMPLATE_LABEL_IF_ANY}"
```

Capture the returned issue URL. The voice-tone gate per ADR-028 may delegate-and-retry; treat this as expected (see "Voice-tone gate interaction" above). Proceed to Step 7 once the issue is created.

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
   - **Disclosure path**: <public issue | security advisory | drafted-and-saved (mailbox / out-of-band)>
   - **Cross-reference confirmed**: <yes/no — true once the upstream issue body contains the local ticket reference>
   ```

### 8. Commit per ADR-014

Follow the ADR-014 ordering:

1. `git add docs/problems/<NNN>-<title>.<status>.md` (and any `## Drafted Upstream Report` appendage if security-path halt fired).
2. Score commit/push/release risk via `wr-risk-scorer:pipeline` subagent (or fall back to `/wr-risk-scorer:assess-release` skill per ADR-015).
3. `git commit -m "docs(problems): P<NNN> reported upstream — <one-line summary>"`.

If the cumulative pipeline risk lands above appetite and `AskUserQuestion` is unavailable, apply the [ADR-013 Rule 6](../../../docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) non-interactive fail-safe: skip the commit and report the uncommitted state. Do NOT auto-commit above appetite without the user's call.

## AFK behaviour summary

Three distinct AFK branches per the architect review of ADR-024 + ADR-013 Rule 6:

| Branch | AFK behaviour | Authority |
|---|---|---|
| Public-issue path (Step 5) | Proceeds. Voice-tone gate per ADR-028 may delegate-and-retry; that is the expected extra turn. | ADR-028 line 126 |
| Security path with declared channel (Step 6, GitHub Advisories) | Proceeds via `gh api .../security-advisories`. | ADR-024 Decision Outcome step 6 |
| Security path with `security@` / other / missing-SECURITY.md (Step 6) | Save drafted report to local ticket's `## Drafted Upstream Report` section. **Halt the orchestrator** — loop-stopping event. AFK orchestrators must never auto-report a security-classified ticket. | ADR-024 Consequences lines 116, 123 |
| Above-appetite commit (Step 8) | Skip the commit, report uncommitted state. | ADR-013 Rule 6 |

## References

- [ADR-024](../../../docs/decisions/024-cross-project-problem-reporting-contract.proposed.md) — primary contract this skill implements.
- [ADR-027](../../../docs/decisions/027-governance-skill-auto-delegation.proposed.md) — Step-0 deferral rationale (held for reassessment).
- [ADR-028](../../../docs/decisions/028-voice-tone-gate-external-comms.proposed.md) — voice-tone gate on `gh issue create` and `gh api .../security-advisories`.
- [ADR-013](../../../docs/decisions/013-structured-user-interaction-for-governance-decisions.proposed.md) — interaction policy; Rule 1 governs Step 6 missing-SECURITY.md `AskUserQuestion`; Rule 6 governs the commit-gate AFK branch.
- [ADR-014](../../../docs/decisions/014-governance-skills-commit-their-own-work.proposed.md) — work → score → commit ordering.
- [ADR-015](../../../docs/decisions/015-on-demand-assessment-skills.proposed.md) — fallback path for `wr-risk-scorer:assess-release`.
- [P055](../../../docs/problems/055-no-standard-problem-reporting-channel.open.md) — upstream problem ticket (Part B).
- `packages/itil/skills/manage-problem/SKILL.md` — names the optional `## Reported Upstream` section as an allowed appendage to a problem ticket.

$ARGUMENTS
