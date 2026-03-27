#!/usr/bin/env bash
set -e

# ─── Detect distro ───────────────────────────────────────────────────────────
detect_distro() {
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
    echo "ERROR: Unsupported distribution. This script supports Arch, Ubuntu, and Linux Mint."
    exit 1
fi
echo "Detected distro family: $DISTRO"

# ─── Package install helper ──────────────────────────────────────────────────
pkg_install() {
    if [ "$DISTRO" = "arch" ]; then
        sudo pacman -S --noconfirm --needed "$@"
    else
        sudo apt-get update -qq
        sudo apt-get install -y "$@"
    fi
}

# ─── 1. Docker ───────────────────────────────────────────────────────────────
echo ""
echo "=== Step 1: Docker ==="
if command -v docker &>/dev/null; then
    echo "Docker is already installed: $(docker --version)"
else
    echo "Installing Docker..."
    if [ "$DISTRO" = "arch" ]; then
        pkg_install docker
    else
        pkg_install docker.io
    fi
fi

# Enable and start the docker service
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
        if [ "$DISTRO" = "arch" ]; then
            pkg_install nodejs npm
        else
            pkg_install nodejs npm
        fi
    fi
    sudo npm install -g @anthropic-ai/claude-code
fi

# ─── 4. wget ─────────────────────────────────────────────────────────────────
echo ""
echo "=== Step 4: wget ==="
if command -v wget &>/dev/null; then
    echo "wget is already installed."
else
    echo "Installing wget..."
    pkg_install wget
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

CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" = "$(which bash)" ]; then
    echo "Bash is already the default shell."
else
    echo "Setting bash as the default shell..."
    sudo chsh -s "$(which bash)" "$USER"
    echo "Default shell changed to bash. Will take effect on next login."
fi

# ─── 6. Go (download and extract to home directory) ──────────────────────────
echo ""
echo "=== Step 6: Go ==="
GO_VERSION="1.26.1"
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_ARCHIVE}"

if [ -d "$HOME/go" ] && "$HOME/go/bin/go" version &>/dev/null; then
    echo "Go is already installed: $($HOME/go/bin/go version)"
else
    echo "Downloading Go ${GO_VERSION}..."
    cd /tmp
    wget -q "$GO_URL"
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

# ─── 8. Set environment variables in ~/.bashrc ───────────────────────────────
echo ""
echo "=== Step 8: Environment variables ==="
BASHRC="$HOME/.bashrc"

add_to_bashrc() {
    local line="$1"
    if ! grep -qF "$line" "$BASHRC" 2>/dev/null; then
        echo "$line" >> "$BASHRC"
        echo "  Added: $line"
    else
        echo "  Already set: $line"
    fi
}

add_to_bashrc 'export GOROOT=~/go'
add_to_bashrc 'export GOPATH=~/proj'
add_to_bashrc 'export GOBIN=~/proj/bin'
add_to_bashrc 'export PATH=$GOROOT/bin:$PATH'
add_to_bashrc 'alias ll="ls -lt"'

# Source the updated bashrc for the rest of this script
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
        echo "$repo already cloned."
    else
        echo "Cloning $repo..."
        git clone "https://github.com/saichler/${repo}.git"
    fi
done

# ─── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Log out and back in (for docker group and shell changes)"
echo "  2. Run 'source ~/.bashrc' or open a new terminal"
echo ""
