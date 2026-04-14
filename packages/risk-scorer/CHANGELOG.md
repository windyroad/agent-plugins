# @windyroad/risk-scorer

## 0.1.5

### Patch Changes

- b12e7c0: Fix misleading error messages in release gate: drift now clearly instructs "re-run risk-scorer", score-too-high retains "split/reduce/incident" guidance inline. Remove generic suffix in git-push-gate that conflated the two cases.

## 0.1.4

### Patch Changes

- 7ee97ba: Add README.md to every package and rewrite the root README with better engagement, problem statement, and project-scoped install documentation.
- eb47a86: Improve git-push-gate hook to detect missing release:watch script and guide the agent to create one instead of directing to a non-existent command.

## 0.1.3

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.2

### Patch Changes

- a4cbfd9: Fix misleading error messages in risk-gate.sh that said the risk-scorer "runs automatically on each prompt". It doesn't — the agent must explicitly delegate to wr-risk-scorer:pipeline.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
