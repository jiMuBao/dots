#!/bin/bash

# A script to bootstrap the dotfiles, offering a choice between symlinking and copying.

set -e # Exit immediately if a command fails.

# --- Helper Functions ---

# Print a message in a given color.
print_color() {
    local color_code
    case "$1" in
        red) color_code="\033[0;31m";; green) color_code="\033[0;32m";; yellow) color_code="\033[0;33m";; blue) color_code="\033[0;34m";; *) color_code="\033[0m";;
    esac
    echo -e "${color_code}${2}\033[0m"
}

# --- Core Functions ---

# Files and directories to be managed by the script.
# Add new files/dirs here. Note: .git is always excluded.
DOT_FILES=(
    .bash_profile .bash_prompt .bashrc .gitconfig .inputrc .tmux.conf .xinitrc .Xmodmap .xprofile .Xresources
    .bash.d .config .fonts .screenlayout bin
)

# Method 1: Create symbolic links
do_symlink() {
    print_color "blue" "Starting symlink setup..."
    for item in "${DOT_FILES[@]}"; do
        local source_path="$PWD/$item"
        local target_path="$HOME/$item"

        # Check if the source file/directory actually exists in the repo
        if [ ! -e "$source_path" ]; then
            print_color "yellow" "Warning: '$item' not found in the repository. Skipping."
            continue
        fi

        # If a file/symlink already exists at the target, back it up.
        if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            local backup_path="${target_path}.bak-$(date +%Y%m%d%H%M%S)"
            print_color "yellow" "Backing up existing '$target_path' to '$backup_path'"
            mv "$target_path" "$backup_path"
        fi

        print_color "green" "Creating symlink for '$item' -> '$target_path'"
        ln -s "$source_path" "$target_path"
    done
    print_color "green" "\nSymlinking complete."
}

# Method 2: Copy files using rsync
do_rsync() {
    print_color "blue" "Starting rsync (copy) setup..."
    # The original rsync command, but using the array for consistency
    rsync --exclude ".git/" --exclude ".DS_Store" --exclude "bootstrap.sh" --exclude "README.md" --exclude "install.sh" -av . ~
    print_color "green" "\nRsync complete."
}

# --- Main Execution ---

main() {
    cd "$(dirname "$0")" # Change to the script's directory

    print_color "blue" "Pulling latest changes from Git repository..."
    git pull
    echo

    print_color "yellow" "Choose your setup method:"
    echo "  1) Symlink (Recommended): Creates links from your home directory to this repo."
    echo "  2) Rsync (Copy): Copies all files to your home directory."
    read -p "Enter your choice (1 or 2): " choice
    echo

    local action_confirmed=false

    if [[ "$choice" == "1" || "$choice" == "2" ]]; then
        read -p "This may overwrite or back up existing files in your home directory. Are you sure? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            action_confirmed=true
        fi
    fi

    if ! $action_confirmed; then
        print_color "red" "Operation cancelled."
        exit 0
    fi

    case "$choice" in
        1) do_symlink ;;
        2) do_rsync ;;
        *) print_color "red" "Invalid choice. Exiting."; exit 1 ;;
    esac

    print_color "blue" "\nSourcing .bash_profile to apply changes..."
    source "$HOME/.bash_profile"
    print_color "green" "Bootstrap complete!"
}

main