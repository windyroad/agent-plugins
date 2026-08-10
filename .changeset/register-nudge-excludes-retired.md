---
"@windyroad/risk-scorer": patch
---

The risk-register nudge now counts a backlog you can actually clear.

The session-start hook counts standing-risk entries still marked as needing curation and says so until the count reaches zero. It was counting retired entries too — risks already closed out, whose impact and likelihood nobody needs to weigh any more. In the plugin's own register that was twenty-two of sixty-nine, a floor the count could never drop below, so the message repeated every session no matter how much curation happened.

Retired entries are now excluded and the count is drainable.

The filter is exclusion-shaped — every entry except a retired one — rather than a match on active entries. A register has three states, and the third is a risk you have consciously decided to tolerate. That decision should rest on the very scoring the curation marker says is still missing, so those entries still count. Matching on active alone would have written them off silently, and would also have missed an entry carrying no status suffix at all.

Nothing else about the hook changes. It stays a read, it stays one line, and `WR_SUPPRESS_OVERSIGHT_NUDGE=1` still silences it along with every other nudge of its class.
