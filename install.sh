#!/bin/bash

# A script to set up a new Arch, Ubuntu, or macOS machine.
# Includes a headless mode for WSL environments.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Helper Functions ---

print_color() {
    local color_code
    case "$1" in
        red) color_code="\033[0;31m";; green) color_code="\033[0;32m";; yellow) color_code="\033[0;33m";; blue) color_code="\033[0;34m";; magenta) color_code="\033[0;35m";; cyan) color_code="\033[0;36m";; *) color_code="\033[0m";;
    esac
    echo -e "${color_code}${2}\033[0m"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_wsl() {
    grep -qE "(Microsoft|WSL)" /proc/version &> /dev/null
}

# --- Package Definitions ---

# GUI packages are separated for headless mode
ARCH_GUI_PKGS=( alacritty i3-wm polybar rofi docker )
AUR_GUI_PKGS=( google-chrome visual-studio-code-bin )
UBUNTU_GUI_PKGS=( alacritty i3 polybar rofi docker.io docker-compose )

# Base packages for all Linux systems
ARCH_BASE_PKGS=( git curl vim htop procs fzf ripgrep bat tmux tldr fd jq )
UBUNTU_BASE_PKGS=( git curl vim htop procs fzf ripgrep bat tmux tldr fd-find jq )

# macOS packages
BREW_FORMULAE=( git curl vim htop procs fzf ripgrep bat tmux tldr fd jq nvm )
BREW_CASKS=( google-chrome visual-studio-code alacritty docker )

# --- Installation Functions ---

install_packages_arch() {
    print_color "blue" "Installing packages for Arch Linux..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm "${ARCH_BASE_PKGS[@]}"

    if ! is_wsl; then
        sudo pacman -S --needed --noconfirm "${ARCH_GUI_PKGS[@]}"
        if ! command_exists yay && ! command_exists paru; then
            print_color "yellow" "No AUR helper found. Installing yay..."
            sudo pacman -S --needed --noconfirm git base-devel
            git clone https://aur.archlinux.org/yay.git /tmp/yay && (cd /tmp/yay && makepkg -si --noconfirm) && rm -rf /tmp/yay
        fi
        local aur_helper=$(command_exists yay && echo "yay" || echo "paru")
        print_color "blue" "Using ${aur_helper} to install AUR packages..."
        $aur_helper -S --needed --noconfirm "${AUR_GUI_PKGS[@]}"
    fi
}

install_packages_ubuntu() {
    print_color "blue" "Installing packages for Ubuntu..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y "${UBUNTU_BASE_PKGS[@]}"

    if ! is_wsl; then
        print_color "yellow" "Adding external repositories for GUI apps..."
        sudo apt install -y wget gpg
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/packages.microsoft.gpg > /dev/null
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
        sudo apt update
        sudo apt install -y "${UBUNTU_GUI_PKGS[@]}" code google-chrome-stable
    fi

    if command_exists batcat && ! command_exists bat; then sudo ln -s /usr/bin/batcat /usr/local/bin/bat; fi
    if command_exists fdfind && ! command_exists fd; then sudo ln -s /usr/bin/fdfind /usr/local/bin/fd; fi
}

install_packages_mac() {
    print_color "blue" "Installing packages for macOS..."
    if ! command_exists brew; then /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; fi
    brew update
    brew install "${BREW_FORMULAE[@]}" "${BREW_CASKS[@]}"
}

install_nvm() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        print_color "green" "NVM is managed via Homebrew on macOS."
    elif [ -d "$HOME/.nvm" ]; then
        print_color "green" "NVM is already installed."
    else
        print_color "blue" "Installing NVM (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
}

install_npm_globals() {
    local npm_packages_file="npm_global_packages.txt"
    if [ ! -f "$npm_packages_file" ]; then return; fi
    print_color "blue" "Installing global npm packages..."
    export NVM_DIR="$HOME/.nvm"
    if [[ "$(uname -s)" == "Darwin" ]]; then [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh";
    else [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; fi
    if ! command_exists node; then nvm install --lts; nvm use --lts; fi
    local packages_to_install=$(cat "$npm_packages_file" | tr '\n' ' ')
    if [ -n "$packages_to_install" ]; then npm install -g $packages_to_install; fi
}

setup_docker() {
    if is_wsl; then
        print_color "yellow" "Skipping Docker installation on WSL. Please install Docker Desktop for Windows."
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        print_color "green" "Docker for Mac is installed as an application."
    elif command_exists docker && getent group docker > /dev/null; then
        print_color "blue" "Configuring Docker..."
        sudo usermod -aG docker "$USER"
        print_color "green" "User added to the docker group. You may need to log out and log back in."
    fi
}

install_fonts() {
    if is_wsl; then print_color "yellow" "Skipping font installation on WSL."; return; fi
    print_color "blue" "Installing custom fonts..."
    local font_dir
    if [[ "$(uname -s)" == "Darwin" ]]; then font_dir="$HOME/Library/Fonts"; else font_dir="$HOME/.local/share/fonts"; fi
    mkdir -p "$font_dir"
    if [ -d ".fonts" ]; then
        cp -r .fonts/* "$font_dir/"
        if [[ "$(uname -s)" != "Darwin" ]]; then fc-cache -f -v; fi
    fi
}

# --- Main Execution ---

main() {
    if is_wsl; then print_color "magenta" "WSL environment detected. Running in headless mode."; fi
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