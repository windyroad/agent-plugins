---
name: wr-risk-scorer:update-policy
description: Create or update the project's RISK-POLICY.md per ISO 31000 and the risk-scorer agent. Examines the project to derive business-specific impact levels.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent
---

# Risk Policy Generator

Create or update `RISK-POLICY.md` per ISO 31000, tailored to this project's business context. The risk-scorer agent reads this file to score pipeline actions (commit, push, release).

## What belongs in RISK-POLICY.md (single source of truth)

- **Risk appetite** -- the residual risk threshold for pipeline actions
- **Impact levels** -- business consequences of failure, specific to this product and its users
- **Likelihood levels** -- descriptions of how likely a risk is to materialise
- **Risk matrix** -- Impact × Likelihood score table and label bands (Low/Medium/High/Critical)
- **Last reviewed date** -- when the policy was last reviewed or updated

The risk-scorer agent, problem management skill, and any other process that needs to assess risk severity reads these definitions from RISK-POLICY.md.

## What does NOT belong in RISK-POLICY.md (lives in the risk-scorer agent)

- Assessment rules, back-pressure, control discovery (scoring mechanics)

## Steps

### 1. Read the risk-scorer agent contract

Read `.claude/agents/risk-scorer-pipeline.md` to understand what the scorer expects from `RISK-POLICY.md`. Extract:

- What fields the agent reads from the policy (look for "Read `RISK-POLICY.md`" in "Your Role")
- The impact level labels used in the agent's risk matrix (look for the "Product Reference Table")
- The label bands and their score ranges (look for "Label Bands")
- The gate threshold the agent uses (look for "risk appetite" references)

Use this contract to guide drafting. Do not hardcode assumptions about the number of levels, their labels, or the appetite threshold -- derive them from the agent definition.

### 2. Discover project context

Examine the project to understand what it does and who uses it. Adapt to the project type -- do not assume any particular framework or language.

**Find the project manifest** (first match wins):
- `package.json` (Node/JS/TS)
- `pyproject.toml` or `setup.py` (Python)
- `go.mod` (Go)
- `Cargo.toml` (Rust)
- `Gemfile` (Ruby)
- `pom.xml` or `build.gradle` (Java/Kotlin)

**Find the project description**:
- `README.md` or `README.*`
- The `description` field in the manifest
- A homepage or docs index

**Discover user-facing features** by scanning for:
- Route/endpoint definitions (scan for directories named `routes/`, `pages/`, `api/`, `handlers/`, `controllers/`, or grep for route decorators/annotations)
- UI entry points (`.html`, `.svelte`, `.tsx`, `.jsx`, `.vue`, `.astro` files)
- CLI commands or public API surface

**Discover infrastructure**:
- Deployment config (`Dockerfile`, `docker-compose.*`, `fly.toml`, `app.yaml`, `serverless.yml`, `*.tf`, cloud config)
- CI/CD workflows (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`)
- Database or storage config

Build a mental model of: what does this product do, who are its users, and what would hurt them?

**Check repository visibility**:
- Run `gh repo view --json isPrivate` or check for other visibility indicators
- If the repository is **public**, confidential business metrics (revenue, user counts, pricing, traffic volumes) must not appear in any committed file. Note this for step 5 — the policy must include a "Confidential Information" section and information disclosure must be covered in the impact levels.

### 3. Check for existing policy

If `RISK-POLICY.md` already exists, read it. Identify:

- Whether impact levels still reflect the current product (features may have been added/removed)
- Whether the risk appetite is still appropriate
- Whether the last reviewed date is stale (> 2 weeks)

### 4. Check for recent incidents

If `docs/problems/` exists, scan for open or known-error problems (files ending in `.open.md` or `.known-error.md`). For each:

- Read the problem to understand its business impact
- Consider whether the impact levels adequately cover this kind of failure
- Flag any gap (e.g., a problem caused data corruption but the impact levels don't mention data integrity)

If recent incidents suggest the impact levels need updating, note this for step 6 (user confirmation). ISO 31000 requires risk criteria to be reviewed after incidents, not just on a schedule.

### 5. Draft impact levels, likelihood levels, and risk matrix

**Impact levels** must describe **business consequences** (ISO 31000 context establishment), not categories of files changed. Each level answers: "What happens to users/business if this goes wrong?"

Use 5 levels (Negligible to Severe). Tailor descriptions to this specific product:

- **Negligible**: No user impact at all
- **Minor**: No user impact; only developer/build affected
- **Moderate**: Deployment/publishing disrupted; users can't get updates. For public repositories: confidential business metrics (revenue, user counts, pricing, traffic volumes) committed to the repository — an information disclosure requiring immediate remediation but not affecting service availability.
- **Significant**: User-facing features degraded or inaccessible
- **Severe**: Data integrity, trust, or availability destroyed

Reference specific product features, user workflows, and infrastructure by name. Generic descriptions like "application logic affected" are wrong -- say what breaks and for whom.

**Likelihood levels** describe how likely a risk is to materialise. Use 5 levels (Rare to Almost certain). These are universal — not product-specific:

- **Rare (1)**: Requires specific, unusual conditions. Extensive test coverage or architectural safeguards make occurrence very unlikely.
- **Unlikely (2)**: Could happen but controls (tests, CI gates, review hooks) significantly reduce probability.
- **Possible (3)**: Moderate complexity or limited test coverage. Could happen under normal conditions.
- **Likely (4)**: High complexity, many code paths, or limited controls. Expected to occur without intervention.
- **Almost certain (5)**: Known gap, no controls in place, or previously observed failure mode.

**Risk matrix**: Include the Impact × Likelihood multiplication table (5×5 = scores 1-25) and the label bands per ADR-086 (supersedes ADR-065):

| Score Range | Label |
|-------------|-------|
| 1-2 | Very Low |
| 3-5 | Low |
| 6-9 | Medium |
| 10-16 | High |
| 17-25 | Very High |

The bands match the risk-scorer agent's authoritative source at `packages/risk-scorer/agents/pipeline.md` and the create-risk SKILL — single source of truth across the plugin. The Low ceiling at 5 admits residual=5 (Impact=5×Likelihood=1, the floor for severe-but-rare risks) within Low so an appetite of 5 is reachable for that class.

The risk matrix is used by both the **risk-scorer agent** (pipeline risk assessment) and the **problem management process** (problem severity via `/problem` skill).

### 6. Confirm with the user

You MUST use the AskUserQuestion tool (not plain text output) to collect user confirmation. Do not proceed to step 6a or step 7 until you have received answers via AskUserQuestion.

Call AskUserQuestion with a single message that presents:

1. The drafted impact levels (as a table) and asks whether they accurately reflect what matters most
2. The risk appetite threshold -- present the label bands from the agent contract (step 1) and recommend a threshold based on project maturity. Ask the user to confirm or adjust. A prototype with no real users may tolerate higher risk than a production system with paying users or compliance requirements
3. Whether any business context is missing (e.g., compliance requirements, SLAs, user base size)

### 6a. Tight-appetite warning when threshold < 5 (ADR-086)

If the user picked an appetite threshold below 5 in step 6, fire a second `AskUserQuestion` confirm-with-warning before proceeding. The Low band's ceiling under ADR-086 is 5; an appetite below 5 means a class of risks (those with Impact=5/Severe and no impact-reducing control available) can never be within appetite — the policy is mathematically infeasible for that class. The user can still set the tighter threshold (some domains genuinely want to prohibit severe-impact activities), but the consequence must be a conscious choice, not a quiet trap.

**Build the warning's example list** (cite concrete activity-classes the user is about to prohibit):

1. Glob `docs/risks/R*.active.md`. For each file, read the `## Inherent Risk` and `## Residual Risk` sections and extract the numeric `Impact` value. Collect entries whose Inherent Impact = 5 OR Residual Impact = 5.
2. If 1+ entries match: pick up to three. Format each as a kebab-case activity-class derived from the entry's filename slug (the part after `R<NNN>-` and before `.active.md`), followed by its R-ID as the audit pointer. Brief-before-ID per P350 — activity-class FIRST, R-ID in parentheses, never the R-ID alone as the carrier of meaning.
3. If 0 entries match (empty register OR no Impact=5 entries): fall back to citing the policy's own Impact=5 row from the Impact Levels table just drafted — the user has it in working memory and it's the right surface for "what kind of thing would be prohibited."

**The warning question**:

> *"You've chosen appetite N. Under the rebalanced label bands (ADR-086) the Low ceiling is 5, so an appetite of N means residual-5 risks like `<activity-class>` ({R-ID}) and `<activity-class>` ({R-ID}) can never be within appetite under this policy — those activities become effectively prohibited (no amount of control work brings their residual below 5 because Impact=5 is fixed). Continue with appetite N, or revise?"*

(Substitute the register-derived example list or the policy-row fallback as appropriate.)

**Options**:
- **Confirm: appetite N, with severe-impact activities prohibited** — the user explicitly accepts the trade-off. Proceed to step 7.
- **Revise the appetite** — return to step 6 with the appetite question only.

**Non-interactive (AFK) fallback** per ADR-013 Rule 6: if `AskUserQuestion` is unavailable, do NOT proceed — the warning is load-bearing (prohibits an entire risk class) and silently consuming it would normalise the prohibition. Halt with a clear "appetite < 5 selected interactively required" message for the orchestrator to drain later.

### 7. Validate draft with risk-scorer agent

Before writing the policy file, invoke the risk-scorer agent to validate the draft. This is the gate -- the enforce hook will only allow writes to RISK-POLICY.md after the scorer returns PASS.

Run the risk-scorer agent (subagent_type: "risk-scorer") with this prompt:

> Review this draft risk policy for ISO 31000 compliance. Validate it.
>
> [paste the full draft policy content here]

The risk-scorer will check:
- Impact levels describe business consequences (not file categories)
- Impact labels match the risk matrix (Negligible, Minor, Moderate, Significant, Severe)
- Risk appetite defines a numeric threshold
- Business context is present
- Last reviewed date is present

It ends its output with `RISK_VERDICT: PASS` or `RISK_VERDICT: FAIL`. The PostToolUse hook reads this from the agent output and sets the edit marker on PASS.

- **If PASS**: proceed to step 8 (write)
- **If FAIL**: fix the issues the scorer identified, then re-run this step

### 8. Write RISK-POLICY.md

Write the policy using the structure derived from the agent contract (step 1). The output must include:

- The ISO 31000 header and "Last reviewed" date (today's date)
- Business context section
- **Confidential Information section** (for public repositories): stating that business metrics must not appear in committed files, with examples of what is confidential and guidance to use generic descriptions instead
- The risk appetite threshold confirmed by the user in step 6
- The impact levels with project-specific descriptions from step 5
- The likelihood levels (universal 1-5 scale)
- The risk matrix (Impact × Likelihood table) and label bands
- **An `## Authorized Bypass Scenarios` section** (P377/RFC-029) stating exactly which gate bypasses are sanctioned — and that nothing else is. The canonical text to write:
  - **Risk-reducing / risk-neutral changes** proceed via the risk-reducing path (a change that lowers or holds residual risk is not blocked by the gate). The scorer emits `RISK_BYPASS: reducing`; the gate honours a drift-revalidated, TTL-bounded `reducing-*` marker.
  - **Incident response** is NOT a separate carve-out — an active incident is a risk already being realised (Likelihood 5), so an incident-response change is scored against that live baseline and proceeds only if net-risk-reducing (per ADR-042 Rule 1b). The `incident-release` marker exists only to let a net-reducing restore-service release proceed despite red/unreadable CI during a live outage.
  - **Above appetite is never bypassable by a prompt or an env var.** There is no "commit/release anyway" question and no `BYPASS_RISK_GATE` / `ci-bypass` override (removed P377/RFC-029) — above appetite, the action auto-remediates to within appetite or halts (ADR-042 Rule 1).
  - **Default-permitted-when-silent**: a project whose RISK-POLICY.md predates this section still permits the risk-reducing and incident paths above; this section makes the policy the explicit single source of truth and SHOULD be added at the next review.
- A note that both the risk-scorer agent and problem management process reference this policy

## Updating an existing policy

When updating rather than creating:

- Preserve the existing risk appetite unless the user wants to change it
- Compare current impact levels against the current state of the project
- Flag levels that reference features or infrastructure that no longer exist
- Flag new features or infrastructure not covered by existing levels
- Update the "Last reviewed" date to today
- Show the user a diff of what changed

$ARGUMENTS
