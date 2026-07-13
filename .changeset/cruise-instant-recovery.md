---
"@windyroad/cruise": patch
---

Recover from throttling instantly when you fall behind pace. A per-call sleep that ramped up while you were over pace used to unwind one call at a time — so a session that had banked surplus stayed slow for minutes after it was already behind pace, and the status command itself sat waiting on the throttle. Now the moment a window is behind its pace line the injected sleep drops to zero, and the re-baseline and too-soon paths no longer re-apply a stale sleep. Braking still engages the instant you're over pace again, so pacing is unchanged when you need it.
