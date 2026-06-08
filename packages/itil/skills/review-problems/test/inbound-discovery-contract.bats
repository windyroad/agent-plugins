#!/usr/bin/env bats
# Contract assertions for /wr-itil:review-problems Step 4.5
# inbound-discovery + assessment-pipeline (RFC-004 Slice C + Slice E).
#
# Structural assertions — Permitted Exception to the source-grep ban
# per ADR-005 / P011 / ADR-037 / ADR-052 § Surface 2. SKILL.md prose
# governs LLM-driven runtime behaviour; behavioural-replay testing
# requires a synthetic agent harness (P012 master ticket; P176 follow-up
# for the SKILL.md surface). Until that harness lands, contract bats
# assert the load-bearing prompt elements are present so future edits
# don't silently strip them.
#
# @problem P079
# @rfc RFC-004
# @adr ADR-062 (inbound discovery + assessment pipeline)
# @adr ADR-028 (external-comms gate)
# @adr ADR-044 (decision-delegation contract — category 4 mechanical-stage carve-out)
# @adr ADR-052 (behavioural-tests default + Permitted Exception)
# @jtbd JTBD-301 (acknowledgement contract — non-negotiable)
# @jtbd JTBD-001 (mechanical-stage carve-out — preserve without slowing down)
# @jtbd JTBD-006 (AFK silent path)
# @jtbd JTBD-101 (downstream non-obligation)
# @jtbd JTBD-201 (audit-log replay)

setup() {
  SKILL_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_FILE="${SKILL_DIR}/SKILL.md"
}

# ──────────────────────────────────────────────────────────────────────────────
# Step 4.5 presence + ADR-062 naming reconciliation
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5 inbound-discovery section exists in SKILL.md (RFC-004 Slice C)" {
  run grep -nE '^### 4\.5\. Inbound-discovery' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5 header preserves ADR-062 'Step 8.5' substring anchor verbatim" {
  # ADR-062 § Confirmation criterion 1 hard-keys on the "Step 8.5"
  # substring. SKILL.md numbering is "Step 4.5"; header cross-references
  # ADR-062's "Step 8.5" verbatim so the criterion remains string-anchorable.
  # Do NOT strip the "Step 8.5" substring on rename.
  run grep -nE 'Step 8\.5' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "SKILL.md preserves ADR-062 'Step 9e' substring anchor verbatim" {
  # ADR-062 § Confirmation criterion 1 final bullet hard-keys on the
  # "Step 9e" substring (the renderer is owned by Slice G; this skill
  # carries the cross-reference forward).
  run grep -nE 'Step 9e' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5 naming-reconciliation HTML comment marker exists" {
  # Architect issue 1+2: preserve both "Step 8.5" and "Step 9e" anchors
  # via a single HTML comment so a future rename doesn't silently strip
  # them. Comment names ADR-062 explicitly.
  run grep -nE 'ADR-062-step-naming-reconciliation' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Step 4.5 sub-step structure (4.5a through 4.5g)
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5a — read channel config (docs/problems/.upstream-channels.json)" {
  run grep -nE '4\.5a\..*[Cc]hannel config' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE '\.upstream-channels\.json' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5b — cache TTL check (docs/problems/.upstream-cache.json)" {
  run grep -nE '4\.5b\..*[Cc]ache TTL' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE '\.upstream-cache\.json' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5c — polls all three GitHub channels (issues / discussions / security-advisories)" {
  run grep -nE 'github-issues' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'github-discussions' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'github-security-advisories' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5d — P070 semantic-comparator with cross-reference comment on hit (JTBD-301)" {
  # Architect issue 5: JTBD-301 acknowledgement contract requires a
  # gated cross-reference comment on matched-local-ticket hits; silent-skip
  # would break the contract.
  run grep -nE '4\.5d.*[Mm]atch.*local' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'cross-reference' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5e — six-step assessment pipeline" {
  run grep -nE '4\.5e\..*[Ss]ix-step assessment pipeline' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5f — audit-log append to docs/audits/inbound-discovery-log.md" {
  run grep -nE '4\.5f\..*[Aa]udit-log' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'inbound-discovery-log\.md' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5g — render-time integration seam (consumed by Slice G renderer)" {
  run grep -nE '4\.5g\..*[Rr]ender' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Slice G: Step 5 README template carries the ## Inbound Upstream Reports section
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 5 README template carries the ## Inbound Upstream Reports section header (Slice G)" {
  run grep -nE '^## Inbound Upstream Reports$' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Slice G renderer documents the lazy-empty discipline (advisory row when no pass run)" {
  run grep -inE 'lazy-empty|No inbound discovery pass has run' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Slice G renderer documents the classification + matched-local-ticket columns" {
  run grep -inE 'Classification.*Matched local ticket|matched.local.ticket.*column' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Six pipeline outcomes (4.5e steps 1-6)
# ──────────────────────────────────────────────────────────────────────────────

@test "Pipeline step 1 — version-aware classification (P129 Phase 1 already-fixed-in-newer; Phase 2 recurrence deferred)" {
  # Phase 1 landed: SKILL.md Step 1 now carries the version-aware classifier
  # for the already-fixed-in-newer branch. Phase 2 (recurrence-class lifecycle)
  # remains deferred and is captured via the cache_audit_note Phase 2 token.
  run grep -inE 'version-aware classification.*P129.*Phase 1|P129.*Phase 1.*already-fixed-in-newer' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 1 — already-fixed-in-newer classification token present (P129 Phase 1)" {
  run grep -nE 'already-fixed-in-newer' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 1 — Phase 2 recurrence deferred with cache_audit_note phase2-recurrence-deferred token" {
  # Phase 2 deferral is recorded as a strictly additive cache_audit_note so
  # Phase 2 can backfill the recurrence-link when it lands; the matched
  # closed-ticket ID is named on the note so Phase 2 has a backfill anchor.
  run grep -nE 'phase2-recurrence-deferred-bug-shape-match' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 1 — Versions section parse per ADR-033 amendment / P128 schema" {
  # The classifier inputs depend on the inbound report carrying a parsable
  # `## Versions` section per P128's schema (`- Local plugin: @windyroad/<pkg>@<version>`).
  # If P128's schema regresses, this anchor surfaces the dependency.
  run grep -inE 'Versions section.*P128|## Versions.*P128|Local plugin.*@windyroad' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 1 — missing-version fail-soft fallback (phase1-version-missing)" {
  # When the reporter's `## Versions` section is absent or `Local plugin` is
  # unparseable, Step 1 logs `cache_audit_note: phase1-version-missing` and
  # proceeds to step 2 (treats as still-active). Required by the fail-soft
  # contract at 4.5 head; protects JTBD-301 acknowledgement.
  run grep -nE 'phase1-version-missing' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 1 — fix-version-extraction-failed fail-soft fallback" {
  # When fix-version extraction from the matched closed ticket's
  # `## Fix Released` section fails (best-effort heuristic miss), Step 1
  # logs `cache_audit_note: phase1-fix-version-extraction-failed-P<NNN>`
  # and proceeds to step 2. Maintainer re-discovers the duplication via
  # the next /wr-itil:review-problems re-rank; no silent loss.
  run grep -nE 'phase1-fix-version-extraction-failed' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 4b — upgrade-pushback branch (P129 Phase 1 fix-released sub-shape)" {
  # New sub-branch wired by Step 1's already-fixed-in-newer outcome.
  # Posts a gated upgrade-pushback comment under the fix-released verdict
  # row of the 4.5e-comment-shape contract. Architect verdict 2026-06-09
  # confirmed this as a sub-shape (not a 6th verdict-shape row) to
  # preserve the JTBD-301 four-verdict contract.
  run grep -inE '4b\..*Upgrade-pushback|Upgrade-pushback branch.*P129' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 4b — no local ticket created on already-fixed-in-newer (Phase 1 contract)" {
  # JTBD verdict 2026-06-09: the absence-of-ticket is correct because no
  # new investigation is needed; the "file a new report" escape hatch
  # preserves the plugin-user persona's agency.
  run grep -inE 'Do NOT open a local ticket|absence-of-ticket is correct' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 4b — anti-leakage (P229) preserved on upgrade-pushback body" {
  # Comment bodies MUST NOT carry framework-internal vocab — Step IDs,
  # branch names, classification tokens, or path syntax. The only
  # structured tokens permitted are the plain-language upgrade target
  # `@windyroad/<pkg>@<fix-version>` + the reporter-readable `P<NNN>` anchor.
  run grep -inE 'Anti-leakage \(P229\).*4b|MUST NOT contain framework-internal vocab' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 4b — gate-denial sub-branch records gate-denied-already-fixed-in-newer-upgrade-pushback" {
  # Symmetry with the existing gate-denial sub-branches on Steps 4 / 5 / 6.
  # The upgrade-pushback comment retries on next discovery pass —
  # JTBD-301 acknowledgement is preserved across gate denials.
  run grep -nE 'gate-denied-already-fixed-in-newer-upgrade-pushback' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 2 — JTBD-alignment classifier (wr-jtbd:agent)" {
  run grep -nE 'JTBD-alignment classifier' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'wr-jtbd:agent' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 3 — dual-axis risk classifier (wr-risk-scorer:inbound-report from Slice B)" {
  run grep -inE 'dual-axis risk classifier' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'wr-risk-scorer:inbound-report' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 4 — above-threshold-pushback branch (gated declining comment)" {
  run grep -nE 'above-threshold-pushback' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 5 — clear-malicious branch with verdict comment BEFORE close (JTBD-301)" {
  # JTBD-301 acknowledgement contract: silent close is forbidden per ADR-062.
  run grep -nE 'clear-malicious' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -inE 'verdict comment.*BEFORE close|silent close.*forbidden' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Pipeline step 6 — safe-and-valid branch invokes capture-problem --no-prompt" {
  # Architect issue 3: documenting the default-technical choice explicitly
  # so the maintainer-re-classify safety net is visible.
  run grep -nE 'safe-and-valid' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'capture-problem.*--no-prompt' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Mechanical-stage carve-out (P132 / ADR-044 category 4)
# Load-bearing test protecting JTBD-001 + JTBD-006 against inverse-P078 drift
# per the architect's named Slice E acceptance criterion.
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5 cites the mechanical-stage carve-out (P132 / ADR-044)" {
  run grep -inE 'mechanical-stage carve-out|P132' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5 explicitly forbids AskUserQuestion at the branch decision (anti-inverse-P078 drift)" {
  # The load-bearing structural assertion per architect Slice E acceptance.
  # If a future edit adds AskUserQuestion to the pipeline branch decision,
  # this assertion fails and surfaces the P132 carve-out regression.
  run grep -nE 'does NOT use .AskUserQuestion. at the branch decision' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5 cites ADR-044 category 4 (silent framework action)" {
  run grep -nE 'ADR-044 category 4' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# JTBD-301 acknowledgement contract (non-negotiable per ADR-062)
# ──────────────────────────────────────────────────────────────────────────────

@test "JTBD-301 acknowledgement contract cited on the matched-local-ticket path (architect issue 5)" {
  run grep -nE 'JTBD-301' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'JTBD-301 acknowledgement' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Per-branch gate-denial sub-branches preserve report on external-comms gate FAIL" {
  # Silent-skip on gate-denial would break JTBD-301; the report is preserved
  # via cache_audit_note for the next discovery pass.
  run grep -nE '[Gg]ate-denial sub-branch' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'cache_audit_note' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Fail-soft contract + downstream non-obligation
# ──────────────────────────────────────────────────────────────────────────────

@test "Step 4.5 declares the fail-soft contract" {
  run grep -inE 'fail-soft contract' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Missing channel config skips Step 4.5 (downstream-adopter non-obligation per JTBD-101)" {
  run grep -nE 'channel config absent|missing or malformed' "$SKILL_FILE"
  [ "$status" -eq 0 ]
  run grep -nE 'JTBD-101' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "AFK-loop silent behaviour documented" {
  run grep -nE 'AFK-loop|AFK orchestrator.*silently' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Slice F: --force-upstream-recheck flag parsing + TTL-expiry auto-recheck
# (Slice F replaced the Slice C SLICE-C-FLAG-STUB string-match with proper
# tokenized flag parsing + explicit TTL-expiry branch)
# ──────────────────────────────────────────────────────────────────────────────

@test "SLICE-C-FLAG-STUB marker has been removed (Slice F replaced the stub)" {
  # Slice F (RFC-004) replaces the Slice C string-match with proper
  # tokenized flag parsing. The stub marker must be gone — its presence
  # would indicate Slice F regression.
  run grep -nE 'SLICE-C-FLAG-STUB' "$SKILL_FILE"
  [ "$status" -ne 0 ]
}

@test "--force-upstream-recheck flag documented (Slice F)" {
  run grep -nE -- '--force-upstream-recheck' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5a parses \$ARGUMENTS as tokenized flag list (Slice F)" {
  # Slice F replaces the Slice C string-match with proper tokenized parsing.
  run grep -inE 'tokenize|whitespace-separated token|parse.*ARGUMENTS' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5b — TTL-expiry auto-recheck branch fires when cache_age > ttl_seconds (Slice F)" {
  # Self-healing: maintainer who runs review-problems once a week still
  # gets a fresh poll after the 24-hour TTL expires, without needing the
  # explicit flag.
  run grep -inE 'TTL-expiry auto-recheck|cache.age.*exceeds.*ttl_seconds|cache_age.*> *ttl_seconds' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5b — explicit branch for cache-fresh (within-TTL silent-pass)" {
  # Within-TTL path is silent per ADR-013 Rule 5 below-appetite silent-pass.
  run grep -inE 'cache-fresh branch|within-TTL|silent within-TTL' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "Step 4.5a — unknown inbound-flags surface advisory rather than silently ignoring" {
  # Defensive contract: unknown --force-upstream / --inbound- flags get
  # named in an advisory so typos are visible (e.g. --force-upsteam-recheck).
  run grep -inE 'Unknown.*flag.*halt|unrecognised flag' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

# ──────────────────────────────────────────────────────────────────────────────
# Cross-reference integrity (ADRs + sibling JTBDs)
# ──────────────────────────────────────────────────────────────────────────────

@test "ADR-062 cross-reference present in Step 4.5 header" {
  run grep -nE 'ADR-062' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}

@test "ADR-028 (external-comms gate) cited for gated-comment paths" {
  run grep -nE 'ADR-028' "$SKILL_FILE"
  [ "$status" -eq 0 ]
}
