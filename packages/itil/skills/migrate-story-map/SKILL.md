---
name: wr-itil:migrate-story-map
description: Replace one eligible legacy story map with a manifest-bound canonical map from a complete adopter-ratified mapping.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Migrate Story Map

Use this only for a retained legacy map whose exact historical projection is authorised by a confirmed adopter decision under the manifest-bound historical-row architecture rule.

## Steps

1. Read the complete legacy map and the supplied structured mapping. Confirm every historical card and placement comes from the retained source; do not infer or add content.
2. Confirm the cited decision has `human-oversight: confirmed` and maps the selected story-map identifier to the mapping's historical SHA-256 fingerprint under `legacy-projections`.
3. Run `wr-itil-migrate-story-map <legacy-map.html> <mapping.json>` from the adopter repository root. The command fails before writing on incomplete or mismatched input, and restores the source and manifest if rendering fails. It exits successfully without changes when the map is absent or already canonical.
4. Run the repository's story-map query, renderer, accessibility, and governance checks.
5. Run the repository's required risk review, then commit the replaced map and manifest as one auditable migration.

Do not use this skill to create new history, approve an RFC, create stories, or interpret arbitrary legacy HTML automatically.

$ARGUMENTS
