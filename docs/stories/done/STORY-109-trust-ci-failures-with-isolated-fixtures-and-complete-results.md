---
status: done
story-id: trust-ci-failures-with-isolated-fixtures-and-complete-results
reported: 2026-10-16
decision-makers: [Tom Howard]
problems: [P459]
jtbd: [JTBD-001, JTBD-008, JTBD-101]
rfcs: [RFC-109]
story-maps: [STORY-MAP-002]
estimated-effort: S
---

# STORY-109: Trust CI failures with isolated fixtures and complete results

**Reported**: 2026-10-16
**Problems**: P459
**JTBD**: JTBD-001, JTBD-008, JTBD-101
**RFCs**: RFC-109
**Story Maps**: STORY-MAP-002, activity `implement`
**Estimated effort**: S, bounded existing evaluation driver, result transport and CI artifact changes.

## User value

In order to diagnose CI failures without confusing hypothetical proposals with the plugin repository, as a developer, I want isolated evaluation fixtures and complete model responses and grading results when checks fail.

## Acceptance criteria

- [x] The Claude architect evaluation uses the existing isolated fixture repository, exact agent prompt and model, and read-only fixture inspection without ambient settings, hooks or MCP configuration.
- [x] Existing agent suites and CI skill checks retain complete structured responses and grading results in designated audit JSON artifacts, excluding credentials, environment dumps and runtime configuration.
- [x] Behavioral checks exercise subprocess isolation, result transport and serialization, and preserve nonzero provider and evaluation failures except recognized pure subscription exhaustion under proposed ADR-141; existing scenarios, assertions, model roles and retry policies remain unchanged.
- [x] Pure quota exhaustion at the probe or during any selected campaign stops further Claude calls, warns and retains partial JSON without model-test pass credit. Mixed, semantic and unclassified failures remain blocking; a later available job runs normally.
- [x] A meaningful new source revision passes the exact required CI with the original incident eligibility cases retained. Selected Claude campaigns provide actual results or an explicit pure-quota unavailable warning under proposed ADR-141; unavailable cases receive no pass credit. A passing execution does not explain the unavailable first failing response.

## INVEST assessment

This independently testable developer-tool repair restores meaningful evaluation context and diagnostics. Means remain negotiable within those evidence requirements. Scope is small and bounded to existing drivers, command transport, CI outputs and behavioral checks. Native generation remains subject to model quota; provider rejection is not passing evidence. No production agent, skill, hook or authority changes are included.

## Driving problem trace

P459 already records the same unique-primary-key over-fire case and missing full failure evidence. The current two failed attempts expose these remaining mechanisms without proving that every failure is sampling variance.

## JTBD trace

JTBD-001 requires trustworthy governance evidence. JTBD-008 keeps this repair separate from the planning capability. JTBD-101 requires meaningful contributor validation.

## Implementation notes

Plan G6a passed independent architecture, JTBD and plan-risk review. Preserve STORY-101's model-pinning scope. Use existing fixture data and read-only tools, retain all current oracles and nonzero outcomes, and upload only designated result JSON. No unchanged-revision retry is included.

The G6a repair passed exact source CI at `27093d4936a330a7e9e7d8117b43b9245a5dce5b`, retaining all 45 passing model cases. Subsequent planning source `5864aca8e1c69820dc70bda62668b37d5c5a0f61` also passed required CI. The release merge's CI run `38909557295` retained a further diagnostic gap: both work-problems appetite cases errored inside the grading process, with no grading verdict. Its wrapper discarded captured stdout when Claude exited nonzero, leaving the provider cause unknown.

Plan G9 preserves that failed evidence and adds a bounded diagnostic transport repair: failed grader stdout goes to stderr, the original nonzero exit survives, unused stdin closes, and successful JSON extraction remains unchanged. Owning subprocess tests cover valid and malformed failed payloads, exact exit status, separate output streams and unchanged successful grading. This changes tarball-excluded evaluation infrastructure only. No model, rubric, threshold or retry policy changes; exact new CI remains required before unrelated documentation integration. P459 remains Known Error.

G9 CI run `38978617123` passes the work-problems appetite checks, then fails incident eligibility at 3/4 with zero provider errors. Its complete retained unknown-baseline row exposes an oracle-scope defect: the grader explicitly acknowledges that the response satisfies the eligibility rubric, then rejects a separate prose consent question using an unrelated project rule. The original failed result is preserved; the subject's separate process defect is not excused.

Plan G11 isolates the grader in a temporary neutral directory and Claude safe mode, with a rubric-only system prompt and no tools, preserving authentication, model selection and failure transport. Owning subprocess checks cover contaminated callers and cleanup. Four direct semantic controls test the unchanged retained positive pair, invalid incident declaration, unsupported regression inference and a separately explicit prohibition of consent questions. CI retains their results before running the unchanged original incident cases. New semantic qualification and required CI remain pending.

Plan G14 preserves the retained G11 native grades: all four match the expected true/false/false/false results, but the single-line JavaScript assertion is expression-wrapped by Promptfoo and throws `Unexpected token return`. The controls therefore failed assertion execution and the original incident group was skipped. G14 changes only the scalar representation to a multiline function body, preserving its predicate, all candidates, rubrics and expectations. An owning actual-Promptfoo subprocess test requires four matching grades to pass, then one deliberately inverted grade to fail with complete retained results. New exact-source CI remains required; G13 qualification and public documentation remain recoverably stashed. P459 remains Known Error.

Plan G13 applies the existing neutral rubric-grader boundary and diagnostic retention to planning's separate evaluation driver. Its owning tests preserve first-argument forwarding, independent subject/grader data and interview sessions, and observe isolated cwd, cleanup, EOF and exact nonzero diagnostics. CI gains a conditional planning campaign and retained result JSON, with behavioral range and command-transport checks. G14 exact CI and the new native campaign remain prerequisites for subsequent integration and qualification respectively.

CI run `38986500635` retained 16 passing planning cases and 32 provider errors after Claude session quota expired. Two retained diagnostics identify the session limit; remaining errors do not preserve that exact line. The campaign provides no complete qualification. G19a narrows only the already-conditional planning campaign to behavioral source, projection and evaluation inputs, avoiding duplicate planning calls on version-only changes. Existing full-main governance campaigns, unconditional checks, conservative unknown-range behavior and provider failure handling remain unchanged. Final qualification requires a complete fresh 54-case campaign for each runtime; the original 49 governance cases remain required. One bounded attempt after observed provider recovery is permitted; previous failures remain evidence.


## Quota handling requested during qualification

Source CI run `39008611611` initially retained 32 successful governance cases
and two provider errors, then stopped before planning. Its second attempt passed
the CI job by warning and skipping at the initial quota probe; it supplied no
additional model-test evidence. The user explicitly requested disabling Claude
tests when quota is exceeded, including exhaustion after a successful probe.

G33Q follows proposed, unconfirmed ADR-141. The existing CI runner owns all
selected campaigns and their original commands. A temporary Claude forwarding
shim recognizes only actual unsuccessful pure quota diagnostics and stops
further calls. A second forwarding boundary captures each known evaluation
script completely and grants a distinct provider proof only when no other
diagnostic accompanies the quota error. A command may warn and stop subsequent
campaigns only when fresh structured results contain quota provider errors and
no assertion or unrelated failure. Existing designated partial JSON is retained.
Ordinary failures keep their nonzero status. State is temporary to the job;
future available jobs run normally. No model, rubric, authentication or published
plugin payload changes are included. Owning behavioral checks and exact new CI
must establish this repair before claiming it delivered.

## Dependencies

- **Blocked by**: none.
- **Blocks**: final planning capability publication while required trunk CI is failed.


## Verified completion - 2026-10-17

The isolated architect fixture and complete result transport were integrated at `27093d4936a330a7e9e7d8117b43b9245a5dce5b`; exact source CI retained 45 passing cases. Subsequent diagnostic, neutral-grader and assertion-body corrections are documented above, with original failures retained. The unchanged original incident eligibility cases remain in the selected campaign. This completion does not explain a failed response whose complete payload was unavailable.

The final quota repair at `74f4cfdac4ad5b59358c018110386a0a1d57729b` passes all 22 owning behavioral checks with stable input hashes (`g33q-final-checks.json` and `.log` in the planning audit directory). These checks exercise each selected campaign, exhaustion after a successful probe, concurrent calls, complete outer-provider diagnostics, partial-result validation, mixed and ordinary failures, forwarding and later-job recovery, including actual Promptfoo execution. The earlier unsafe inner-proof experiment remains retained; only the reviewed complete-provider proof implementation is integrated.

[Exact source CI 39016506787](https://github.com/windyroad/agent-plugins/actions/runs/39016506787), [release-merge CI 39017618147](https://github.com/windyroad/agent-plugins/actions/runs/39017618147) and [documentation CI 39018647304](https://github.com/windyroad/agent-plugins/actions/runs/39018647304) succeed. Their explicit Claude quota warnings establish unavailable coverage and receive zero additional model-test pass credit. Pure quota exhaustion stops later calls; semantic, mixed, malformed, transport and unknown failures remain blocking. New available jobs run the selected evaluations normally. No model, rubric, authentication or consumer payload was changed by this repair.

The quota exception follows user direction and proposed ADR-141, which remains unconfirmed. P459 remains Known Error because its broader evaluation-flake work is not complete. Standalone planning publication and its separately qualified 58 cases per runtime do not substitute for unavailable CI model coverage.

After the observed reset, [CI 39019901484](https://github.com/windyroad/agent-plugins/actions/runs/39019901484) at `9a3f28e9605859b916aa616ad7b17661efa24eed` executes all 49 selected Claude checks successfully, with zero failures or provider errors. Its downloaded `agent-evaluation-results` artifact contains all 13 complete result files, including the original four incident eligibility cases. This directly verifies that a later available job resumes execution. The earlier quota warnings still receive no model-test pass credit.
