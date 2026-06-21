#!/usr/bin/env bats

# tdd-review: structural-permitted (justification: P012 skill testing
#   harness scope is open; no behavioural alternative for SKILL.md prose-
#   template structural assertions today. ADR-052 Migration clause permits
#   structural retrofit-via-justification when the linked harness-gap ticket
#   has not yet shipped the primitives. The paired promptfoo eval at
#   packages/itil/skills/update-upstream/eval/promptfooconfig.yaml carries
#   the behavioural Tier-A/B coverage per ADR-075 Amendment 2026-06-02.
#   Provenance: P080 (original bidirectional contract) + P363 / ADR-024
#   amendment 2026-06-22 (inbound-origin verdict dispatch leg — tests 21-30,
#   behaviourally paired by the inbound eval cases in promptfooconfig.yaml).
#   The lockstep transition-problem/manage-problem grep check is an inherent
#   copy-not-move drift detector (ADR-010/P362) with no behavioural form.)
#
# Doc-lint structural test (Permitted Exception per ADR-005 — structural
# SKILL.md content checks, not behavioural). Mirrors the doc-lint pattern
# established in ADR-011 and ADR-027 Confirmation tests and used by the
# sibling report-upstream contract test.
#
# Asserts the update-upstream skill's SKILL.md encodes the contract
# documented in ADR-024 amendment (P080):
# - sibling-skill split per ADR-010 amended
# - reads ## Reported Upstream from the local ticket
# - three transition templates (Open→KE, KE→Verifying, Verifying→Closed)
# - composes through external-comms + voice-tone gates (AND, not OR)
# - within appetite → gh issue comment; on Verifying→Closed also gh issue close
# - above appetite → silent risk-reduce + re-score; if still above, queue
#   to ## Queued Upstream Update + outstanding_questions (NOT halt the loop)
# - back-writes to ## Upstream Lifecycle Updates (append-only log)
# - ADR-014 single-commit grain when fired from transition-problem Step 7

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/packages/itil/skills/update-upstream/SKILL.md"
  EVAL_CONFIG="$REPO_ROOT/packages/itil/skills/update-upstream/eval/promptfooconfig.yaml"
  TRANSITION_MD="$REPO_ROOT/packages/itil/skills/transition-problem/SKILL.md"
  MANAGE_MD="$REPO_ROOT/packages/itil/skills/manage-problem/SKILL.md"
}

@test "update-upstream: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "update-upstream: SKILL.md declares sibling-skill split per ADR-010 amended (P080 user direction (a))" {
  # User direction (a) — new sibling skill, not a mode flag on report-upstream.
  run grep -F 'sibling' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'ADR-010' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md cross-references ADR-024 amendment (P080)" {
  run grep -F 'ADR-024' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'P080' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md reads ## Reported Upstream from the local ticket (P080 contract)" {
  # The skill reads the section that /wr-itil:report-upstream Step 7
  # writes (per ADR-024 Confirmation criterion 3a). Without this read, the
  # skill has no upstream URL to comment on.
  run grep -F '## Reported Upstream' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md documents three transition templates (Open→KE, KE→Verifying, Verifying→Closed)" {
  # Each transition has its own template — investigation findings vs release
  # info vs closure thanks. ADR-024 amendment authority pins all three.
  run grep -iE 'Open[[:space:]]*[—\-][[:space:]]*[>›]?[[:space:]]*Known Error|Open[[:space:]]*→[[:space:]]*Known Error' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'Known Error[[:space:]]*[—\-][[:space:]]*[>›]?[[:space:]]*Verification Pending|Known Error[[:space:]]*→[[:space:]]*Verification Pending' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'Verification Pending[[:space:]]*[—\-][[:space:]]*[>›]?[[:space:]]*Closed|Verification Pending[[:space:]]*→[[:space:]]*Closed' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md composes through external-comms gate (P080 user direction (b) + ADR-028)" {
  # User direction (b) — risk-gated. The gate is wr-risk-scorer:external-comms
  # per ADR-028's third-evaluator extension point (the same gate the post-
  # P270 amendment uses for the initial-filing path).
  run grep -F 'wr-risk-scorer:external-comms' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md composes through voice-tone gate (P080 user direction (b) + ADR-028)" {
  # User direction (b) — voice-tone gated. The gate is wr-voice-tone:agent
  # firing on gh issue comment / gh issue close per ADR-028.
  run grep -F 'ADR-028' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'voice-tone gate' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md gates compose AND (both must pass) not OR (P080 user direction (c))" {
  # User direction (c) — same external-comms gate composition pattern as
  # inbound (P079). That pattern is AND, not OR — one fail blocks the post.
  # The SKILL.md must frame composition explicitly so adopters do not read
  # it as independent gates.
  run grep -iE 'voice-tone fail.*queue|voice-tone.*FAIL.*queue|FAIL.*identically' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md within-appetite posts via gh issue comment" {
  # Within-appetite path posts via gh issue comment with the matched URL's
  # issue number — same gh CLI surface as report-upstream Step 5c.
  run grep -F 'gh issue comment' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md Verifying→Closed also runs gh issue close (symmetric audit trail)" {
  # JTBD-201 symmetric audit trail outcome — when the local ticket goes
  # .closed.md the upstream issue must also close. Without gh issue close
  # the upstream tracker accumulates stale-looking open issues.
  run grep -F 'gh issue close' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md above-appetite saves to ## Queued Upstream Update (not the report rename)" {
  # ADR-024 amendment (P080) — the lifecycle-update queue section is named
  # ## Queued Upstream Update, distinct from the initial-filing ## Queued
  # Upstream Report (renamed per the 2026-06-04 second-amendment leaf (c)).
  # Distinct sections so a single local ticket can carry both without collision.
  run grep -F '## Queued Upstream Update' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md above-appetite queues outstanding_questions (does NOT halt the orchestrator per P352)" {
  # P352 queue-and-continue — same shape as the post-P270 initial-filing
  # path. The above-appetite branch must NOT halt the loop; the queued
  # entry surfaces at the existing batched-AskUserQuestion end-of-loop gate.
  run grep -iE 'outstanding_questions|queue-and-continue|P352' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md silent risk-reduce + re-score is mechanical per ADR-044 (no per-iter AskUserQuestion)" {
  # ADR-044 framework-resolution boundary — the risk-reduce + re-score is
  # silent (mechanical); per-iter AskUserQuestion for risk-reduce vocabulary
  # is the lazy-deferral anti-pattern P132 closes.
  run grep -iE 'silent risk-reduce|mechanical.*ADR-044|ADR-044.*mechanical' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md back-writes to ## Upstream Lifecycle Updates (append-only log)" {
  # The audit-trail back-write mirrors the ## Reported Upstream back-write
  # in report-upstream Step 7 (per ADR-024 Confirmation criterion 3a),
  # extended to log every transition.
  run grep -F '## Upstream Lifecycle Updates' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'append-only|never overwritten|append.*entry' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md AFK behaviour summary table exists (architect review)" {
  # Mirrors report-upstream's AFK behaviour summary table — the canonical
  # place where adopters look up the AFK routing for each branch.
  run grep -F 'AFK behaviour summary' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md cites ADR-014 single-commit grain (transition + back-write + upstream post)" {
  # When fired from transition-problem Step 7, the upstream comment +
  # back-write + ticket rename + README refresh ride the SAME commit per
  # ADR-014 single-commit grain.
  run grep -F 'ADR-014' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'single-commit|same single commit|same commit' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md no-op exit on missing ## Reported Upstream (cheap unconditional firing)" {
  # The trigger fires on every transition unconditionally; the no-op exit
  # absorbs the misses (most tickets have no ## Reported Upstream). Without
  # the no-op exit, every transition pays a decision cost.
  run grep -iE 'no-op exit|nothing to update|exit cleanly' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md no-invention rule on template-filling (reporter-trust guard)" {
  # If a cited local-ticket section is absent, write the explicit "absent"
  # phrasing rather than invent content. The risk + voice-tone gates cannot
  # guard against invented technical claims; the no-invention rule does.
  run grep -iE 'no.invention|do not invent|never invent|rather than invent|absent.*phrasing|"absent"' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md annotates JTBD-301 + JTBD-001 (jtbd-lead review)" {
  # JTBD-301 plugin-user reporter feedback loop AND JTBD-001 solo-developer
  # without-slowing-down are the load-bearing JTBDs. The jtbd-lead review
  # required both annotations.
  run grep -F 'JTBD-301' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'JTBD-001' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md documents transition-problem Step 7 trigger wire-in (P080 invocation contract)" {
  # The advisory subsection in transition-problem Step 7 fires this skill
  # when ## Reported Upstream is present. The SKILL.md must reference the
  # trigger surface so adopters understand the invocation contract.
  run grep -iE 'transition-problem.*Step 7|Step 7.*transition-problem|fired from.*transition' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# ─── Inbound-origin verdict dispatch leg (P363 / ADR-024 amendment 2026-06-22) ─

@test "update-upstream: SKILL.md documents the inbound-origin verdict dispatch leg (P363)" {
  # The skill reads the **Origin**: inbound-reported (#NN) field (ADR-076)
  # in addition to ## Reported Upstream, so inbound reporters get a verdict.
  run grep -iE 'Inbound-origin verdict dispatch' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'inbound-reported (#NN)' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md no-op exit requires BOTH surfaces absent (section AND inbound Origin)" {
  # The dual-direction no-op exit fires only when NEITHER the outbound
  # ## Reported Upstream section NOR the inbound **Origin** field is present.
  run grep -iE 'no inbound Origin|NEITHER .*Reported Upstream.*Origin|both are absent' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md inbound leg resolves the originating issue on OUR OWN repo (not external upstream)" {
  # Inbound issues are filed AGAINST us — the comment posts on our own repo,
  # resolved via gh default / gh repo view, NOT an external upstream owner/repo.
  run grep -iE 'gh repo view|our own repo|own repo' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md inbound leg has an idempotency guard (gh issue view --json comments)" {
  # Before posting, scan existing comments for the verdict marker
  # (package@version + commit SHA) and skip if already posted.
  run grep -F 'gh issue view' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'idempoten' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md inbound templates carry the P229 anti-leakage rule (reporter-facing, no internal vocab)" {
  # Reporter-facing comment bodies on our own repo MUST NOT leak Step IDs,
  # branch names, classification tokens, or P/ADR/JTBD IDs as carriers of
  # meaning. The released @windyroad/<pkg>@<version> is the only permitted
  # structured token. Mirrors ADR-062 safe-and-valid acknowledgement shape.
  run grep -iE 'anti-leakage|reporter-surface prose|reporter-facing' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -F 'P229' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md inbound leg keeps the SAME dual gate composition (no weaker path)" {
  # The inbound comment routes through the SAME external-comms + voice-tone
  # dual gate as the outbound path — no weaker path for inbound.
  run grep -iE 'SAME .*external-comms .*voice-tone|same.*dual gate' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md inbound Verifying→Closed also closes the own-repo issue (addresses #97-unclosed witness)" {
  # P211 #97 was silent AND unclosed. The inbound leg runs gh issue close
  # on the own repo on the Verifying→Closed transition.
  run grep -iE 'posted-inbound-comment-and-closed|gh issue close .*OWN' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md both-direction tickets fire both legs independently" {
  # A ticket reported upstream AND reported against us inbound fires both
  # dispatches independently — one above-appetite leg queues only itself.
  run grep -iE 'Both-direction|both.*legs.*independent|fire .*independently' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "update-upstream: SKILL.md back-writes inbound entries direction-tagged so P249 poller is uncontaminated" {
  # Inbound entries log to ## Upstream Lifecycle Updates (NOT ## Reported
  # Upstream) so /wr-itil:check-upstream-responses (P249) is not contaminated.
  run grep -F 'P249' "$SKILL_MD"
  [ "$status" -eq 0 ]
  run grep -iE 'inbound.*disclosure path|posted-inbound-comment' "$SKILL_MD"
  [ "$status" -eq 0 ]
}

@test "transition-problem + manage-problem Step 7 greps match the inbound Origin alternation in LOCKSTEP (P363/P362)" {
  # Both lockstep pre-checks must match ^## Reported Upstream OR
  # ^\*\*Origin\*\*: inbound-reported \(# — drift re-opens the P363 gap on
  # whichever surface lacks the alternation (ADR-010 copy-not-move / P362).
  run grep -F 'inbound-reported \(#' "$TRANSITION_MD"
  [ "$status" -eq 0 ]
  run grep -F 'inbound-reported \(#' "$MANAGE_MD"
  [ "$status" -eq 0 ]
}

# ─── Paired promptfoo eval (ADR-075 Amendment 2026-06-02 + ADR-061 Rule 4) ────
#
# The paired promptfoo eval at packages/itil/skills/update-upstream/eval/
# discharges the R009 prose-floor for this SKILL surface atomically per
# ADR-061 Rule 4 evidence-floor — without the paired eval, ADR-042 Rule 2
# move-to-holding would apply per the P080 iter contract.

@test "update-upstream: paired promptfoo eval config exists (ADR-075 Amendment 2026-06-02)" {
  [ -f "$EVAL_CONFIG" ]
}

@test "update-upstream: paired eval uses exec:bash provider per ADR-075 §6 (no API key)" {
  # ADR-075 §6 — subscription auth via claude -p, no ANTHROPIC_API_KEY.
  # The provider must be exec:bash invoking ./run-skill-eval.sh.
  run grep -F "exec:bash ./run-skill-eval.sh" "$EVAL_CONFIG"
  [ "$status" -eq 0 ]
}

@test "update-upstream: paired eval ships Tier-B llm-rubric grader for negative clauses" {
  # Negative clauses (must NOT halt; must NOT invent) cannot be Tier-A
  # graded — a not-regex for "halt" false-fails the correct "does NOT halt".
  # The grader script + llm-rubric assertions discharge those clauses.
  GRADER="$REPO_ROOT/packages/itil/skills/update-upstream/eval/grade-llm-rubric.sh"
  [ -f "$GRADER" ]
  [ -x "$GRADER" ]
  run grep -F 'llm-rubric' "$EVAL_CONFIG"
  [ "$status" -eq 0 ]
}
