---
"@windyroad/itil": patch
"@windyroad/architect": patch
"@windyroad/jtbd": patch
"@windyroad/tdd": patch
"@windyroad/risk-scorer": patch
"@windyroad/style-guide": patch
"@windyroad/voice-tone": patch
---

quota-pace-throttle: smart glide-path pacing (P160). Replace the bang-bang
fixed-60s catch-up with a proportional controller — sleep = CAP × (1 − safe_rate)
where safe_rate = budget-left / time-left over the tighter window. Over-pace work
now slows proportionally and eases back to the sustainable pace before the quota
is consumed (a runner drifting back onto pace, not stopping dead), while still
making progress the whole time. Never a hard stop; fail-open unchanged.
