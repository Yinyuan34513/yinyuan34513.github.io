#!/bin/bash

# Termux AI Tool Installer
# https://github.com/Yinyuan34513/opencode-termux

REPO="Yinyuan34513/opencode-termux"
RELEASE_TAG="v1.18.23-termux"
PROXY="https://v4.gh-proxy.org"
GITHUB="https://github.com"

# TUI helpers
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
BG_BLUE='\033[44m'
FG_WHITE='\033[97m'
FG_GREEN='\033[92m'
FG_GRAY='\033[90m'

selected=1
total=3

draw_menu() {
    local items=("OpenCode" "AtomCode" "Exit")
    local descs=("AI coding agent with full TUI" "AI coding CLI for Android")
    local icons=(">" ">" ">")
    local w=44

    printf "\033[H\033[J"
    printf "\n"
    printf "  ┌─%s─┐\n" "$(printf '─%.0s' $(seq 1 $w))"
    printf "  │%*s%*s│\n" $(( (w+12)/2 )) "Termux AI Tools" $(( (w+12)/2 - w )) ""
    printf "  ├─%s─┤\n" "$(printf '─%.0s' $(seq 1 $w))"
    printf "  │%*s│\n" $((w+12)) ""
    for i in 1 2 3; do
        if [ $i -eq $selected ]; then
            printf "  │  ${BG_BLUE}${FG_WHITE}${BOLD}  ▸ %-40s${RESET}  │\n" "${items[$((i-1))]}"
        else
            printf "  │  ${DIM}    %-40s${RESET}  │\n" "${items[$((i-1))]}"
        fi
    done
    printf "  │%*s│\n" $((w+12)) ""
    printf "  ├─%s─┤\n" "$(printf '─%.0s' $(seq 1 $w))"
    printf "  │  ${FG_GRAY}↑↓ Navigate  Enter Select  q Quit${RESET}%*s│\n" $((w-22)) ""
    printf "  └─%s─┘\n" "$(printf '─%.0s' $(seq 1 $w))"
    printf "\n"
}

check_github() {
    if curl -s --connect-timeout 5 --max-time 10 "https://github.com" >/dev/null 2>&1; then
        BASE_URL="$GITHUB"
    else
        printf "  ⚠️  Using proxy: $PROXY\n"
        BASE_URL="$PROXY/$GITHUB"
    fi
}

detect_platform() {
    if [ -n "$TERMUX_VERSION" ] || [ -n "$PREFIX" ] && echo "$PREFIX" | grep -q "com.termux"; then
        echo "termux"
    else
        echo "unknown"
    fi
}

install_opencode() {
    local platform=$(detect_platform)
    if [ "$platform" != "termux" ]; then
        echo "  Only Termux/Android supported."
        return 1
    fi

    local tmpdir="${TMPDIR:-$HOME}"
    mkdir -p "$tmpdir"

    printf "\n  ${BOLD}Downloading OpenCode...${RESET}\n"
    curl -L --progress-bar "${BASE_URL}/${REPO}/releases/download/${RELEASE_TAG}/opencode-termux-full.tar.zst" \
        -o "${tmpdir}/opencode-full.tar.zst"

    printf "  ${BOLD}Extracting...${RESET}\n"
    if command -v zstd &>/dev/null; then
        tar xf "${tmpdir}/opencode-full.tar.zst" --zstd -C "$HOME"
    else
        pkg install -y zstd 2>/dev/null
        tar xf "${tmpdir}/opencode-full.tar.zst" --zstd -C "$HOME"
    fi
    rm -f "${tmpdir}/opencode-full.tar.zst"
    chmod +x "$HOME/opencode-termux/opencode" "$HOME/opencode-termux/opencode.sh"

    printf "\n  ${FG_GREEN}${BOLD}✓ Installed to ~/opencode-termux/${RESET}\n"
    printf "  Run: ${BOLD}~/opencode-termux/opencode.sh${RESET}\n"
}

install_atomcode() {
    local platform=$(detect_platform)
    if [ "$platform" != "termux" ]; then
        echo "  Only Termux/Android supported."
        return 1
    fi

    local tmpdir="${TMPDIR:-$HOME}"
    mkdir -p "$tmpdir"

    printf "\n  ${BOLD}Downloading AtomCode...${RESET}\n"
    curl -L --progress-bar "${BASE_URL}/${REPO}/releases/download/${RELEASE_TAG}/atomcode" \
        -o "${tmpdir}/atomcode"

    chmod +x "${tmpdir}/atomcode"
    mkdir -p "$HOME/.local/bin"
    mv "${tmpdir}/atomcode" "$HOME/.local/bin/atomcode"

    printf "\n  ${FG_GREEN}${BOLD}✓ Installed to ~/.local/bin/atomcode${RESET}\n"
    printf "  Run: ${BOLD}~/atomcode${RESET}\n"
}

# Setup terminal
stty_old=$(stty -g 2>/dev/null || true)
printf "$HIDE_CURSOR"
trap 'printf "$SHOW_CURSOR"; stty "$stty_old" 2>/dev/null; exit' INT TERM

while true; do
    draw_menu
    read -rsn1 key

    case "$key" in
        $'\x1b')
            read -rsn2 key2
            case "$key2" in
                '[A') [ $selected -gt 1 ] && selected=$((selected-1)) ;;
                '[B') [ $selected -lt $total ] && selected=$((selected+1)) ;;
            esac
            ;;
        '')
            case $selected in
                1) check_github; install_opencode ;;
                2) check_github; install_atomcode ;;
                3) printf "$SHOW_CURSOR"; exit 0 ;;
            esac
            echo ""
            read -p "  Press Enter to continue..."
            ;;
        q|Q) printf "$SHOW_CURSOR"; exit 0 ;;
    esac
done
