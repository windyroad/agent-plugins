---
"@windyroad/itil": minor
---

Accepting a story no longer un-ratifies it.

The previous release said ticking a criterion or advancing a story's status would not count as a change. That was half true: the oversight fingerprint ignored the `status:` field in a story's frontmatter, but it still hashed the `**Status**:` line that repeated the same value in the body. So accepting a story you had just ratified changed hashed content, the story read as unratified, and the commit gate then blocked its own implementation. Both fingerprint functions had the gap.

The duplicate line is now gone — from the story template, from this repo's stories, and from the documented body shape. Lifecycle state lives in frontmatter only. The fingerprint functions themselves are unchanged, so nothing you have already ratified is invalidated by upgrading.

**Your existing stories still carry the line, so run this once:**

```
wr-itil-migrate-story-status-mirror docs/stories
```

That is a plain command rather than a `/` skill, so it will not appear in autocomplete — there is no decision to walk you through, so there is nothing for a skill to host.

It removes the duplicate and re-points each story's fingerprint at the same content you ratified. It never writes `human-oversight`, so a story you never confirmed stays unconfirmed. A story whose stored fingerprint had already drifted is left drifted rather than quietly revived. And where a story's `**Status**:` line says something its frontmatter does not, the migration skips it and tells you, because that line is carrying information rather than duplicating it. Re-running is a no-op.
