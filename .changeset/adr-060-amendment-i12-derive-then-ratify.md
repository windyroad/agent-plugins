---
"@windyroad/itil": minor
---

ADR-060 Amendment 2026-06-02: strike type-tag clauses in-place; replace I12 hard-block with derive-then-ratify contract

Per twice-confirmed user direction (2026-05-25 P287 base + 2026-06-02 ADR-060 amendment substance), `docs/decisions/060-...accepted.md` is amended in-place to strike type-tag clauses across Decision Outcome item 1, Type-tag schema block, I2 invariant body, Phase-3 P3.1 type predicate, Phase-4 P4.2/P4.3 type-keyed dispatch, Confirmation criterion 4 (type-tag prompt), and Reassessment "Type-tag drift" entry. I12 (originally `type: user-business` + empty `jtbd:` → hard-block at capture) is REPLACED wholesale with a **derive-then-ratify** contract applying to ALL problems (no type-keyed gating).

**New I12 (derive-then-ratify, applies to ALL problems)**:

- Every `/wr-itil:capture-problem` invocation MUST derive persona + JTBD via LLM analysis of the description.
- On derivation failure or ambiguity, MUST propose candidates for user ratification via `AskUserQuestion`.
- **REJECT** of proposed persona/JTBD = **rejection of the problem** (no ticket created; halt-with-stderr-directive + exit non-zero).
- **CORRECTIONS** (free-text via AskUserQuestion) = **acceptance with corrected values**.
- **ACCEPTANCE** (option-pick of a proposed candidate) = **acceptance with proposed values**.
- AFK callers MUST pre-resolve via `--persona=<value>` + `--jtbd=JTBD-NNN[,...]` flags; `--no-prompt` (REVIVED 2026-06-02) without these flags + derive-failure = halt-with-stderr-directive.

**@windyroad/itil (minor)**:

- `docs/decisions/060-...accepted.md`: Amendment 2026-06-02 block at top of Decision Outcome; type-tag clauses struck in-place across all the surfaces listed above; I12 invariant body REPLACED wholesale; Phase-3 P3.1 type predicate struck; Phase-4 P4.2 enum reconciled to actual `docs/jtbd/` directory names (`developer | tech-lead | plugin-developer | plugin-user` — was stale `solo-developer`); Phase-4 P4.3 type-uniformity references struck; Phase 1 item 8 (Type-tag introduction block) marked STRUCK; Confirmation criteria 4 + 10 + 11 amended in-place; Reassessment "Type-tag drift" struck; frontmatter `amended: 2026-06-02` + `prior-amendments` extended.
- `docs/jtbd/plugin-user/JTBD-301-report-problem-without-pre-classifying.proposed.md` line 25: struck "type, " from maintainer-side-complement outcome; struck trailing comma after "persona" (grammar fix per JTBD AMEND nit); added amendment note.
- `packages/itil/skills/capture-problem/SKILL.md`: frontmatter `allowed-tools` extended to include `AskUserQuestion` (required for I12 ratification dispatch); Rule 6 audit row rewritten end-to-end so REJECT/option-pick/free-text-correction semantics + AFK halt-with-stderr-directive are first-class (NOT optional / best-effort); Step 1.5b body fully rewritten to implement the derive-then-ratify contract per the new I12; flag table revives `--no-prompt` as the AFK-mode marker (suppresses the ratification AskUserQuestion + halts on derive-failure); Composition table row updated; P287 amendment note refreshed to reference the ADR-060 Amendment 2026-06-02 substance ratification.
- `packages/itil/skills/capture-problem/test/capture-problem-step-1-5b-jtbd-trace.bats`: new `i12_should_halt_afk()` positive-predicate reference impl (AFK halt-without-flags); new `classify_ratification_response()` + `ratification_creates_ticket()` reference impls covering REJECT (no ticket) / option-pick (ACCEPTANCE) / free-text correction (CORRECTION-AS-ACCEPTANCE); new `parse_no_prompt_flag()` reference impl; persona enum reconciled to `developer` across `validate_persona` + tests (was stale `solo-developer`); 11 new positive-control assertions for the derive-then-ratify contract; SKILL.md grep tests amended to assert the new contract names (derive-then-ratify identifier, `--no-prompt` flag, REJECT-as-problem-rejection semantics, AFK halt-with-stderr-directive, AskUserQuestion in allowed-tools, ADR-044 direction-setting category 1 on ratification fallback); historical `nullable-field-conditional` assertion replaced with the amendment-cite assertion.
- `packages/itil/skills/capture-problem/test/capture-problem.bats`: amended `allowed-tools` assertion — pre-amendment was "omits AskUserQuestion"; post-amendment is "includes AskUserQuestion" per the I12 derive-then-ratify dispatch requirement.
- `docs/problems/README.md` line 3 + `docs/problems/README-history.md`: amendment fragment appended per P134; prior fragment rotated to history.

**Architect verdict AMEND 2026-06-02** (4 must-fix items all closed in this changeset: persona enum drift to `developer`; Step 1.5b + Rule 6 row rewritten end-to-end; ADR-052 positive-control gap closed via the new bats positive-control fixtures; ADR-044 category re-labelled as direction-setting per the user-ratification framing).

**JTBD verdict PASS 2026-06-02** (JTBD-301 line 25 "type, " strike + trailing-comma grammar fix landed in same iter; firewall preserved; JTBD-006 AFK contract codified via `--no-prompt` + flag pre-resolution caller-side discipline).

**Out of scope this iter** (queued for follow-on iter — not blocking adopter release):

- `/wr-itil:work-problems` capture-on-correction sub-flow caller-side update to pass `--no-prompt --persona=<value> --jtbd=JTBD-NNN` when invoking `/wr-itil:capture-problem` mid-iter. Without this, AFK iters that hit the capture-on-correction path will halt-with-stderr-directive on every undetectable-from-context capture — the loop continues per JTBD-006 (the halt is queued behaviour, not blocked behaviour), but the directive surfaces on user return. JTBD-006 verdict notes this as a caller-side contract that needs landing as an immediate follow-up.
