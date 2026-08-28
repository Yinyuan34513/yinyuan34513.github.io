#!/bin/bash

# Termux AI Tool Installer
# https://github.com/Yinyuan34513/opencode-termux
# Usage: curl -sL https://yinyuan34513.github.io/install.sh | bash

REPO="Yinyuan34513/opencode-termux"
RELEASE_TAG="v1.18.23-termux"
PROXY="https://v4.gh-proxy.org"
GITHUB="https://github.com"

# If stdin is a pipe (curl | bash), re-exec with terminal stdin
if [ ! -t 0 ]; then
    tmpscript=$(mktemp "${TMPDIR:-$HOME}/install-XXXXX.sh")
    curl -sL "https://yinyuan34513.github.io/install.sh" -o "$tmpscript"
    chmod +x "$tmpscript"
    exec bash "$tmpscript" < /dev/tty
fi

# Colors
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
BG='\033[44m'
FG_W='\033[97m'
FG_G='\033[92m'
FG_GY='\033[90m'

selected=1
total=3

draw() {
    local names=("OpenCode" "AtomCode" "Exit")
    local w=44
    printf "\033[H\033[J\033[?25l"
    printf "\n"
    printf "  ┌─%s─┐\n" "$(printf '─%.0s' $(seq 1 $w))"
    printf "  │%*s%*s│\n" $((w/2+6)) "Termux AI Tools" $((w/2+6-14)) ""
    printf "  ├─%s─┤\n" "$(printf '─%.0s' $(seq 1 $w))"
    printf "  │%*s│\n" $((w+12)) ""
    for i in 1 2 3; do
        if [ $i -eq $selected ]; then
            printf "  │  ${BG}${FG_W}${BOLD}  ▸ %-40s${RESET}  │\n" "${names[$((i-1))]}"
        else
            printf "  │  ${DIM}    %-40s${RESET}  │\n" "${names[$((i-1))]}"
        fi
    done
    printf "  │%*s│\n" $((w+12)) ""
    printf "  ├─%s─┤\n" "$(printf '─%.0s' $(seq 1 $w))"
    printf "  │  ${FG_GY}↑↓ Navigate  Enter Select  q Quit${RESET}%*s│\n" $((w-22)) ""
    printf "  └─%s─┘\n" "$(printf '─%.0s' $(seq 1 $w))"
}

check_github() {
    if curl -s --connect-timeout 5 --max-time 10 "https://github.com" >/dev/null 2>&1; then
        BASE_URL="$GITHUB"
    else
        printf "  Using proxy: $PROXY\n"
        BASE_URL="$PROXY/$GITHUB"
    fi
}

is_termux() {
    [ -n "$TERMUX_VERSION" ] || { [ -n "$PREFIX" ] && echo "$PREFIX" | grep -q "com.termux"; }
}

install_opencode() {
    is_termux || { echo "  Termux only."; return 1; }
    local tmp="${TMPDIR:-$HOME}"
    mkdir -p "$tmp"
    printf "\n  ${BOLD}Downloading OpenCode...${RESET}\n"
    curl -L --progress-bar "${BASE_URL}/${REPO}/releases/download/${RELEASE_TAG}/opencode-termux-full.tar.zst" \
        -o "${tmp}/oc.tar.zst"
    printf "  ${BOLD}Extracting...${RESET}\n"
    command -v zstd &>/dev/null || pkg install -y zstd 2>/dev/null
    tar xf "${tmp}/oc.tar.zst" --zstd -C "$HOME"
    rm -f "${tmp}/oc.tar.zst"
    chmod +x "$HOME/opencode-termux/opencode" "$HOME/opencode-termux/opencode.sh"
    printf "\n  ${FG_G}${BOLD}✓ Installed to ~/opencode-termux/${RESET}\n"
    printf "  Run: ${BOLD}~/opencode-termux/opencode.sh${RESET}\n"
}

install_atomcode() {
    is_termux || { echo "  Termux only."; return 1; }
    local tmp="${TMPDIR:-$HOME}"
    mkdir -p "$tmp"
    printf "\n  ${BOLD}Downloading AtomCode...${RESET}\n"
    curl -L --progress-bar "${BASE_URL}/${REPO}/releases/download/${RELEASE_TAG}/atomcode" \
        -o "${tmp}/atomcode"
    chmod +x "${tmp}/atomcode"
    mkdir -p "$HOME/.local/bin"
    mv "${tmp}/atomcode" "$HOME/.local/bin/atomcode"
    printf "\n  ${FG_G}${BOLD}✓ Installed to ~/.local/bin/atomcode${RESET}\n"
    printf "  Run: ${BOLD}atomcode${RESET}\n"
}

cleanup() { printf "\033[?25h"; }
trap cleanup EXIT INT TERM

while true; do
    draw
    IFS= read -rsn1 key
    case "$key" in
        $'\x1b')
            IFS= read -rsn2 k2
            case "$k2" in
                '[A') [ $selected -gt 1 ] && selected=$((selected-1)) ;;
                '[B') [ $selected -lt $total ] && selected=$((selected+1)) ;;
            esac
            ;;
        '')
            case $selected in
                1) check_github; install_opencode ;;
                2) check_github; install_atomcode ;;
                3) exit 0 ;;
            esac
            echo ""
            IFS= read -p "  Press Enter..." _
            ;;
        q|Q) exit 0 ;;
    esac
done
