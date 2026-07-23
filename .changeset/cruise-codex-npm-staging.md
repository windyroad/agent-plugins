---
"@windyroad/cruise": patch
---

Stage the published package outside its scoped npm path before registering the Codex marketplace, so Codex does not misinterpret `@windyroad` as a Git ref.
