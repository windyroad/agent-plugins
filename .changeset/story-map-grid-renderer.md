---
"@windyroad/itil": minor
---

A new `wr-itil-render-story-map` command renders story maps from data, and renders them as a grid rather than a list.

`/wr-itil:capture-story-map` shipped an HTML skeleton that was not a story map. A story map in Patton's sense is two-dimensional — journey activities across the top, release slices down the side, task cards in the cells, so that reading a row left to right tells you everything that ships together. The skeleton emitted a vertical stack of headings with no columns, no release dimension and no cells, so every map it generated was a list wearing map vocabulary.

One template now owns the shape, and the renderer builds every map from it. A map is a single file carrying its own data in a `<script id="story-map-data">` block; the renderer reads that block and rewrites the presentation around it in place. Creating a map and editing one are the same command on the same file, so no source file can fall out of step with the rendered output. The skill no longer asks an agent to hand-write markup, and no longer leaves it to infer the shape from a sibling map — which is how the shape drifted in the first place.

Ratification fingerprints for story maps now cover the data block rather than the whole file. Without that, changing the template would regenerate every map, drift every stored fingerprint, and silently revoke approvals a human had given. Maps carrying no data block — anything authored before this release — still hash whole-file, so existing ratifications survive untouched and a mixed corpus stays safe.

This release also fixes packaging: `@windyroad/itil` now ships the template in its published files. Without that entry, installing the plugin gave you a renderer that could not find its template.
