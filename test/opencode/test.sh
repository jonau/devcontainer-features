#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

detect_feature_user() {
    local user="${USERNAME:-automatic}"
    if [ "$user" = "automatic" ] || [ -z "$user" ] || [ "$user" = "root" ]; then
        for candidate in vscode node codespace "$(id -un 1000 2>/dev/null || true)"; do
            if [ -n "$candidate" ] && id -u "$candidate" >/dev/null 2>&1; then
                user="$candidate"
                break
            fi
        done
    fi

    if [ "$user" = "automatic" ] || [ "$user" = "none" ] || ! id -u "$user" >/dev/null 2>&1; then
        user="root"
    fi

    echo "$user"
}

resolve_home() {
    local user="$1"
    local home
    home="$(getent passwd "$user" | cut -d: -f6)"
    if [ -z "$home" ]; then
        if [ "$user" = "root" ]; then
            home="/root"
        else
            home="/home/$user"
        fi
    fi
    echo "$home"
}

DEV_USER="$(detect_feature_user)"
DEV_HOME="$(resolve_home "$DEV_USER")"
DEV_CONFIG="$DEV_HOME/.config/opencode/opencode.json"
DEV_CONFIG_DIR="$DEV_HOME/.config/opencode"
DEV_CONFIG_PARENT="$DEV_HOME/.config"
DEV_STATE_PARENT="$DEV_HOME/.local"
DEV_STATE_SHARE="$DEV_STATE_PARENT/share"
DEV_STATE_DIR="$DEV_STATE_SHARE/opencode"
export DEV_USER DEV_CONFIG DEV_STATE_DIR DEV_CONFIG_DIR DEV_CONFIG_PARENT DEV_STATE_PARENT DEV_STATE_SHARE

check "opencode version" bash -c "opencode --version"
check "config file exists" bash -c "[ -f \"$HOME/.config/opencode/opencode.json\" ]"
check "template helper" bash -c "opencode-template | grep -q '{'"
check "dev user config owner" bash -c '[ -f "$DEV_CONFIG" ] && [ "$(stat -c "%U" "$DEV_CONFIG")" = "$DEV_USER" ]'
check "dev user state dir owner" bash -c '[ -d "$DEV_STATE_DIR" ] && [ "$(stat -c "%U" "$DEV_STATE_DIR")" = "$DEV_USER" ]'
check "dev user config dir owner" bash -c '[ -d "$DEV_CONFIG_DIR" ] && [ "$(stat -c "%U" "$DEV_CONFIG_DIR")" = "$DEV_USER" ]'
check "dev user config parent owner" bash -c '[ -d "$DEV_CONFIG_PARENT" ] && [ "$(stat -c "%U" "$DEV_CONFIG_PARENT")" = "$DEV_USER" ]'
check "dev user .local owner" bash -c '[ -d "$DEV_STATE_PARENT" ] && [ "$(stat -c "%U" "$DEV_STATE_PARENT")" = "$DEV_USER" ]'
check "dev user .local/share owner" bash -c '[ -d "$DEV_STATE_SHARE" ] && [ "$(stat -c "%U" "$DEV_STATE_SHARE")" = "$DEV_USER" ]'

reportResults
