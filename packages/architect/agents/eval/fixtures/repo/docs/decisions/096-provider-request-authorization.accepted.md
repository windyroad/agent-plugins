---
status: accepted
human-oversight: confirmed
---

# ADR-096: Use the provider's authorization decision when recording its response

Synthetic decision for the isolated wallet review fixture.

## Decision Outcome

The provider authorizes consent for its request. The wallet records the
authorized response it receives, including a response returned after consent
withdrawal if the provider accepted the request before withdrawal. A provider
denial produces no observation. The wallet enforces tenant isolation and read
authorization for its stored observations. Existing retention and erasure
rules continue to govern observations after capture.
