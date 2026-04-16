---
"@windyroad/itil": patch
---

fix(manage-problem): add Parked lifecycle status and README.md fast-path cache (closes P027)

- Adds `.parked.md` suffix and Parked status to problem lifecycle table
- `problem work` checks README.md freshness before triggering full 18-file re-scan
- Step 9e writes/overwrites `docs/problems/README.md` after every full re-rank
- Parked problems excluded from WSJF ranking; shown in separate Parked table
