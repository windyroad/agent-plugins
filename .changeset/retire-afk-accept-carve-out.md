---
"@windyroad/itil": major
---

**Your story map is now what you approve, and approving it approves every story on it.**

Until now you ratified a story map and then ratified each story on it again, one at a time. Worse, capturing a story listed it on its map, which re-opened that map's approval — so writing a story could un-approve the map the story depended on.

Approval now sits in one place. Ratify the map and every story on it is approved, including stories added later.

**A story no longer carries an oversight field at all.** No `human-oversight:`, no `oversight-hash:`. Whether a story is approved is worked out from the maps named in its `story-maps:` field: if every one of them is ratified, the story is approved. A story naming no map is never approved, so deleting the field cannot approve a story by accident. `wr-itil-mark-story-oversight-confirmed` now refuses a story and tells you to ratify the map instead.

This is a cutover, not a gradual migration. Oversight fields were stripped from every story that had one, and a leftover `human-oversight: confirmed` on a story no longer approves anything. Until you ratify a map, the stories on it are unapproved and commits referencing them are blocked. Ratifying each map once clears it.

What still re-opens a map's approval: a new activity column, a change to the map's own prose or traces. What no longer does: drawing a release row, putting a story in one, or editing a story's body. A row is scheduling, and scheduling was never what you were approving.

**Also removed.** An unattended run used to be able to accept a story on its own if you turned that on, and a set of commands and flags existed to support it. The deadlock that feature worked around is gone, so the feature is gone with it:

- the `wr-itil-check-afk-accept-eligible` command
- the `--pure-decomposition` flag on `wr-itil-mark-story-oversight-confirmed`
- the `--with-afk-accepted` flag on `wr-itil-detect-unratified-stories-maps`
- the `afk_accept_pure_decomposition` key in `.claude/itil.config.json`
- the `afkAccepted` field in `wr-itil-story-map-query` output
- the `afk-accept:` story field and its `## Decomposition basis` section

If you set `afk_accept_pure_decomposition` in your config, the key is now ignored — delete it. If you call the removed command from a script, that call will fail; the check it performed no longer has anything to check. No story in this project's own corpus ever used the feature, so we have no evidence of it running anywhere, but the removal is a hard break for anyone who did opt in.

`wr-itil-check-rfc-stories-ratified` takes an optional third argument, the story-maps root, so it can resolve a story's approval through its map.
