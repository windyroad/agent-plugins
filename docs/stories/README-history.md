## 2026-05-12

> Last reviewed: 2026-05-12 — **Scaffolded.** Directory + lifecycle subdirs created; encoding stays markdown per ADR-060 amendment 2026-05-12 (HTML reserved for story-maps; stories are 1D INVEST cards). Skills (`/wr-itil:capture-story`, `/manage-story`, `/reconcile-stories`, `/list-stories`) land in P170 Phase 2 Slice 4. Bootstrap stories (extracted from `docs/plans/170-rfc-framework-story-map.md` slices) land in P170 Phase 2 Slice 8.

## 2026-07-03

> Last reviewed: 2026-07-03 — **STORY-020/021/022/024/025 accepted** — RFC-037 Phase-2 cohort transitioned draft→accepted (INVEST gate I7 RFC-005 + I8 STORY-MAP-002 + I10 shape all passed); ready for implementation. Rankings-table build + parent reverse-trace deferred to a reconcile pass (README is scaffold-state; STORY-MAP-002 is HTML).

## 2026-07-09

> Last reviewed: 2026-07-03 **STORY-020/021/022/024/025 done** — RFC-037's five tooling stories implemented, ratified, and transitioned to done (all acceptance criteria met).

## 2026-07-11

> Last reviewed: 2026-07-09 **STORY-042 accepted** — quota-pacing extraction passes I7 (RFC-046) / I8 (STORY-MAP-003) / I10 INVEST; Rankings table backfilled with active stories from FS truth (Done-table backfill still outstanding — run `/wr-itil:manage-story review`). RFC-046 Release-2 build begins.
> Last reviewed: 2026-07-11 **STORY-043 accepted** — self-installing quota-state producer passes I7/I8/I10; built + 7 green bats (create-and-wire when absent / no-op when producing / agent-merge never blind-append). Kill-switch retired (disable via `max_sleep_s: 0`). Closes RFC-046 Release 2's functional scope.
> Last reviewed: 2026-07-11 **STORY-042/043 → in-progress, STORY-039 → archived, RFC-046 → in-progress** — RFC-046 Release 2 fully built (throttle self-calibrating fix + extraction + self-installer, 19 cruise bats incl. concurrency); STORY-039 superseded. Awaiting release (changeset) → then done/verifying.

## 2026-07-26

> Last reviewed: 2026-07-12 **STORY-044 accepted** — cruise status/telemetry skill (`/wr-cruise:status`): per-window pace vs usage, the sleep the throttle is injecting now, glide projection, cache-health (flags an inert fail-open throttle). Built + 7 bats (29 cruise bats total). Awaiting release.

## 2026-08-29

> Last reviewed: 2026-08-29 **index reconciled** — STORY-068 added at `accepted` for the single-prefix Codex skill name; reverse traces are present on P527, JTBD-302, and RFC-074's release row on STORY-MAP-008.

> Last reviewed: 2026-08-29 **index reconciled** — STORY-069 added at `accepted` for one isolated Codex CLI iteration; reverse traces are present on P529, JTBD-006, and RFC-075's release row on STORY-MAP-002.

> Last reviewed: 2026-08-29 **index reconciled** — STORY-070 added at `accepted` for the Codex persisted-Goal loop anchor; reverse traces are present on P528, JTBD-006, and RFC-076's release row on STORY-MAP-011.
