# .dotfiles

## Requirements

### Git and GitHub SSH Setup

Before using these dotfiles, make sure you have:

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
   ssh-keygen -t ed25519 -C "your_email@example.com"
   
   # Start the ssh-agent in the background
   eval "$(ssh-agent -s)"
   
   # Add your SSH key to the ssh-agent
   ssh-add ~/.ssh/id_ed25519
   
   # Copy the SSH key to your clipboard
   pbcopy < ~/.ssh/id_ed25519.pub
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
