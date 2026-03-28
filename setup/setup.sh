#!/usr/bin/env bash
set -e

# ─── Detect distro ───────────────────────────────────────────────────────────
detect_distro() {
    case "$(uname -s)" in
        Darwin) echo "mac" ; return ;;
    esac
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|endeavouros|manjaro) echo "arch" ;;
            ubuntu|linuxmint)        echo "debian" ;;
            *)
                # Mint also sets ID_LIKE
                case "$ID_LIKE" in
                    *ubuntu*|*debian*) echo "debian" ;;
                    *arch*)            echo "arch" ;;
                    *) echo "unknown" ;;
                esac
                ;;
        esac
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
if [ "$DISTRO" = "unknown" ]; then
    echo "ERROR: Unsupported distribution. This script supports macOS, Arch, Ubuntu, and Linux Mint."
    exit 1
fi
echo "Detected distro family: $DISTRO"

# ─── Package install helper ──────────────────────────────────────────────────
pkg_install() {
    if [ "$DISTRO" = "mac" ]; then
        brew install "$@"
    elif [ "$DISTRO" = "arch" ]; then
        sudo pacman -S --noconfirm --needed "$@"
    else
        sudo apt-get update -qq
        sudo apt-get install -y "$@"
    fi
}

# ─── 0. Homebrew (macOS only) ────────────────────────────────────────────────
if [ "$DISTRO" = "mac" ]; then
    echo ""
    echo "=== Step 0: Homebrew ==="
    if command -v brew &>/dev/null; then
        echo "Homebrew is already installed."
    else
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for the rest of this script
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
fi

# ─── 1. Docker ───────────────────────────────────────────────────────────────
echo ""
echo "=== Step 1: Docker ==="
if command -v docker &>/dev/null; then
    echo "Docker is already installed: $(docker --version)"
else
    echo "Installing Docker..."
    if [ "$DISTRO" = "mac" ]; then
        brew install --cask docker
        echo "NOTE: Open Docker Desktop from Applications to finish setup."
    elif [ "$DISTRO" = "arch" ]; then
        pkg_install docker
    else
        pkg_install docker.io
    fi
fi

if [ "$DISTRO" != "mac" ]; then
    # Enable and start the docker service (Linux only — macOS uses Docker Desktop)
    sudo systemctl enable docker
    sudo systemctl start docker

    # Add current user to the docker group
    if groups "$USER" | grep -qw docker; then
        echo "User '$USER' is already in the docker group."
    else
        echo "Adding user '$USER' to the docker group..."
        sudo usermod -aG docker "$USER"
        echo "NOTE: You may need to log out and back in for the docker group to take effect."
    fi
fi

# ─── 2. Git ──────────────────────────────────────────────────────────────────
echo ""
echo "=== Step 2: Git ==="
if command -v git &>/dev/null; then
    echo "Git is already installed: $(git --version)"
else
    echo "Installing Git..."
    pkg_install git
fi

# ─── 3. Claude Code ─────────────────────────────────────────────────────────
echo ""
echo "=== Step 3: Claude Code ==="
if command -v claude &>/dev/null; then
    echo "Claude Code is already installed."
else
    echo "Installing Claude Code via npm..."
    # Ensure npm is available
    if ! command -v npm &>/dev/null; then
        echo "npm not found, installing Node.js and npm..."
        if [ "$DISTRO" = "mac" ]; then
            pkg_install node
        else
            pkg_install nodejs npm
        fi
    fi
    if [ "$DISTRO" = "mac" ]; then
        npm install -g @anthropic-ai/claude-code
    else
        sudo npm install -g @anthropic-ai/claude-code
    fi
fi

# ─── 4. wget ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Step 4: wget ==="
if command -v wget &>/dev/null; then
    echo "wget is already installed."
else
    if [ "$DISTRO" = "mac" ]; then
        echo "Skipping wget (macOS uses curl natively)."
    else
        echo "Installing wget..."
        pkg_install wget
    fi
fi

# ─── 5. Bash (ensure installed and set as default shell) ─────────────────────
echo ""
echo "=== Step 5: Bash ==="
if command -v bash &>/dev/null; then
    echo "Bash is already installed: $(bash --version | head -1)"
else
    echo "Installing Bash..."
    pkg_install bash
fi

if [ "$DISTRO" = "mac" ]; then
    CURRENT_SHELL=$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')
else
    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
fi
if [ "$CURRENT_SHELL" = "$(which bash)" ]; then
    echo "Bash is already the default shell."
else
    echo "Setting bash as the default shell..."
    if [ "$DISTRO" = "mac" ]; then
        chsh -s "$(which bash)"
    else
        sudo chsh -s "$(which bash)" "$USER"
    fi
    echo "Default shell changed to bash. Will take effect on next login."
fi

# ─── 6. Go (download and extract to home directory) ──────────────────────────
echo ""
echo "=== Step 6: Go ==="
GO_VERSION="1.26.1"
if [ "$DISTRO" = "mac" ]; then
    GO_ARCH="$(uname -m)"
    if [ "$GO_ARCH" = "arm64" ]; then
        GO_ARCHIVE="go${GO_VERSION}.darwin-arm64.tar.gz"
    else
        GO_ARCHIVE="go${GO_VERSION}.darwin-amd64.tar.gz"
    fi
else
    GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
fi
GO_URL="https://go.dev/dl/${GO_ARCHIVE}"

if [ -d "$HOME/go" ] && "$HOME/go/bin/go" version &>/dev/null; then
    echo "Go is already installed: $($HOME/go/bin/go version)"
else
    echo "Downloading Go ${GO_VERSION}..."
    cd /tmp
    if command -v wget &>/dev/null; then
        wget -q "$GO_URL"
    else
        curl -fsSLO "$GO_URL"
    fi
    echo "Extracting Go to $HOME/go..."
    rm -rf "$HOME/go"
    tar -C "$HOME" -xzf "$GO_ARCHIVE"
    rm -f "$GO_ARCHIVE"
    echo "Go installed: $($HOME/go/bin/go version)"
fi

# ─── 7. Create project directory ─────────────────────────────────────────────
echo ""
echo "=== Step 7: Project directory ==="
PROJECT_DIR="$HOME/proj/src/github.com/saichler"
if [ -d "$PROJECT_DIR" ]; then
    echo "Project directory already exists: $PROJECT_DIR"
else
    echo "Creating $PROJECT_DIR..."
    mkdir -p "$PROJECT_DIR"
fi

# ─── 8. Set environment variables in shell profile ──────────────────────────
echo ""
echo "=== Step 8: Environment variables ==="
if [ "$DISTRO" = "mac" ]; then
    SHELL_PROFILE="$HOME/.bash_profile"
else
    SHELL_PROFILE="$HOME/.bashrc"
fi

add_to_profile() {
    local line="$1"
    if ! grep -qF "$line" "$SHELL_PROFILE" 2>/dev/null; then
        echo "$line" >> "$SHELL_PROFILE"
        echo "  Added: $line"
    else
        echo "  Already set: $line"
    fi
}

add_to_profile 'export GOROOT=~/go'
add_to_profile 'export GOPATH=~/proj'
add_to_profile 'export GOBIN=~/proj/bin'
add_to_profile 'export PATH=$GOROOT/bin:$PATH'
add_to_profile 'alias ll="ls -lt"'
add_to_profile 'alias proj="cd ~/proj/src/github.com/saichler"'

# Source the updated profile for the rest of this script
export GOROOT="$HOME/go"
export GOPATH="$HOME/proj"
export GOBIN="$HOME/proj/bin"
export PATH="$GOROOT/bin:$PATH"

# ─── 9. Clone repositories ──────────────────────────────────────────────────
echo ""
echo "=== Step 9: Clone repositories ==="
cd "$PROJECT_DIR"

for repo in l8book l8nasfile l8erp l8orm l8ui l8agent l8web l8reflect l8types l8events l8bus l8myfamiliy l8services l8opensim l8collector l8topology l8-site-base l8utils l8ql l8srlz l8finplan l8inventory l8logfusion l8bugs l8test l8traffic l8alarms l8notify l8pollaris l8parser probler; do
    if [ -d "$PROJECT_DIR/$repo" ]; then
        echo "$repo already cloned, pulling latest..."
        git -C "$PROJECT_DIR/$repo" pull
    else
        echo "Cloning $repo..."
        git clone "https://github.com/saichler/${repo}.git"
    fi
done

# ─── 10. Install Claude Code global rules ─────────────────────────────────
echo ""
echo "=== Step 10: Claude Code global rules ==="
CLAUDE_RULES_DIR="$HOME/.claude/rules"
L8BOOK_RULES_DIR="$PROJECT_DIR/l8book/rules"
mkdir -p "$CLAUDE_RULES_DIR"

if [ -d "$L8BOOK_RULES_DIR" ]; then
    echo "Symlinking rules from l8book/rules into ~/.claude/rules/..."
    for rule in "$L8BOOK_RULES_DIR"/*.md; do
        [ -f "$rule" ] || continue
        name=$(basename "$rule")
        if [ -L "$CLAUDE_RULES_DIR/$name" ] || [ -f "$CLAUDE_RULES_DIR/$name" ]; then
            rm -f "$CLAUDE_RULES_DIR/$name"
        fi
        ln -s "$rule" "$CLAUDE_RULES_DIR/$name"
    done
    echo "  $(ls "$L8BOOK_RULES_DIR"/*.md 2>/dev/null | wc -l) rules linked."
else
    echo "WARNING: l8book/rules directory not found at $L8BOOK_RULES_DIR"
fi

# ─── 11. Create new project directory ─────────────────────────────────────
echo ""
echo "=== Step 11: Create new project directory ==="
MY_PROJECT_DIR="$PROJECT_DIR/my-project"
if [ -d "$MY_PROJECT_DIR" ]; then
    echo "Project directory already exists: $MY_PROJECT_DIR"
else
    echo "Creating $MY_PROJECT_DIR..."
    mkdir -p "$MY_PROJECT_DIR"
fi

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Log out and back in (for docker group and shell changes)"
echo "  2. Run 'source $SHELL_PROFILE' or open a new terminal"
echo "  3. cd $MY_PROJECT_DIR"
echo ""
echo "You can now execute claude in this directory and create a PRD for your idea."
echo ""
