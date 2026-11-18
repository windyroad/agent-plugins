#!/bin/bash

# Both runtime completion paths use the same bounded, unquoted-heading contract.
_ARCHITECT_VERDICT_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
architect_verdict() {
  python3 "$_ARCHITECT_VERDICT_LIB/architect-verdict.py"
}
