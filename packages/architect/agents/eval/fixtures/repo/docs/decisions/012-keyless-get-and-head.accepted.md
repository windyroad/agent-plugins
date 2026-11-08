---
status: accepted
human-oversight: confirmed
---

# Decision 012: Omit key capabilities from GET and HEAD request contexts

Synthetic decision for the isolated authorization callback review fixture.

## Decision Outcome

GET and HEAD request contexts have neither keys nor decryption capabilities.
The existing authorized integration command performs credential operations
outside those contexts under its own authorization policy.

This decision sets the credential boundary. It does not choose how work
reaches the command.
