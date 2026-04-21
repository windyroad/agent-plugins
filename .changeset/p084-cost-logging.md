---
"@windyroad/itil": minor
---

Extend `/wr-itil:work-problems` Step 5 to extract per-iteration cost + token metadata from each `claude -p --output-format json` response. Surface it in Step 6's per-iteration progress line and the ALL_DONE Output Format's new "Session Cost" section.

**Why:** the subprocess-dispatch swap shipped in 0.13.0 landed real per-iteration cost inside the JSON response alongside `.result`, but the orchestrator was throwing it away. Without surfacing it, the user has no feedback loop for calibrating AFK loop sizing decisions (e.g. the 2026-04-21 "max out the token usage, they are wasted unused" direction needs actuals to calibrate against). Cost metadata is already emitted — this change just wires it into the user-visible output.

**Extracted fields (explicit list; PII guard):** `.total_cost_usd`, `.duration_ms`, `.usage.input_tokens`, `.usage.output_tokens`, `.usage.cache_creation_input_tokens`, `.usage.cache_read_input_tokens`. SKILL.md names the extraction scope explicitly so future contributors don't unconsciously broaden it to include `session_id`, `model`, `stop_reason`, `permission_denials`, `uuid`, or other subprocess-envelope fields.

**Step 6 per-iteration format:** `[Iteration N] Worked P<NNN> — <action>. <K> problems remain. ($<cost>, <duration_s>s, <total_tokens_K>K tokens)`.

**ALL_DONE Session Cost section:** aggregate totals (cost, iterations, mean cost per iteration, input/output/cache-creation/cache-read tokens, duration). Cache-read column surfaces the warm-cache-reuse signal observed across subsequent subprocess invocations in the same Bash session. Renders identically in interactive and AFK modes; no decision branch (output-side only, per ADR-013 Rule 6).

**Source citation (per ADR-026):** Session Cost numbers are extracted measured-actuals from each iteration's `claude -p` JSON output — not estimates. Cited in the section header so downstream audits can trust the numbers.

Architect + JTBD reviews PASS (both 2026-04-21). Bats doc-lint: 9 new assertions on the extraction language + Session Cost section shape; 54/54 work-problems suite green.
