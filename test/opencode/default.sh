#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

CONFIG_FILE="$HOME/.config/opencode/opencode.json"

check "custom template applied" bash -c "grep -q '\"testing\": true' \"$CONFIG_FILE\""
check "helper prints template" bash -c "opencode-template | grep -q '\"testing\": true'"

reportResults
