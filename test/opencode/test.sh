#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "opencode version" bash -c "opencode --version"
check "config file exists" bash -c "[ -f \"$HOME/.config/opencode/opencode.json\" ]"
check "template helper" bash -c "opencode-template | grep -q '{'"

reportResults
