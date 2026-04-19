---
"@windyroad/jtbd": patch
---

Strengthen the `wr-jtbd:agent` output contract to forbid bare verdicts without remediation guidance (closes P037). The agent now treats the inline response as the primary authoritative channel and the `/tmp/jtbd-verdict` file as a subordinate internal signal. Every response must begin with a structured `JTBD Review: PASS | ISSUES FOUND | JOB UPDATE NEEDED | PERSONA UPDATE NEEDED` line and, on non-PASS verdicts, include file + line + issue + affected job + suggested fix. "FAIL" alone or a bare file list is now explicitly forbidden. Includes a 7-test doc-lint bats regression file.
