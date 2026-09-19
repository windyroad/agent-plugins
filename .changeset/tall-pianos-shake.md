---
"@windyroad/itil": patch
---

The AFK backlog loop can no longer end by simply going quiet, and being told you are going to bed now keeps it working instead of stopping it.

Every guard against the loop stopping early fired when it was about to print its ending, so a loop that stopped by printing nothing reached none of them. The orchestrator now leaves the loop only through an ending it names in the transcript, and a turn spent running the loop ends having either printed one of those endings or dispatched the next ticket. A closing message that calls the drain parked or leaves you an instruction for restarting it is named as the defect rather than as an ending.

An announcement that you are leaving, going to sleep or will be unreachable is the loop's reason to keep going, not a signal to stop — which is the whole point of a loop built for the hours you are away. A turn spent on something else you asked for is untouched by the rule; how long the loop stays live across a detour like that is a separate question still open.
