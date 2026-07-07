---
"@windyroad/itil": minor
---

Story-lifecycle gates (P404 / ADR-095 + ADR-096). capture-story now enforces
story-map membership (I8) and real content (user value + acceptance criteria) at
capture, refusing-and-routing to capture-story-map when no map exists. A new
PreToolUse gate (itil-no-implement-draft-gate) blocks any commit whose
`Refs: STORY-NNN` trailer names a story still in draft — a draft story cannot be
implemented; accept it first. The draft->in-progress auto-transition is removed;
the commit-trailer advisory now advises accepted->in-progress. Bootstrap-exempt
and capture commits are exempt; the gate is fail-open and bypassable with
BYPASS_NO_IMPLEMENT_DRAFT=1.
