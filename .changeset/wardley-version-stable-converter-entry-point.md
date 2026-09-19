---
"@windyroad/wardley": minor
---

Render a Wardley map by calling `wr-wardley-owm-to-svg`.

Installing the plugin now puts the OWM-to-SVG converter on your `PATH` as a
named command, and it keeps working across upgrades -- it resolves to the newest
installed version at every call. Previously the converter could only be reached
by a path into the plugin cache, and that path carries a version number that
changes on every release, so anything calling it that way broke the next time
the plugin updated. Reported by a consumer whose map render failed with
`Cannot find module` after an upgrade.

In Codex, plugin `bin/` directories are not on `PATH`; call
`node <skill-dir>/owm-to-svg.mjs` from the installed skill directory, which is
what the skill already did and continues to do.
