# R008: Credentials / secrets in committed files

A file being edited or written contains a credential — API key, auth token, private key, OAuth secret, `.env` value, signed JWT, password — that ends up committed to git. Once the commit is pushed, the credential is in git history indefinitely; rotation is the only remediation (filter-branch / force-push only removes from the head, not from clones, mirrors, or third-party scrapers that hit the public repo). Distinct from R001 (confidential disclosure in **outbound prose** the agent drafts) — this class is **content entering git via Edit/Write**, regardless of whether prose was drafted.

## Inherent risk

Per `RISK-POLICY.md` (without controls):

- **Impact**: 5 (Severe) — `RISK-POLICY.md` L65: "leaks npm auth tokens via CI logs" is the canonical Severe instance. Committed credentials in a public repo trigger mandatory rotation (financial impact for cloud API keys; security impact for auth tokens; reputational impact across the board).
- **Likelihood**: 3 (Possible) — without controls, accidental commit is common via test fixtures, debugging artefacts, copy-pasted config from local dev.
- **Inherent score**: 15
- **Inherent band**: High

## Residual risk

Per `RISK-POLICY.md` `## Control Composition`:

- **Likelihood after controls**: 1 (Rare) — three independent paths: `secret-leak-gate.sh` PreToolUse:Edit/Write hook with regex on common secret patterns; `.gitignore` filesystem-level exclusion of credential-bearing file types; CI / pre-receive secret scanning as second-line catch. 3 → 2 → 1 → 1 (capped).
- **Residual score**: 5
- **Residual band**: Medium

**Gap-to-appetite**: residual exceeds appetite (4/Low) because Impact 5 (Severe) means even Rare likelihood produces Medium-band residual. Adding a 4th control path won't drop residual below 5 (the Impact floor caps it). Treatment is therefore: maintain controls AND prepare rotation-runbook so post-incident response is fast (the residual reflects WHEN, not IF — and rotation is the load-bearing post-incident control).

## Controls

- **`packages/risk-scorer/hooks/secret-leak-gate.sh`** — PreToolUse:Edit/Write hook; regex-blocks AWS access keys, PEM-format private keys, GitHub tokens, generic `api_key`/`auth_token`/`secret_key` assignment patterns with high-entropy values, Cloudflare auth keys, Netlify auth tokens. Deny includes the matched class so the agent can rewrite using environment variable / CI secret instead.
- **`.gitignore`** — covers `.env`, `*.pem`, `*.key`, `id_rsa`, etc. for files that should never reach the index.
- **CI / pre-receive secret scanning** (e.g., GitHub Push Protection, gitleaks) — second-line catch if a secret slips past the local hook.
- **`BYPASS_RISK_GATE=1`** — explicit override for false-positives (e.g., a deliberately-fake fixture credential the regex pattern-matches).

## Watch-out

- Test fixtures that include sample credentials are the canonical false-positive — the regex can't tell a deliberately-fake AWS key from a real one. Document the fixture intent in a comment + use the bypass env-var.
- JWTs and audit-log captures sometimes land in committed audit reports unnoticed; the regex catches PEM-bracket key shapes but JWT bodies are higher entropy and may pass.
- This very file initially failed the gate because the description quoted the PEM-bracket pattern verbatim — the gate is sensitive enough that even prose-about-the-gate can trigger it. Lesson: when documenting the control, paraphrase the pattern shape rather than reproduce it.
- Once committed AND pushed, rotation is mandatory regardless of subsequent revert — public repo scrapers will have already pulled the secret.
- Sub-class: a config file (`.env.example`, `config.yaml`) intended to be committed with placeholder values, where the placeholder accidentally retains a real value from local development. The hook may or may not catch depending on entropy of the placeholder.
- Distinct from R001 even when the agent IS drafting the file: R001 is the prose-content-leak class (the agent writes prose that names a confidential thing); R008 is the secret-in-file-content class (the file body has structured credential material).
