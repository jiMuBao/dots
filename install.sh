#!/bin/bash

# A script to set up a new Arch, Ubuntu, or macOS machine.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Helper Functions ---

# Print a message in a given color.
# Usage: print_color <color> <message>
# Colors: red, green, yellow, blue, magenta, cyan
print_color() {
    local color_code
    case "$1" in
        red) color_code="\033[0;31m";; green) color_code="\033[0;32m";; yellow) color_code="\033[0;33m";; blue) color_code="\033[0;34m";; magenta) color_code="\033[0;35m";; cyan) color_code="\033[0;36m";; *) color_code="\033[0m";;
    esac
    echo -e "${color_code}${2}\033[0m"
}

# Check if a command exists.
# Usage: command_exists <command>
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Package Definitions ---

ARCH_PKGS=( git curl vim htop procs fzf ripgrep bat tmux tldr fd jq alacritty i3-wm polybar rofi docker )
AUR_PKGS=( google-chrome visual-studio-code-bin )
UBUNTU_PKGS=( git curl vim htop procs fzf ripgrep bat tmux tldr fd-find jq alacritty i3 polybar rofi docker.io docker-compose )
BREW_FORMULAE=( git curl vim htop procs fzf ripgrep bat tmux tldr fd jq nvm )
BREW_CASKS=( google-chrome visual-studio-code alacritty docker )

# --- Installation Functions ---

install_aur_helper() {
    if ! command_exists yay && ! command_exists paru; then
        print_color "yellow" "No AUR helper found. Installing yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay && (cd /tmp/yay && makepkg -si --noconfirm) && rm -rf /tmp/yay
        print_color "green" "yay has been installed."
    else
        print_color "green" "AUR helper (yay or paru) already installed."
    fi
}

install_packages_arch() {
    print_color "blue" "Installing packages for Arch Linux..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm "${ARCH_PKGS[@]}"
    install_aur_helper
    local aur_helper=$(command_exists yay && echo "yay" || echo "paru")
    print_color "blue" "Using ${aur_helper} to install AUR packages..."
    $aur_helper -S --needed --noconfirm "${AUR_PKGS[@]}"
}

install_packages_ubuntu() {
    print_color "blue" "Installing packages for Ubuntu..."
    sudo apt update && sudo apt upgrade -y
    print_color "yellow" "Adding external repositories (VSCode, Google Chrome)..."
    sudo apt install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/packages.microsoft.gpg > /dev/null
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo apt update
    sudo apt install -y "${UBUNTU_PKGS[@]}" code google-chrome-stable
    if command_exists batcat && ! command_exists bat; then sudo ln -s /usr/bin/batcat /usr/local/bin/bat; fi
    if command_exists fdfind && ! command_exists fd; then sudo ln -s /usr/bin/fdfind /usr/local/bin/fd; fi
}

install_homebrew() {
    if ! command_exists brew; then
        print_color "yellow" "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_color "green" "Homebrew has been installed."
    else
        print_color "green" "Homebrew is already installed."
    fi
}

install_packages_mac() {
    print_color "blue" "Installing packages for macOS..."
    install_homebrew
    print_color "yellow" "Updating Homebrew..."
    brew update
    print_color "blue" "Installing formulae and casks..."
    brew install "${BREW_FORMULAE[@]}" "${BREW_CASKS[@]}"
}

install_nvm() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        print_color "green" "NVM is managed via Homebrew on macOS."
    else
        if [ -d "$HOME/.nvm" ]; then
            print_color "green" "NVM is already installed."
        else
            print_color "blue" "Installing NVM (Node Version Manager)..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
            print_color "green" "NVM installed."
        fi
    fi
}

install_npm_globals() {
    local npm_packages_file="npm_global_packages.txt"
    if [ ! -f "$npm_packages_file" ]; then
        print_color "yellow" "Warning: '$npm_packages_file' not found. Skipping global npm package installation."
        return
    fi

    print_color "blue" "Installing global npm packages..."

    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # For macOS with Homebrew
        [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
    else
        # For Linux
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    fi

    # Install Node.js LTS if not already installed
    if ! command_exists node; then
        print_color "yellow" "Node.js not found. Installing latest LTS version..."
        nvm install --lts
        nvm use --lts
    fi

    # Read packages from file and install
    local packages_to_install=$(cat "$npm_packages_file" | tr '\n' ' ')
    if [ -n "$packages_to_install" ]; then
        print_color "cyan" "Installing: $packages_to_install"
        npm install -g $packages_to_install
        print_color "green" "Global npm packages installed."
    else
        print_color "yellow" "No packages listed in '$npm_packages_file'."
    fi
}

setup_docker() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        print_color "green" "Docker for Mac is installed as an application. No further setup needed."
    elif command_exists docker && getent group docker > /dev/null; then
        print_color "blue" "Configuring Docker..."
        sudo usermod -aG docker "$USER"
        print_color "green" "User added to the docker group. You may need to log out and log back in."
    fi
}

install_fonts() {
    print_color "blue" "Installing custom fonts..."
    local font_dir
    if [[ "$(uname -s)" == "Darwin" ]]; then font_dir="$HOME/Library/Fonts"; else font_dir="$HOME/.local/share/fonts"; fi
    mkdir -p "$font_dir"
    if [ -d ".fonts" ]; then
        cp -r .fonts/* "$font_dir/"
        print_color "green" "Fonts copied to ${font_dir}."
        if [[ "$(uname -s)" != "Darwin" ]]; then fc-cache -f -v; fi
    else
        print_color "red" "'.fonts' directory not found. Skipping font installation."
    fi
}

# --- Main Execution ---

main() {
    print_color "magenta" "Starting system setup..."

    local OS_TYPE=$(uname -s)
    local OS_NAME=""
    if [ -f /etc/os-release ]; then . /etc/os-release; OS_NAME=$NAME; fi

    if [[ "$OS_TYPE" == "Darwin" ]]; then install_packages_mac
    elif [[ "$OS_NAME" == "Arch Linux" || "$OS_NAME" == "EndeavourOS" ]]; then install_packages_arch
    elif [[ "$OS_NAME" == "Ubuntu" || "$OS_NAME" == "Pop!_OS" ]]; then install_packages_ubuntu
    else print_color "red" "Unsupported OS: $OS_TYPE / $OS_NAME"; exit 1; fi

    install_nvm
    install_npm_globals
    setup_docker
    install_fonts

    print_color "magenta" "================================================"
    print_color "green"   "  System setup complete!                  "
    print_color "magenta" "================================================"
    print_color "yellow" "Please review messages for manual steps (e.g., relogin for Docker, NVM setup)."
}

main
