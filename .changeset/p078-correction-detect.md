---
"@windyroad/itil": patch
---

P078 — Hook now offers ticket capture on strong-signal correction.

A new `UserPromptSubmit` hook (`itil-correction-detect.sh`) detects strong-affect correction signals in the user's prompt — `FFS`, all-caps imperatives (`DO NOT`, `DON'T`, `STOP`), direct contradiction (`that's wrong`, `you're not listening`), exasperation markers (`!!!`), meta-correction (`you always`, `you never`, `you keep`) — and injects a `MANDATORY` reminder telling the assistant to OFFER `/wr-itil:capture-problem` (with `/wr-itil:manage-problem` as today's fallback) BEFORE addressing the operational request. Once-per-session full block + terse-reminder pattern (ADR-038).

Without this, strong-signal corrections decay with session context and the same class-of-behaviour pattern recurs next session, with the user having to manually request the ticket every time.

Pattern vocabulary lives in `packages/itil/hooks/lib/detectors.sh::CORRECTION_SIGNAL_PATTERNS`. Detection is intentionally aggressive (case-insensitive); false positives degrade gracefully (one extra advisory line — the offer is non-blocking).
