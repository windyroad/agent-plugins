---
name: developer
description: Developer using AI coding agents — solo, small-team, or within a larger software development team
human-oversight: confirmed
oversight-date: 2026-08-09
oversight-note: "2026-08-09 — re-ratified via AskUserQuestion after a material amendment under ADR-068 lockstep (P357 post-change brief): added one context constraint, the reading context. This person reads governance artefacts away from the repository — phone, preview pane, attachment, browser rendering — with no filesystem access, so an artefact must be readable from its own bytes and a claim made on it must be self-evidently true rather than verifiable-in-principle. It is hosted at persona tier rather than on individual jobs because it is a fact about the person and constrains every artefact they read; the option of attaching it per-job was offered and declined on the grounds that it would be restated and drift. Load-bearing already: ADR-105 argued it from first principles because there was nothing to cite, ADR-107 leaned on it and left half its argument out, and on 2026-08-09 it produced a live defect where a story map's value clauses were separated only by a CSS rule and ran together when the file was opened away from its directory. Closes the first two investigation tasks on P484. Prior confirmations: 2026-08-04, 2026-05-27."
prior-oversight-note: "2026-08-04 — re-ratified via AskUserQuestion after a material amendment under ADR-068 lockstep (P357 post-change brief): added one context constraint (repo shape varies — a project may ship via changesets on npm, a tag push, a Makefile target, or nothing, so tooling must discover rather than assume) and one pain point (out-of-band pipeline observation). Both surfaced by the P435 review. The repo-shape constraint binds JTBD-002 and JTBD-012, so it is hosted here rather than asserted inside a single job — hosting it at persona level removes the circularity of a split criterion resting on a claim made by the artefact arguing for the split. Prior confirmation: 2026-05-27."
---

# Developer

## Who

Uses AI coding agents (Claude Code) to do hands-on software development — working solo, in a small team, or within a larger software development team. Moves fast, ships often. May be working across multiple repos simultaneously.

The distinguishing axis is **role**, not team size: this is the developer who *does the work*, as opposed to `tech-lead` (the governance / quality-enforcement role). The persona's jobs apply to a developer on a team of any size.

## Context Constraints

- Wants speed without sacrificing quality
- May install only 2-3 plugins relevant to their project
- Owns the work directly; whether a dedicated QA or architecture-review process exists depends on team size, so the plugins must carry the guardrails regardless
- Repo shape varies: the developer's projects do not share one stack. How a project ships may be changesets on npm, a tag push, a Makefile target, or nothing at all. Tooling that names a specific command must discover it rather than assume it
- Reads governance artefacts away from the repository — on a phone, in a preview pane, as an attachment, in a browser rendering — with no filesystem access and often with attention divided. Two things follow. An artefact must be readable from its own bytes: if it needs a stylesheet, a sibling file, or a directory around it to make sense, it does not make sense. And a claim made *on* an artefact cannot be checked against the corpus at read time, so it must be self-evidently true rather than verifiable-in-principle — an identifier is an audit-trail annotation, never the thing that carries the meaning

## Pain Points

- Agents skip steps (architecture review, TDD, risk assessment)
- Silent config corruption from misbehaving plugins
- Having to manually police AI output
- Plugin-version drift across sibling projects on the same machine: a new plugin release lands on npm but the user's active sessions still run the old code, and catching up every sibling project (`cd ../foo && claude plugin install …`) is manual, repetitive, and easy to forget.
- Out-of-band pipeline observation: after pushing, learning what the pipeline did means leaving the terminal to poll CI or hunt for a release PR. The outcome arrives while attention has already moved on, so failures are found late.
