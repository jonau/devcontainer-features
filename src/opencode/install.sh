#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_TEMPLATE="${CONFIGTEMPLATE:-"{}"}"
INSTALL_HELPERS="${INSTALLHELPERSCRIPTS:-"true"}"
REQUESTED_VERSION="${OPENCODEVERSION:-"latest"}"

OPENCODE_BIN_DIR="/usr/local/bin"
OPENCODE_SHARE_DIR="/usr/local/share/opencode"

_apt_updated="false"

log_info() {
    echo "[opencode-feature] $*"
}

ensure_packages() {
    if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg >/dev/null 2>&1; then
        return
    fi

    local missing=()
    for pkg in "$@"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        return
    fi

    if [ "${_apt_updated}" != "true" ]; then
        apt-get update -y
        _apt_updated="true"
    fi

    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
}

detect_user() {
    local user="${USERNAME:-automatic}"
    if [ "$user" = "automatic" ] || [ "$user" = "" ]; then
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

ensure_packages curl ca-certificates tar

lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

detect_arch() {
    local machine
    machine="$(uname -m)"
    case "$machine" in
        x86_64|amd64)
            echo "x64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

is_musl() {
    if [ -f /etc/alpine-release ]; then
        return 0
    fi
    if command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; then
        return 0
    fi
    return 1
}

needs_baseline_build() {
    if [ "$(detect_arch)" != "x64" ]; then
        return 1
    fi
    if grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
        return 1
    fi
    return 0
}

resolve_version() {
    local requested="$1"
    if [ -z "$requested" ] || [ "$requested" = "latest" ]; then
        local latest
        latest="$(curl -fsSL https://api.github.com/repos/anomalyco/opencode/releases/latest | sed -n 's/.*"tag_name": *"v\([^" ]*\)".*/\1/p' | head -n 1)"
        if [ -z "$latest" ]; then
            echo ""
            return 1
        fi
        echo "$latest"
    else
        echo "${requested#v}"
    fi
}

download_opencode() {
    local version="$1"
    local arch target filename url tmp_dir

    arch="$(detect_arch)"
    if [ "$arch" = "unsupported" ]; then
        log_info "Unsupported architecture: $(uname -m)"
        exit 1
    fi

    target="linux-$arch"
    if needs_baseline_build; then
        target="$target-baseline"
    fi
    if is_musl; then
        target="$target-musl"
    fi

    filename="opencode-${target}.tar.gz"
    url="https://github.com/anomalyco/opencode/releases/download/v${version}/${filename}"

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT

    log_info "Downloading OpenCode ${version} (${target})"
    curl -fsSL -o "$tmp_dir/$filename" "$url"

    tar -xzf "$tmp_dir/$filename" -C "$tmp_dir"
    install -m 0755 "$tmp_dir/opencode" "$OPENCODE_BIN_DIR/opencode"

    rm -rf "$tmp_dir"
    trap - EXIT
}

install_helper_scripts() {
    local normalized
    normalized="$(lower "$INSTALL_HELPERS")"
    if [ "$normalized" = "true" ] || [ "$normalized" = "1" ] || [ "$normalized" = "yes" ]; then
        install -m 0755 "$SCRIPT_DIR/assets/opencode-template" "$OPENCODE_BIN_DIR/opencode-template"
    fi
}

write_template_store() {
    mkdir -p "$OPENCODE_SHARE_DIR"
    printf '%s\n' "$CONFIG_TEMPLATE" > "$OPENCODE_SHARE_DIR/default-config.json"
    chmod 0644 "$OPENCODE_SHARE_DIR/default-config.json"
}

ensure_opencode_config() {
    local user="$1"
    if ! id -u "$user" >/dev/null 2>&1; then
        return
    fi

    local home config_dir config_file
    home="$(eval echo "~$user")"
    config_dir="$home/.config/opencode"
    config_file="$config_dir/opencode.json"

    mkdir -p "$config_dir"
    chown "$user":"$user" "$config_dir"

    if [ ! -f "$config_file" ]; then
        log_info "No user config mounted, creating minimal fallback for $user"
        printf '%s\n' "$CONFIG_TEMPLATE" > "$config_file"
        chmod 600 "$config_file"
        chown "$user":"$user" "$config_file"
    fi
}

main() {
    install -d "$OPENCODE_BIN_DIR"

    local resolved_version
    resolved_version="$(resolve_version "$REQUESTED_VERSION")"
    if [ -z "$resolved_version" ]; then
        echo "Failed to determine which OpenCode version to install" >&2
        exit 1
    fi

    download_opencode "$resolved_version"
    install_helper_scripts
    write_template_store

    ensure_opencode_config root
    ensure_opencode_config "$(detect_user)"

    log_info "OpenCode CLI installation complete"
}

main "$@"
