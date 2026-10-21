---
status: accepted
story-id: remember-project-tracking-and-share-increment-work
reported: 2026-10-21
decision-makers: [Tom Howard]
problems: [P560]
jtbd: [JTBD-008, JTBD-004, JTBD-003, JTBD-101]
rfcs: [RFC-110]
story-maps: [STORY-MAP-002]
estimated-effort: M
---

# STORY-110: Remember project tracking choices and share increment work

**Reported**: 2026-10-21
**Problems**: P560
**JTBD**: JTBD-008, JTBD-004, JTBD-003, JTBD-101
**RFCs**: RFC-110
**Story Maps**: STORY-MAP-002
**Estimated effort**: M, bounded skill extraction, shared configuration guidance, existing package/evaluation checks and release workflows; model and CI duration remain uncertain.

## User value

In order to continue useful shared work across sessions, as a developer, I want planning and contribution skills to reuse my project tracking choice and expose bounded work within the current increment.

## Acceptance criteria

- [x] Update personal planning and install contribute first, preserving the existing planning identity, picker, modes and latest upstream changes.
- [ ] Ask one GitHub Issues or Local question only when unset, wait, save and read back the choice; both skills reuse it across fresh sessions, honor explicit changes and preserve unrelated or invalid configuration.
- [ ] Local mode requires no GitHub setup; GitHub Projects remain optional, with bootstrap only for selected missing setup and no implied access or messaging authority.
- [ ] Preserve five independent plan critics, scorer-led necessary risk treatment and the prohibition on speculative risk-mitigation tasks.
- [ ] Expose bounded contribution opportunities and pull just-in-time tasks within assessed Now without reserving all work; preserve one claim, ownership, dependencies and actual acknowledgement.
- [ ] Package both standalone entrypoints and complete ITIL planning compatibility with resolving references, behavioral qualification in both runtimes and preserved personal installations.
- [ ] Publish through the normal pipeline and verify registry provenance, fresh installation, discovery, native behavior and matching live public documentation.

## INVEST assessment

The two entrypoints form one independently useful capability because cross-skill persistence is the requested result. Implementation means remain negotiable. Medium scope is bounded to existing skill and packaging boundaries, with no new runtime parser, service, hook or polling system. Acceptance is observable through saved files, native sessions, package/evaluation results and actual publication. Consumers acquire no story requirement.

## Implementation notes

Plans P3 and P4 passed five independent critics. The local-first payload preserves the latest five-critic, just-in-time contribution and GitHub bootstrap guidance. P3 native qualification verifies both backends and fresh cross-skill reuse: Claude at the default path, Codex at a project-declared writable path. Codex workspace-write correctly refuses its protected default without falsely claiming persistence. No actual GitHub operations are credited. P4 publishes the frozen payload through existing canonical, compatibility and Codex projections, then normal qualification/release/docs verification. Proposed ADR-142 records shared declarative project configuration without a new ratification gate under ADR-136.

## Dependencies

- **Blocked by**: none beyond normal review, qualification and release gates.
- **Composes with**: architecture, JTBD, risk, cognitive accessibility and planning critics.
