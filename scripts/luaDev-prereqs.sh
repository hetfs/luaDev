#!/usr/bin/env bash
# luaDev-prereqs.sh — Cross-platform setup for LuaDev (Linux/macOS)
# Author: Fredaws Lomdo (@hetfs) • Accra, Ghana
# License: MIT • https://github.com/hetfs/luaDev

set -e

# --- Flags ---
DRYRUN=false
MINIMAL=false
ALL=false

for arg in "$@"; do
    case $arg in
    --dry-run) DRYRUN=true ;;
    --minimal) MINIMAL=true ;;
    --all) ALL=true ;;
    esac
done

# --- Setup Logs ---
LOG_DIR="./scripts/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/luaDev-prereqs-$(date +'%Y%m%d-%H%M%S').log"
touch "$LOG_FILE"

log() {
    echo -e "[luaDev] $1" | tee -a "$LOG_FILE"
}

# --- Detect System Package Manager ---
detect_package_manager() {
    if command -v brew &>/dev/null; then
        echo "brew"
    elif command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        log "❌ No supported package manager found"
        exit 1
    fi
}

# --- Detect AUR Helper (Arch) ---
detect_aur_helper() {
    if command -v yay &>/dev/null; then
        echo "yay"
    elif command -v paru &>/dev/null; then
        echo "paru"
    else
        echo "" # No helper
    fi
}

PACKAGE_MANAGER=$(detect_package_manager)
AUR_HELPER=$(detect_aur_helper)

log "🛠 Package manager: $PACKAGE_MANAGER"
[[ "$PACKAGE_MANAGER" == "pacman" && -n "$AUR_HELPER" ]] && log "📦 AUR helper: $AUR_HELPER"

# --- Install Function ---
install_tool() {
    local name="$1"
    local cmd="$2"
    local is_aur="$3"

    if command -v "$cmd" &>/dev/null; then
        log "✅ $name already installed"
        return
    fi

    log "⬇️ Installing $name..."

    if $DRYRUN; then
        log "🔍 [DryRun] Would install: $name"
        return
    fi

    if [[ "$PACKAGE_MANAGER" == "pacman" && "$is_aur" == "aur" ]]; then
        if [[ -n "$AUR_HELPER" ]]; then
            "$AUR_HELPER" -S --noconfirm "$cmd"
        else
            log "⚠️ AUR tool '$cmd' requires yay/paru. Please install manually."
            return
        fi
    else
        case $PACKAGE_MANAGER in
        apt) sudo apt update && sudo apt install -y "$cmd" ;;
        dnf) sudo dnf install -y "$cmd" ;;
        brew) brew install "$cmd" ;;
        pacman) sudo pacman -Sy --noconfirm "$cmd" ;;
        esac
    fi

    if command -v "$cmd" &>/dev/null; then
        log "✅ $name installed"
    else
        log "❌ Failed to install $name"
    fi
}

# --- Define Tools ---
CORE_TOOLS=(
    "Git:git:"
    "CMake:cmake:"
    "LLVM/Clang:clang:"
    "Ninja:ninja:"
    "Python:python:"
    "Rust Toolchain:rustup:"
    "Perl:perl:"
    "direnv:direnv:"
    "git-cliff:git-cliff:aur"
)

EXTRA_TOOLS=(
    "Cppcheck:cppcheck:"
    "Clangd:clangd:"
    "LuaLS:lua-language-server:aur"
    "7-Zip:p7zip:"
    "GNU Make:make:"
)

TOOLS_TO_INSTALL=("${CORE_TOOLS[@]}")
$ALL && TOOLS_TO_INSTALL+=("${EXTRA_TOOLS[@]}")
$MINIMAL && TOOLS_TO_INSTALL=("Git:git:" "CMake:cmake:" "Python:python:" "Rust Toolchain:rustup:")

log "🚀 Starting setup"
$DRYRUN && log "💡 Dry run enabled — no changes made"

# --- Install All Tools ---
for entry in "${TOOLS_TO_INSTALL[@]}"; do
    IFS=':' read -r NAME CMD IS_AUR <<<"$entry"
    install_tool "$NAME" "$CMD" "$IS_AUR"
done

# --- Setup Rust ---
if command -v rustup &>/dev/null && ! $DRYRUN; then
    log "🦀 Installing Rust toolchain..."
    rustup install stable >>"$LOG_FILE" 2>&1
    rustup default stable >>"$LOG_FILE" 2>&1
fi

# --- Verification ---
log "🔍 Verifying tools"
for entry in "${TOOLS_TO_INSTALL[@]}"; do
    IFS=':' read -r NAME CMD _ <<<"$entry"
    if command -v "$CMD" &>/dev/null; then
        VER=$("$CMD" --version 2>/dev/null | head -n 1)
        log "✔️ $NAME: $VER"
    else
        log "❌ $NAME not found after install"
    fi
done

# --- Complete ---
log "✅ Setup complete. Log saved to $LOG_FILE"
