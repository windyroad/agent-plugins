# Ask Hygiene — 2026-05-25 (work-problems → release saga → install-updates → risk-register → #149 fix)

Session arc: `/wr-itil:work-problems` (iter P073 close) → Step 6.5 release halt (architect@0.8.0 E404) → npm token 2FA-bypass fix + release → loop-end directives → install-updates simplification → risk-register naming migration → issue #149 root-cause + fix + release.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| 1 | Bulk WSJF re-rate | direction | Gap: ~83 placeholder stubs — user cadence (small batches vs bulk) not derivable from framework; accumulated loop-end outstanding_question per Step 2.5 / ADR-044. |
| 2 | Bulk K-E transitions | direction | Gap: whether to bulk-transition ~45 eligible tickets reshapes the queue — a scope/direction call, not WSJF-resolvable. |
| 3 | docs/retros gate exclusion | deviation-approval | Gap: iter-1 surfaced a deviation-candidate (architect+JTBD gates fire on run-retro docs/retros trail writes); existing P131/gate-exclusion design contradicted by evidence → user routes (append P225). |
| 4 | P258 severity | direction | Gap: P258 label 12 vs Impact4×L1=4 inconsistency; re-rate to match P0 framing is a severity judgment the framework leaves to the maintainer. |
| 5 | install-updates sibling scope | direction | Gap: architect Needs-Direction (ADR-064) — sibling-scope (b keep / c current-only) materially diverges; "just refresh" pinned outcome but not scope. |
| 6 | install-updates bootstrap ADR | direction | Gap: architect Needs-Direction — amend ADR-059 vs supersede vs new ADR; decision-recording mechanics not framework-pinned. |
| 7 | Risk-register naming reconcile | direction | Gap: 24 curated `.md` entries vs canonical `.active.md`; migrate-vs-widen-tooling-vs-defer are materially different approaches on user-curated files (borderline — `.active.md` canonicity was framework-resolved, but the migrate/widen/defer approach was not). |

**Lazy count: 0**
**Direction count: 6**
**Deviation-approval count: 1**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

Notable non-ask (correct framework-resolution, NOT counted): the #149 architect Needs-Direction surfaced "Option B vs C" — resolved as B (within ADR-028, no deviation) per the architect's own framing; acted without an AskUserQuestion. Avoided a lazy ask.

Meta-friction this retro: the Step 2d trail write itself tripped BOTH the architect AND JTBD edit gates (docs/retros/ is absent from `architect-enforce-edit.sh` and `jtbd-enforce-edit.sh` exclusion lists, though both exclude docs/problems + docs/briefing + docs/jtbd), forcing two dispatches to unblock one advisory write — the live recurrence of the P225 docs/retros gate-exclusion gap. Both agents independently confirmed the gap this session (architect ac53…, jtbd a84f…); adding docs/retros/ to both exclusion lists is a precedented (ADR-amendment-worthy) fix tracked under P225.

TREND: lazy stays 0 (consecutive retros at lazy=0 per `check-ask-hygiene.sh`). R6 numeric gate (≥2 lazy across 3 consecutive) NOT fired.
