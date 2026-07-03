---
"@windyroad/itil": patch
---

derive-release-vehicle: recover the release vehicle from a co-committed changeset when the ticket body lacks the `**Release vehicle**` seed (P389). An iter that fixes a Known Error sometimes ships the fix + changeset in one commit but omits the P330 seed, leaving the body with no `.changeset/` reference — `derive` would exit 2 and the post-release K→V auto-enumerator (P228) would silently skip the ticket even though its fix shipped (exactly why P384 was not auto-detected). Under ADR-014's one-commit grain the authoring commit also touched the ticket, so a `.changeset/*.md` added by a commit that also touched the ticket file is its release vehicle; the fallback walks the ticket's commits (newest first, across renames) and takes the first co-committed changeset. Behavioural bats added.
