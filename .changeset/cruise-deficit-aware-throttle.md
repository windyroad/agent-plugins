---
"@windyroad/cruise": patch
---

Make the throttle deficit-aware so it stops over-braking when you're behind pace. It now brakes only when a rolling window is both over-rate AND at or over its linear pace line. While you're under the line you hold banked surplus, so a burst no longer triggers braking — the previous controller braked on instantaneous rate alone and slowed you even with days of runway and usage well under the line. Braking still engages as you reach the line and holds you to glide to reset, so the non-exhaustion behaviour is unchanged. Also fixes /wr-cruise:status, which labelled any active sleep as "ahead of pace" regardless of your real position.
