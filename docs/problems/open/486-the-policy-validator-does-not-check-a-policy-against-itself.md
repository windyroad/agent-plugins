# Problem 486: The policy validator checks a policy's shape, never whether it contradicts itself

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 12 (High) — Impact: 4 × Likelihood: 3. Impact 4: a risk policy is the arbiter every commit, push and release is scored against. A contradiction inside it does not fail loudly; it makes the scorer's answer depend on which clause the agent read, so two runs over the same change can legitimately disagree and both cite the policy. Likelihood 3: it needs a policy edit that introduces the contradiction, and nothing detects one — the validator passed the live instance below.
**Origin**: inbound-reported
**Effort**: M — one more check in the validator, plus deciding what "consistent" means precisely enough to grade
**JTBD**: JTBD-001
**Persona**: plugin-user

## Description

`wr-risk-scorer:policy` validates a `RISK-POLICY.md` draft against six items: impact labels are business consequences and use the five named levels, the appetite is a numeric residual threshold, labels match the matrix rows exactly, business context is present, a last-reviewed date exists, and public repos carry a confidential-information section.

Every one of those is a **shape** check. Nothing reads the policy against itself. So a policy can state two rules that cannot both hold, and the validator passes it.

### The live instance

Reported from an adopter repository, `voder-mcp-hub`, in `RISK-POLICY.md` § 3 — both clauses in the **same sentence**:

> To bring a Severe class within appetite you must either drive its likelihood to Rare with named, exercised controls, **OR reduce its IMPACT below 5 with a consequence-control** (soft-delete/recoverability, structural tenant isolation, least-privilege scoping)

and, a few clauses earlier:

> a ≤4 appetite would have left every Impact-5 class permanently above appetite (5 > 4) regardless of controls — **controls only lower likelihood, never impact**.

The first says a control can reduce impact. The second says it never can. They cannot both be true, and which one an agent applies decides whether a Severe class can be brought within appetite at all.

### Why this is worse than an editing slip

It is a contradiction about the **core mechanic**, not a detail. The whole remediation loop rests on it. If controls only lower likelihood, then an Impact-5 class under a ≤4 appetite is permanently above appetite and no remediation can ever clear it — which is exactly what the second clause says, and exactly what the first clause exists to deny.

So the policy does not merely contain an error. It fails to answer the question it is consulted for, while appearing to answer it twice.

**The shipped scorer has a third position**, which is worth knowing before choosing a fix. Its reports credit controls that reduce likelihood numerically and describe others as *"impact-shaping, no likelihood credit"* — recognising that a control can bound consequence, while declining to move the impact number for it. That is neither of the adopter's two clauses. Whatever the validator ends up enforcing has to agree with what the scorer actually does, or a policy will pass validation and then be scored against different rules.

## Symptoms

- A policy stating two rules that cannot both hold, passing validation.
- Two scoring runs over the same change disagreeing, each citing the policy correctly.
- A remediation list that cannot bring a class within appetite, with no explanation of why.
- A reader having to decide which clause of a ratified policy is the real one.

## Workaround

Read the policy end to end before trusting a score that turns on the impact axis. There is no detector.

## Impact Assessment

- **Who is affected**: every adopter whose commits, pushes and releases are gated on their own policy, and anyone reading a score that cites it.
- **Frequency**: on any policy edit that touches the control mechanics. Rare per-repo, permanent once it lands.
- **Severity**: the policy is the arbiter. An arbiter that contradicts itself makes the gate's answer unpredictable rather than wrong, which is harder to notice.
- **Analytics**: none.

## Root Cause Analysis

Suspected: the checklist was written to catch a policy that is *malformed* — wrong labels, missing threshold, no date — because those were the failures seen when the validator was built. A policy that is well-formed and self-contradicting looks identical to a well-formed correct one under every check that exists.

There is a second-order cause worth naming: shape checks are mechanical and cheap to specify, and consistency checks need a model of what the policy means. The cheap checks got built and the expensive one did not, which is the same economics recorded in P485.

### Investigation Tasks

- [ ] Settle what a control may do, in one place, and make the scorer and the validator agree. Three positions are live: controls lower likelihood only; controls may lower impact; controls may bound consequence without moving the impact number (what the scorer does today). Until this is settled the validator has nothing to check against.
- [ ] Add an internal-consistency check to the validator. The live instance is detectable by an LLM reading two clauses of one sentence — this does not need a formal model, it needs the reviewer to be asked the question at all.
- [ ] Decide the verdict grade. A contradiction is arguably worse than a missing date, which is currently a FAIL, and worse than a missing confidential section, which is a warning.
- [ ] Cover it with a behavioural eval: a policy fixture carrying two contradictory clauses must FAIL, and a policy that merely states an unusual-but-coherent rule must PASS. The second half matters — a check that fires on anything surprising is a check nobody keeps.
- [ ] Check whether the same gap exists in the sibling validators. `plan`, `wip` and `pipeline` all read the policy; if none of them notices a contradiction either, the policy is unchecked from every direction.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P485.

## Related

- **P485** — every step in the process adds and none removes. Same economics one level up: the cheap mechanical checks got built, the expensive semantic one did not.
- **P444** — granular policy choices pass artefact-level ratification unsurfaced. Sibling: that one is about a policy decision nobody saw, this one is about a policy that disagrees with itself once written.
- **P395** — the external-comms agent goes dormant when a policy section is missing. Same family: the policy is load-bearing and under-checked.
- Reported by the maintainer, 2026-08-09, from `voder-mcp-hub`'s `RISK-POLICY.md` § 3.

(captured via /wr-itil:capture-problem; the duplicate-check surfaced twelve keyword matches on policy/appetite/control, none of which is this: they concern a missing policy section, agent-prose test harnesses, and unsurfaced design decisions respectively.)
