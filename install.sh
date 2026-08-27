#!/bin/bash
set -e

# OpenCode Termux Installer
# https://github.com/Yinyuan34513/opencode-termux

REPO="Yinyuan34513/opencode-termux"
RELEASE_TAG="v1.18.23-termux"
INSTALL_DIR="${HOME}/opencode"
PROXY="https://v4.gh-proxy.org"
GITHUB="https://github.com"

# Check if direct GitHub access works
check_github() {
    if curl -s --connect-timeout 5 --max-time 10 "https://github.com" >/dev/null 2>&1; then
        BASE_URL="$GITHUB"
    else
        echo "⚠️  Direct GitHub connection failed, using proxy: $PROXY"
        BASE_URL="$PROXY/$GITHUB"
    fi
}

# Detect platform
detect_platform() {
    if [ -n "$TERMUX_VERSION" ] || [ -n "$PREFIX" ] && echo "$PREFIX" | grep -q "com.termux"; then
        echo "termux"
    elif [ "$(uname -s)" = "Linux" ]; then
        echo "linux-$(uname -m)"
    elif [ "$(uname -s)" = "Darwin" ]; then
        echo "darwin-$(uname -m)"
    else
        echo "unknown"
    fi
}

# Check dependencies
check_deps() {
    local missing=""
    for cmd in curl tar; do
        if ! command -v "$cmd" &>/dev/null; then
            missing="$missing $cmd"
        fi
    done
    if [ -n "$missing" ]; then
        echo "Missing dependencies:$missing"
        if command -v pkg &>/dev/null; then
            echo "Installing with pkg..."
            pkg install -y curl tar zstd
        elif command -v apt &>/dev/null; then
            echo "Installing with apt..."
            apt update && apt install -y curl tar zstd
        elif command -v brew &>/dev/null; then
            echo "Installing with brew..."
            brew install curl tar zstd
        else
            echo "Please install manually: curl tar zstd"
            exit 1
        fi
    fi
}

# Download and install
install_opencode() {
    local platform=$(detect_platform)
    echo "Detected platform: $platform"

    mkdir -p "$INSTALL_DIR"

    if [ "$platform" = "termux" ]; then
        echo "Installing OpenCode for Termux/Android..."

        # Download standalone binary (zstd compressed)
        echo "Downloading opencode binary..."
        curl -L "${BASE_URL}/${REPO}/releases/download/${RELEASE_TAG}/opencode-termux" \
            -o "/tmp/opencode-termux.zst"

        # Decompress
        if command -v zstd &>/dev/null; then
            zstd -d -f "/tmp/opencode-termux.zst" -o "$INSTALL_DIR/opencode"
        else
            echo "Warning: zstd not found, trying to install..."
            pkg install -y zstd 2>/dev/null && zstd -d -f "/tmp/opencode-termux.zst" -o "$INSTALL_DIR/opencode"
        fi
        rm -f "/tmp/opencode-termux.zst"
        chmod +x "$INSTALL_DIR/opencode"

        echo "Installed to: $INSTALL_DIR/opencode"
        echo ""
        echo "Run with:"
        echo "  $INSTALL_DIR/opencode"
        echo ""
        echo "Or add to PATH:"
        echo "  export PATH=\"\$HOME/opencode:\$PATH\""
        echo "  opencode"

    else
        echo "Installing OpenCode for $platform..."

        # Check if platform-specific release exists, fallback to Termux bundle
        local filename="opencode-${platform}.tar.zst"
        local url="${BASE_URL}/${REPO}/releases/download/${RELEASE_TAG}/${filename}"
        if ! curl -sf --connect-timeout 5 --max-time 10 -o /dev/null "$url" 2>/dev/null; then
            echo "No pre-built binary for $platform, using Termux bundle..."
            filename="opencode-termux-aarch64.tar.zst"
        fi

        echo "Downloading $filename..."
        curl -L "${BASE_URL}/${REPO}/releases/download/${RELEASE_TAG}/${filename}" \
            -o "/tmp/${filename}"

        echo "Extracting..."
        if command -v zstd &>/dev/null; then
            tar xf "/tmp/${filename}" --zstd -C "$INSTALL_DIR"
        else
            tar xf "/tmp/${filename}" -C "$INSTALL_DIR"
        fi
        rm -f "/tmp/${filename}"

        echo "Installed to: $INSTALL_DIR"
        echo ""
        echo "Run with:"
        echo "  $INSTALL_DIR/opencode-termux-release/opencode"
    fi
}

# Main
echo "=== OpenCode Installer ==="
echo ""
check_github
check_deps
install_opencode
echo ""
echo "Done! 🎉"
