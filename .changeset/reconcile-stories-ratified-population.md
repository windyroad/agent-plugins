---
"@windyroad/itil": patch
---

The story reconciler no longer reports correct work as drift on the legacy-RFC leg, and now says which population it checked.

An RFC may reference only a story whose story map has been ratified. The reconciler demanded a `## Stories` reverse-trace row from every story that named an RFC regardless, so for a story held pending ratification the row's absence — which is the correct state — was reported as `MISSING_REVERSE_TRACE`. The finding could not be cleared by any compliant action: satisfying it meant writing the reference the rule forbids. That leg is now narrowed to approved stories. The release-row leg is unchanged, because a story card belongs on its map from capture and its absence there is never correct.

Every run of that leg now writes one line to stderr saying how many story/RFC pairs it checked and how many it skipped, so a clean result can be read as "checked and clean" rather than "quietly skipped". Two skip reasons are corpus defects rather than correct absences — a story that names no story map, and a story naming a map id that does not resolve to exactly one file — and they are counted apart so neither hides behind an explanation that does not apply to it.

The helper that regenerates an RFC's `## Stories` section is gated on the same rule and names on stderr any story it withheld, so the repair for a genuine finding can no longer sweep unapproved stories in behind a now-quiet detector.

Standard output and the exit codes are unchanged.
