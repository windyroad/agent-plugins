---
"@windyroad/risk-scorer": patch
---

P164 Phase 2: force base-10 in the risk-extractor next-ID formula to prevent an octal-eval failure at the `008 → 009` ID boundary.

`scripts/extract-risks-from-reports.sh` allocated the next risk ID with `NEXT_ID=$(( ${LOCAL_MAX:-0} + 1 ))`. When `LOCAL_MAX` carries a zero-padded id such as `008`, bash's `$(( ... ))` arithmetic context reads the leading zero as octal; `008` is an invalid octal literal (digit ≥ 8), so bash emits `bash: 008: value too great for base` and the script exits before minting the entry. The line now uses the standard base-10 prefix — `NEXT_ID=$(( 10#${LOCAL_MAX:-0} + 1 ))`.

This is the script-surface sibling of the Phase 1 fix (the same octal-eval defect across six ticket-creator SKILL.md formulas, already shipped). Phase 1's `$(( $(echo` survey pattern did not match this simpler no-pipe shape. A repo-wide survey of every `$(( ... ))` over a zero-padded ID string confirms this was the only remaining vulnerable surface; the loop-counter increment on the next line operates on a clean decimal integer and needs no prefix. A behavioural test exercises the `008 → 009` boundary against the synthetic fixture. Refs: P164.
