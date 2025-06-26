# My Dotfiles

This repository contains my personal configuration files (dotfiles) for various tools and shells on Linux (Arch/Ubuntu) and macOS. It includes a set of scripts to automate the setup and maintenance of a new machine.

## Quickstart

To set up a new machine, follow these two steps:

1.  **Install Tools:** Run the installation script to install all the necessary applications and tools.
2.  **Deploy Dotfiles:** Run the bootstrap script to activate the configuration files.

```bash
# 1. Make scripts executable
chmod +x install.sh bootstrap.sh

# 2. Run the installer
./install.sh

# 3. Run the bootstrap script
./bootstrap.sh
```

---

## Scripts

### `install.sh`

This script installs a curated list of command-line tools, development software, and GUI applications. It automatically detects your operating system (Arch, Ubuntu, or macOS) and uses the appropriate package manager (`pacman`, `apt`, `brew`).

**Features:**
- **Idempotent:** The script can be run multiple times without issues. It checks if a tool is already installed before trying to install it.
- **Multi-platform:** Supports Arch Linux (including EndeavourOS), Ubuntu (and derivatives), and macOS.
- **Automated:** Installs software without requiring manual confirmation for each package.
- **Handles Special Cases:** Manages installations for `nvm`, `docker`, and custom fonts.

### `bootstrap.sh`

This script deploys the dotfiles from this repository to your home directory. It will first pull the latest changes from Git and then prompt you to choose one of two methods:

1.  **Symlink (Recommended):**
    - This method creates symbolic links from your home directory (`~`) to the configuration files in this repository.
    - **Pros:** Your dotfiles are managed from a single source of truth. Any changes you make are automatically saved to the repository, making it easy to commit and push updates.
    - **Safety:** The script will back up any existing dotfiles in your home directory with a timestamp (e.g., `~/.bashrc.bak-20250627103000`) before creating a symlink.

2.  **Rsync (Copy):**
    - This method copies all the configuration files from the repository directly into your home directory.
    - **Pros:** The deployed dotfiles are independent of the repository. This can be useful if you want to make machine-specific modifications without affecting your central dotfiles collection.

---

## Manual Sync (Legacy)

If you use the `rsync` method, you may need to manually sync changes from your home directory back to this repository. You can do this with the following command:

```bash
# Sync changes from your home directory back to the 'dots' repo
rsync -av --existing ~/{.bashrc,.gitconfig,...} /path/to/your/dots/
```

However, using the `symlink` method in the `bootstrap.sh` script is the recommended approach to avoid manual syncing.