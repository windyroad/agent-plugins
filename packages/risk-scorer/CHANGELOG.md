# @windyroad/risk-scorer

## 0.1.3

### Patch Changes

- eda2a15: Fix release preview to use pre-release versions (e.g., 0.1.2-preview.42) instead of exact release versions, preventing version collision with changeset publish.

## 0.1.2

### Patch Changes

- a4cbfd9: Fix misleading error messages in risk-gate.sh that said the risk-scorer "runs automatically on each prompt". It doesn't — the agent must explicitly delegate to wr-risk-scorer:pipeline.

## 0.1.1

### Patch Changes

- 3833199: Fix: bundle shared install utilities into each package so bin scripts work when installed via npx.
