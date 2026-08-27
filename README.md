# .dotfiles

## Requirements

### Git and GitHub SSH Setup

Before using these dotfiles project, make sure you have:

1. **Git installed** (without Homebrew):
   ```bash
   # Download the latest Git for macOS installer
   curl -O https://sourceforge.net/projects/git-osx-installer/files/git-2.33.0-intel-universal-mavericks.dmg

   # Mount the disk image
   hdiutil attach git-2.33.0-intel-universal-mavericks.dmg

   # Install the package
   sudo installer -pkg /Volumes/Git\ 2.33.0\ Mavericks\ Intel\ Universal/git-2.33.0-intel-universal-mavericks.pkg -target /

   # Unmount the disk image
   hdiutil detach /Volumes/Git\ 2.33.0\ Mavericks\ Intel\ Universal/
   ```

2. **GitHub SSH connection configured**:
   ```bash
   # Generate SSH key
   ssh-keygen -f ~/.ssh/github -t ed25519 -C "your_email@example.com"

   # Start the ssh-agent in the background
   eval "$(ssh-agent -s)"

   # Add your SSH key to the ssh-agent
   ssh-add ~/.ssh/github

   # Copy the SSH key to your clipboard
   pbcopy < ~/.ssh/github.pub
   ```

   Then add the SSH key to your GitHub account:
   1. Go to GitHub → Settings → SSH and GPG keys
   2. Click "New SSH key"
   3. Paste your key and save

   Test your connection:
   ```bash
   ssh -T git@github.com
   ```

## Installation

To install dotfiles:

```bash
git clone git@github.com:maxime-lenne/.dotfiles.git
cd .dotfiles
chmod 755 install-deps.sh
chmod 755 configure_dotfiles.sh
./install-deps.sh
./configure_dotfiles.sh
```

## Disk cleanup (`clean-mac.sh`)

`clean-mac.sh` frees up disk space taken by caches, logs and temporary
files from the dev tools installed via `install-deps.sh`. It goes
section by section, explains what it's about to remove and why it's
safe, shows the current size, and asks for confirmation before doing
anything. Nothing is deleted without an explicit yes.

What it can clean, section by section:

- **Homebrew**: old formula/cask versions and download cache (`brew cleanup`), orphaned dependencies (`brew autoremove`).
- **Docker Desktop**: stopped containers, unused networks and dangling images (`docker system prune`), optionally *all* unused images and volumes (more aggressive, can delete data from unmounted volumes), and the build cache (`docker builder prune`).
- **JetBrains** (WebStorm, PyCharm, DataGrip, RubyMine, Toolbox...): the IDEs' indexing cache (`~/Library/Caches/JetBrains`, rebuilt automatically on next open) and logs (`~/Library/Logs/JetBrains`). Toolbox's old IDE version archives are only reported (size + where to configure retention), never deleted automatically.
- **Ollama**: downloaded models, asked one by one by name and size (deleting one means re-pulling it later), plus its logs.
- **uv**: the Python package cache (`uv cache clean`).
- **bun**: the package cache (`~/.bun/install/cache`).
- **Bonus**: npm cache, pnpm store (`pnpm store prune`), pip cache, and Xcode DerivedData.

At the end it prints a summary of the estimated space freed and the
free disk space before/after.

Usage:

```bash
./clean-mac.sh              # interactive, asks before each cleanup
./clean-mac.sh --dry-run    # shows what would be done, deletes nothing
./clean-mac.sh -y           # auto-confirms every prompt
```
