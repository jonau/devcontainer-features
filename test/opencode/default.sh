#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "helper prints template" bash -c "opencode-template | grep -q '"testing": true'"

reportResults
