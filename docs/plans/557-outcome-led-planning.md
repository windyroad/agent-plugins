# Outcome-led planning skill delivery

## Confirmed objective

Developers using Claude Code or Codex can invoke a published Windy Road skill
that helps them establish and confirm a SMART outcome, then achieve it through
Now/Next/Later planning and iteration. The skill interviews one question at a
time and waits for answers, obtains goal confirmation before executable
planning, reviews every plan revision with architecture, JTBD and risk, and
uses INVEST for Now without adding story records unless the project requires
them.

Completion evidence: stable npm publication, fresh installation and discovery
in both runtimes, and behavioral checks of the confirmed contract. Prefer end
of Thursday 15 October 2026; acceptable by end of Friday 16 October 2026,
Australia/Sydney. The user explicitly confirmed this playback in the current
conversation before this executable plan resumed.

## Delivered: update the actively used local skill first

P8 follows the user's local-first priority. The personal skill at
`/Users/tomhoward/.codex/skills/outcome-led-planning` now matches the corrected
canonical contract except its invocation name. Existing UI metadata is preserved.
The original was backed up under the ignored audit workspace; frontmatter
validation and normalized byte comparison passed. The personal copy remains
available because the user is actively using it.

## Delivered Now: qualify and integrate the complete skill

Use the existing ITIL package, canonical skill and generated Codex projection.
Preserve the accepted STORY-106 on the ratified developer journey and the
problem-traced RFC-106 release row. No new package, reviewer role or hook.

- Add the SMART interview and explicit confirmation gate. Ordinary replanning
  keeps the confirmed objective; substantive changes require confirmation.
- Apply INVEST to coherent release increments, allowing internal dependencies.
- Require all three substantive plan reviews and resolve substantive JTBD
  rejection before execution, alongside architecture and risk findings.
- Omit unrelated capture delegation only from this skill's Codex projection.
- Qualify actual model decisions on both projections, including sequential
  interview turns, goal confirmation and substantive reviewer rejection.
- Keep subject scenarios isolated from assertion/context metadata and grade
  independently. Verify that boundary with subprocess tests.
- Verify packing, invocation names, preserved existing projections and isolated
  installation. Integrate without a changeset and watch exact implementation CI.

P8 passed architecture, JTBD and plan-risk assessment, including the explicit
timing question or user-declined exception and local-first sequencing. Forecast residual risk
is 4/25 against appetite 5, conditional on actual controls passing. Earlier
P6 tests and the aborted assertion-contaminated model run do not qualify the final source.

## Delivered Next: intentional release and verified adoption

After implementation CI and actual evidence, revise and obtain all three plan
reviews. Prepare one complete cumulative minor changeset in its own commit;
obtain current action risk assessments; use the standard push and release
watchers. Verify the exact registry version, fetched artifact, both runtime
installations and installed contract. Preserve the actively used personal copy; compare it with the released contract
without silently removing or disabling it.

## Later: no further work required

The confirmed objective is verified. Speculative improvements are outside this
achieved objective; no further increment is retained.

## Learning to retain

- A personal artifact did not satisfy expected plugin publication.
- Goal confirmation is separate from plan reviews and action authority.
- All three reviews must be substantive; completed JTBD rejection is enforcing.
- Evaluation metadata contains expected assertions and must not reach subjects.
- Implementation CI precedes intentional cumulative release metadata.

## Verification evidence

- Final P8 canonical source SHA-256:
  `fa69c4ba7825a7d3958798d5fbbb79c735e5eb6972d1a577d98d725a6a39f76a`.
- Local personal source SHA-256:
  `bd6bfc374ad94a77529b1bee36fee6189df38e89118f382c59ea8876f9129fa4`.
  Normalized comparison passed; original UI metadata preserved.
- Final harness-boundary and packed-installation Bats checks: 9/9 passed.
  These exercise subprocess isolation, sequential session resumption, projection,
  packaging and real isolated Codex plugin installation.
- Generated Codex skill format validation passed. Plugin manifest, Codex
  manifest, shared instructions, executable modes and whitespace checks passed.
- Claude plugin validation passed with existing manifest/hook warnings.
- P8 semantic qualification passed all 20 single-turn cases. Both multi-turn
  cases failed because the CLI inherited loop stdin and consumed future user
  replies; this is invalid interview evidence, retained in the audit workspace.
  Architecture, JTBD and risk approved the bounded stdin-isolation repair. A
  regression test reproduced the failure before both loop calls were redirected
  to `/dev/null`; all three harness-boundary tests then passed. Both actual
  multi-turn cases then passed, each returning three separate exchanges.
  Combined qualification is 22/22 scenarios across the unchanged canonical
  contract and Codex projection; no skill contract changed.
- Tabletop model checks measure decisions expressed by the subject; they do
  not prove live reviewer dispatch or external effects.

## Terminal receipt: objective verified, 2026-10-15

Publication and fresh native invocation completed within the preferred deadline.
The objective remains the confirmed result above. This is a terminal status
update, not another executable plan or an authorization for new work.

### Publication and pipeline evidence

- Implementation: `d605e6c42ecc9f7ce516d5e643f6ffa1412e24f5`;
  [exact CI 38652395169](https://github.com/windyroad/agent-plugins/actions/runs/38652395169)
  fully passed before intentional release metadata.
- Cumulative changeset-only preparation: `3e5a24d5`, after preserving another
  owner's documentation update; [CI 38655481854](https://github.com/windyroad/agent-plugins/actions/runs/38655481854)
  passed. The earlier metadata commit is recoverable on
  `codex/p557-release-preparation-before-trunk-reconcile`.
- Published [`@windyroad/itil@3.1.0`](https://www.npmjs.com/package/@windyroad/itil/v/3.1.0)
  through [PR #528](https://github.com/windyroad/agent-plugins/pull/528), at
  `d1f4a081194d69a99195694fdf1c55cdea0e144a`.
  [PR CI 38655600782](https://github.com/windyroad/agent-plugins/actions/runs/38655600782),
  [publication 38656992826](https://github.com/windyroad/agent-plugins/actions/runs/38656992826)
  and [release-merge CI 38656992744](https://github.com/windyroad/agent-plugins/actions/runs/38656992744)
  passed. Later CI's existing quota preflight supplies no additional model
  evidence; the valid 22-scenario qualification above remains separate.
- Registry `gitHead` matches the release commit. Independently computed tarball
  SHA-512 matches registry SRI:
  `sha512-uao5zjv2OPXSU2t43UHhxHt5+RLLZ674Mdb9lqAktzHxaR9bVzutlaEVOc7ehaZVz1sYwRRpS5nc4bFtwIO/hg==`.
  Tarball SHA-256:
  `75779ec0ed365e14e364601485ad28dec336b261051c5252669c993be9da233b`.

### Fresh installed exercise

The verified tarball's supported installer created both fresh installations in
isolated user homes outside the source checkout. Claude installed through its
Git marketplace path; its 3.1.0 skill metadata/body match the fetched artifact.
Codex staged the fetched package and its installed projection matches artifact
bytes. Both then ran from an empty consumer directory.

- Claude Code 2.1.296 listed enabled plugin `wr-itil@windyroad` 3.1.0. Native
  session `8d6fd010-fcbd-4a35-9293-39736265ebdc` registered
  `/wr-itil:outcome-led-planning` from that installed plugin; tools were limited
  to Read and Skill. It played back the supplied SMART objective and waited for
  confirmation before planning, then exited successfully.
  Transcript SHA-256:
  `eae52fcaa3cac634540205f27cc2be5c692e135c04becb3019ddde72d662dccb`.
- Codex 0.162.0 listed enabled plugin `wr-itil@windyroad-itil-local` 3.1.0.
  Ephemeral read-only session `01a13cdc-de2a-7001-8bc1-c8e5e8a5659d` invoked
  `$wr-itil:outcome-led-planning`, read the exact isolated installed
  `3.1.0/skills-codex/outcome-led-planning/SKILL.md`, played back the supplied
  SMART objective and waited for confirmation before planning. Exit status 0.
  Transcript SHA-256:
  `a99b694f5ec9ed77edef6c170594f40deb1f9722761a85c68afbc9476abda91e`.
- Parsed canonical metadata/body and installed Claude content match qualified
  source; Codex installed bytes match the published projection, SHA-256
  `9c4b61ae7ff4c322a6351270d5bcce214c6e8f213e41409077b034cbd92912db`.
  Publisher YAML quoting changes formatting only. The personal copy still
  matches the released contract after normalizing its invocation name; existing
  UI metadata is preserved.
- Codex used an owner-only temporary reference to existing native authentication;
  cleanup removed that reference. No credentials were copied into evidence.
- Native smoke trials establish installed discovery, loading and the initial
  confirmation gate. Sequential interviews, later planning decisions and review
  rejection use the separate model qualification above. Neither smoke proves
  live reviewer dispatch, every future interaction, or hot-reload in existing
  desktop chats. The isolated Codex home lacked the separate risk-scorer plugin;
  its absence was not exercised before confirmation and is not a passing review.

The ignored `docs/audits/557-outcome-led-planning-workspace/published-3.1.0/`
contains the registry receipt, tarball, installer/plugin lists, installed skill
copies, native transcripts, cleanup receipt and SHA-256 inventory. Essential
observations are recorded here so completion remains understandable without
those temporary logs.

### Terminal reconciliation

Architecture independently verified the native evidence and approved one
coherent lifecycle receipt: STORY-106 done, RFC-106 derived delivered, and P557
closed on its stated evidence. ADR-103 supersedes the legacy document-RFC
status prerequisite; ADR-129 preserves the direct evidence-authorized closure
path. Existing map ratification and all human-oversight markers are preserved.
