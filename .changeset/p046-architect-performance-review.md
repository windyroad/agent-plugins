---
"@windyroad/architect": minor
---

Add runtime-path performance review to `wr-architect:agent` per ADR-023 (closes P046). When a proposed change touches HTTP cache directives, rate limits, throttles, response size, or per-request handler behaviour, the architect now MUST report a per-request cost delta (concrete units: ms, bytes), a request-frequency estimate (with cited source — ADR, JTBD, telemetry, or explicit "worst-case assumption"), their product as aggregate load delta, and a verdict against any in-scope `performance-budget-*` ADR. Qualitative phrases like "load is negligible" or "microseconds only" are now forbidden without concrete numeric backing. Includes a 9-test bats regression file enforcing the prompt wording. Rationale: the same architect agent reviews many downstream projects; a systemic blind spot for per-request cost trade-offs (addressr 2026-04-18 incident) affects every consumer.
