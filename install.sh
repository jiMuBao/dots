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
        red) color_code="\033[0;31m";;
        green) color_code="\033[0;32m";;
        yellow) color_code="\033[0;33m";;
        blue) color_code="\033[0;34m";;
        magenta) color_code="\033[0;35m";;
        cyan) color_code="\033[0;36m";;
        *) color_code="\033[0m";; # No Color
    esac
    echo -e "${color_code}${2}\033[0m"
}

# Check if a command exists.
# Usage: command_exists <command>
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Package Definitions ---

# Packages for Arch Linux (Official Repositories)
ARCH_PKGS=(
    git curl vim htop procs fzf ripgrep bat tmux tldr fd jq alacritty i3-wm polybar rofi docker
)

# Packages for Arch Linux (AUR)
AUR_PKGS=( google-chrome visual-studio-code-bin )

# Packages for Ubuntu/Debian
UBUNTU_PKGS=(
    git curl vim htop procs fzf ripgrep bat tmux tldr fd-find jq alacritty i3 polybar rofi docker.io docker-compose
)

# Packages for macOS (Homebrew Formulae)
BREW_FORMULAE=(
    git curl vim htop procs fzf ripgrep bat tmux tldr fd jq nvm
)

# Packages for macOS (Homebrew Casks)
BREW_CASKS=(
    google-chrome visual-studio-code alacritty docker
)

# --- Installation Functions ---

install_aur_helper() {
    if ! command_exists yay && ! command_exists paru; then
        print_color "yellow" "No AUR helper found. Installing yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
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
    local aur_helper
    aur_helper=$(command_exists yay && echo "yay" || echo "paru")
    print_color "blue" "Using ${aur_helper} to install AUR packages..."
    $aur_helper -S --needed --noconfirm "${AUR_PKGS[@]}"
}

install_packages_ubuntu() {
    print_color "blue" "Installing packages for Ubuntu..."
    sudo apt update && sudo apt upgrade -y

    print_color "yellow" "Adding external repositories (VSCode, Google Chrome)..."
    sudo apt install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'

    sudo apt update
    sudo apt install -y "${UBUNTU_PKGS[@]}" code google-chrome-stable

    if command_exists batcat && ! command_exists bat; then
        print_color "yellow" "Creating symlink for bat..."
        sudo ln -s /usr/bin/batcat /usr/local/bin/bat
    fi
    if command_exists fdfind && ! command_exists fd; then
        print_color "yellow" "Creating symlink for fd..."
        sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
    fi
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
    print_color "blue" "Installing formulae..."
    brew install "${BREW_FORMULAE[@]}"
    print_color "blue" "Installing casks..."
    brew install --cask "${BREW_CASKS[@]}"
}

install_nvm() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        print_color "green" "NVM is installed via Homebrew on macOS."
        print_color "yellow" "To finish NVM setup, add the following to your ~/.zshrc or ~/.bash_profile:"
        print_color "cyan" '  export NVM_DIR="$HOME/.nvm"'
        print_color "cyan" '  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"'
        print_color "cyan" '  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"'
        return
    fi

    if [ -d "$HOME/.nvm" ]; then
        print_color "green" "NVM is already installed."
    else
        print_color "blue" "Installing NVM (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        print_color "green" "NVM installed."
        print_color "yellow" "Please close and reopen your terminal to start using NVM."
    fi
}

setup_docker() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        print_color "green" "Docker for Mac is installed as an application. No further setup is needed."
        return
    fi

    if command_exists docker; then
        print_color "blue" "Configuring Docker..."
        if getent group docker > /dev/null; then
            print_color "yellow" "Adding current user to the 'docker' group..."
            sudo usermod -aG docker "$USER"
            print_color "green" "User added to the docker group."
            print_color "yellow" "You may need to log out and log back in for this to take effect."
        else
            print_color "red" "The 'docker' group does not exist. Skipping user addition."
        fi
    else
        print_color "red" "Docker is not installed. Skipping Docker setup."
    fi
}

install_fonts() {
    print_color "blue" "Installing custom fonts..."
    local font_dir
    if [[ "$(uname -s)" == "Darwin" ]]; then
        font_dir="$HOME/Library/Fonts"
    else
        font_dir="$HOME/.local/share/fonts"
    fi

    if [ ! -d "$font_dir" ]; then
        mkdir -p "$font_dir"
    fi

    if [ -d ".fonts" ]; then
        cp -r .fonts/* "$font_dir/"
        print_color "green" "Fonts copied to ${font_dir}."
        if [[ "$(uname -s)" != "Darwin" ]]; then
            print_color "yellow" "Rebuilding font cache..."
            fc-cache -f -v
            print_color "green" "Font cache rebuilt."
        fi
    else
        print_color "red" "'.fonts' directory not found. Skipping font installation."
    fi
}


# --- Main Execution ---

main() {
    print_color "magenta" "Starting system setup..."

    local OS_TYPE=$(uname -s)
    local OS_NAME=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
    fi

    if [[ "$OS_TYPE" == "Darwin" ]]; then
        install_packages_mac
    elif [[ "$OS_NAME" == "Arch Linux" || "$OS_NAME" == "EndeavourOS" ]]; then
        install_packages_arch
    elif [[ "$OS_NAME" == "Ubuntu" || "$OS_NAME" == "Pop!_OS" ]]; then
        install_packages_ubuntu
    else
        print_color "red" "Unsupported operating system: $OS_TYPE / $OS_NAME"
        exit 1
    fi

    install_nvm
    setup_docker
    install_fonts

    print_color "magenta" "================================================"
    print_color "green" "  System setup complete!                  "
    print_color "magenta" "================================================"
    print_color "yellow" "Please review any messages above for required manual steps (e.g., logout/relogin)."
}

main