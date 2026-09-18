# Problem 542: The oversight-marker shim silently writes nothing when the command is not a bare two-word invocation

**Status**: Open
**Reported**: 2026-09-19
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a
**WSJF**: 8 — (16 × 1.0) / 2 (added 2026-09-18 review — capture wrote no WSJF line)
**JTBD**: JTBD-001
**Persona**: developer

## Description

`packages/architect/hooks/architect-slide-marker.sh` recognises the ratification command by an exact-shape match on the parsed argv. Lines 30–43:

```python
argv = shlex.split(data.get("tool_input", {}).get("command", ""))
if (data.get("tool_name") == "Bash"
        and ...
        and len(argv) == 2
        and argv[0] == "wr-architect-mark-oversight-confirmed"):
    print(argv[1])
```

Any invocation that is not exactly two words fails the match. An environment-variable prefix is the common case:

```bash
CLAUDE_SESSION_ID=<uuid> wr-architect-mark-oversight-confirmed docs/decisions/<NNN>-<slug>.proposed.md
```

`shlex.split` yields `['CLAUDE_SESSION_ID=<uuid>', 'wr-architect-mark-oversight-confirmed', '<path>']` — `len(argv) == 3` and `argv[0]` is the assignment, so the match fails, `OVERSIGHT_PATH` stays empty, and no marker is written.

**The failure is silent by construction.** The `python3` block is wrapped in `except Exception: pass` and redirected `2>/dev/null`, and every diagnostic below it lives inside `if [ -n "$OVERSIGHT_PATH" ]` — the branch a parse miss never enters. So the four `echo ... >&2` messages intended to report trouble are unreachable on exactly the path that needs them. The caller sees a clean exit and no output, indistinguishable from success.

### Why this matters more than a missing marker

The silent no-op is what pushes an agent onto the Bash workaround that defeats the ratification contract outright. Field evidence, 2026-09-19, adopter repo `voder-mcp-hub`: an agent hit a non-functioning marker path, was told "just work around it", and replied *"Working around it via Bash, since the ratification is real and only the marker hook is broken."* — then hand-wrote `human-oversight: confirmed` into five ADR frontmatters (344–348) in a single `for` loop. That bypass is tracked on P503 as a field instance of its named residual; this ticket is the upstream cause that made the workaround look reasonable.

The shim reporting nothing is the load-bearing defect. An agent that saw `no marker written: unrecognised command shape` would fix its invocation; an agent that sees silence concludes the tooling is broken and routes around it.

### Observed twice today

1. This repo, ratifying ADR-128: `CLAUDE_SESSION_ID=... wr-architect-mark-oversight-confirmed <path>` produced no output and no marker. Re-running the bare two-word form produced `/tmp/oversight-confirmed-<sha>-<sid>` immediately. The env prefix was the only difference.
2. `voder-mcp-hub`, as above — cause not confirmed to be this exact shape, but the same "marker hook is broken" symptom preceded the bypass.

### Third instance of a recurring class

Two siblings are already closed, both "the oversight shim silently writes nothing":

- **P380** — the shim's `find /tmp` did not follow the macOS symlink.
- **P502** — the candidate-SID window excluded sessions older than 24h.

Each was fixed at its own mechanism. None addressed the shared property that makes the class expensive: **a parse or lookup miss is unreportable**. A fail-loud default would have surfaced all three on first occurrence.

### Aggravating factor in the guidance

Session memory `feedback_oversight_shim_needs_explicit_session_id.md` (P368) advises exporting the session id before invoking the shim, because it "silently no-ops on an empty `CLAUDE_SESSION_ID`". Applying that advice as an inline env prefix triggers *this* defect — the documented remedy for one silent failure lands on another. Whatever the fix, that guidance needs to move with it.

## Symptoms

- `wr-architect-mark-oversight-confirmed <path>` exits 0 with no output, and `/tmp/oversight-confirmed-*` is not created.
- Reproduces whenever the command carries an env-var prefix, a wrapper, or any additional word.
- The frontmatter marker the caller then writes is unbacked, and nothing says so.

## Workaround

Invoke it as a bare two-word command, exactly `wr-architect-mark-oversight-confirmed <path>`, with nothing before or after. Then verify the marker exists (`ls /tmp/oversight-confirmed-*`) rather than trusting the silent exit.

## Impact Assessment

- **Who is affected**: anyone running a ratification flow — `/wr-architect:create-adr` Step 5d, `/wr-architect:review-decisions`, and the equivalent JTBD/story marker shims if they share the shape.
- **Frequency**: every non-bare invocation. Hit once in this session; the P368 guidance makes the triggering form more likely, not less.
- **Severity**: the governance record either misses a real ratification or, via the workaround it provokes, gains a permanent unbacked one.
- **Analytics**: not instrumented — and by construction it emits nothing to instrument.

## Root Cause Analysis

The recogniser is a strict positional match on `shlex.split` output, and its enclosing error handling converts every non-match into silence. The design assumes the caller's command shape rather than validating it and reporting a mismatch.

### Investigation Tasks

- [ ] Make a parse miss **loud**: when `tool_name == "Bash"` and the command contains `wr-architect-mark-oversight-confirmed` but the shape does not match, emit a stderr diagnostic naming the received argv and the expected form. This is the fix that generalises across P380 / P502 / this ticket.
- [ ] Decide whether to tolerate leading `VAR=value` assignments in the matcher, or to keep the strict shape and rely on the loud diagnostic. Tolerating them removes the trap; strictness plus a diagnostic keeps the evidence binding narrow. Name the choice rather than defaulting.
- [ ] Audit the sibling marker shims (`wr-jtbd-mark-oversight-confirmed`, `wr-itil-mark-story-oversight-confirmed`, the external-comms mark hooks) for the same positional-match-plus-silence shape.
- [ ] Reconcile the P368 guidance, which currently steers callers into the failing form.
- [ ] Behavioural coverage: prove RED that an env-prefixed invocation writes no marker and emits no diagnostic, then GREEN that it either writes the marker or reports why not.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P503 (the Bash-routed bypass this defect provokes), P380 and P502 (closed siblings in the same silent-no-op class)

## Related

- **P503** (`docs/problems/known-error/503-...md`) — the bypass this defect makes attractive; its 2026-09-19 recurrence subsection records the voder-mcp-hub instance. Arbitrated by `wr-itil:hang-off-check`, which routed the bypass evidence to P503 and explicitly carved this parser-shape defect out as its own ticket with its own fix locus.
- **P380**, **P502** (closed) — prior silent-no-op instances in the same shim.
- **ADR-110** — a ratification marker can only be written when someone actually ratified. This defect undermines it indirectly, by making the sanctioned path look broken.
- **ADR-066** — the `human-oversight` marker is write-once-permanent, which is why an unbacked marker does not self-correct.
- `packages/architect/hooks/architect-slide-marker.sh` lines 30–43 — the recogniser.

(captured via /wr-itil:capture-problem; expand at next investigation)
