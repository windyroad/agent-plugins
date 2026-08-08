---
status: draft
story-id: get-the-fix-by-upgrading-not-by-patching-a-cache
reported: 2026-08-09
decision-makers: [Tom Howard]
problems: [P369]
jtbd: [JTBD-303, JTBD-101]
story-maps: [STORY-MAP-008]
estimated-effort: M
---

# STORY-057: Get the fix by upgrading, not by patching a cache

## User value (INVEST Valuable)

In order to trust that upgrading is how I get a fix, as a developer running a plugin that has just shipped one, I want the upgrade to actually take effect in my session — so I am not editing files inside a plugin cache to work around something already fixed upstream.

## Acceptance criteria (INVEST Testable)

- [ ] A hook the plugin has retired stops being invoked. When a file is removed in a new version, a session holding the old binding fails on a path that no longer exists, and the error names a file the adopter never wrote.
- [ ] The failure, if it can still happen, says what to do. A message naming an absolute path inside a plugin cache tells the reader nothing about the remedy; it reads as the plugin being broken rather than the session being stale.
- [ ] Upgrading is sufficient. No step in the remedy asks the adopter to edit, delete, or patch anything under the plugin cache — that is the thing this story exists to remove.
- [ ] Behavioural test: a fixture that retires a hook and then invokes the surface which bound it either succeeds or fails with a message naming the upgrade, not the cache path.

## Notes

The card this story backs sits in the `fixed` activity of STORY-MAP-008 — the last step of the journey, where an adopter finds out whether the plugin behaves like a guest when it changes.

P369 is the recorded instance, and the reporting is the evidence of the harm: *"you've got bad paths again. I thought we put controls in place to prevent this!!!"* The fix had shipped. The adopter's session was still invoking the retired file by an absolute cache path, so from where they stood the plugin was broken and the only visible move was to go into the cache themselves.
