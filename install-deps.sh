#!/bin/bash

# Options:
#   --server       minimal setup: the target package-manager stack
#                  (asdf, uv, bun) installed without prompts, and no GUI
#                  apps. For headless machines (e.g. the Mac mini server).
#   --workstation  full setup: same package-manager stack, but asked
#                  section by section, plus IDEs, GUI and App Store apps.
#                  For dev machines (e.g. the MacBook Pro).
#
# The legacy managers (nvm, pyenv, rvm) are NOT installed by either role:
# they were removed from both machines on 2026-08-28 and asdf/uv/bun
# fully replace them. See README "Package managers".
#
# Auto-detected from hostname if neither flag is passed (a "mac-mini"
# hostname maps to --server, anything else to --workstation).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dotfiles-lib.sh"

detect_machine_role "$@"

# Function to ask user if they want to install a section
ask_to_install() {
  local section_name=$1
  ask "Do you want to install $section_name?"
}

# Installs a package, or upgrades it if it's already there.
# Usage: install_or_upgrade [--cask] <package> [<package>...]
#
# Names are matched *exactly* against `brew list`. The previous version
# grepped, so "jpeg" matched the installed "jpeg-turbo" and the script
# decided jpeg was already there. Tap-qualified names (derailed/k9s/k9s)
# are compared on their last component, which is how brew lists them.
#
# A failing brew command is reported and skipped rather than silently
# swallowed — some steps below depend on third-party taps that may not
# be present.
function install_or_upgrade {
  local cask_flag=""
  if [[ "$1" == "--cask" ]]; then
    cask_flag="--cask"
    shift
  fi

  local installed package
  if [[ -n "$cask_flag" ]]; then
    installed="$(brew list --cask 2>/dev/null)"
  else
    installed="$(brew list --formula 2>/dev/null)"
  fi

  for package in "$@"; do
    if grep -qxF -- "${package##*/}" <<< "$installed"; then
      brew upgrade $cask_flag "$package" || echo "  ! brew upgrade ${cask_flag:+$cask_flag }$package failed — skipping"
    else
      brew install $cask_flag "$package" || echo "  ! brew install ${cask_flag:+$cask_flag }$package failed — skipping"
    fi
  done
}

echo "Welcome to the dotfiles installation script!"
echo "This script will guide you through installing various development tools and applications."
echo "You can choose which sections to install."
echo ""
echo "Machine role: $MACHINE_ROLE (override with --server / --workstation)"
echo ""

# Install homebrew
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

sudo chown -R "$(whoami):admin" /opt/homebrew

echo "------------------------------"
echo "Installing Xcode Command Line Tools."
xcode-select --install
sudo xcodebuild -license accept

echo "------------------------------"
echo "Installing basic libraries..."
sudo chown -R "$USER:admin" /usr/local
# openssl@3 explicitly: "openssl" is an alias for it, and openssl@1.1
# was dropped on 2026-08-28 (EOL upstream, ruby-build builds against
# openssl@3 fine, `brew uses --installed openssl@1.1` returns nothing).
install_or_upgrade "openssl@3"
install_or_upgrade "libxml2"
install_or_upgrade "libxslt"
install_or_upgrade "libiconv"
install_or_upgrade "libksba"
install_or_upgrade "zlib"
install_or_upgrade "coreutils"
install_or_upgrade "automake"
install_or_upgrade "pkgconf"

echo "------------------------------"
echo "fonts and terminal customization"

# fonts
install_or_upgrade "--cask" "font-hack-nerd-font"

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
# (colorls is installed in the Ruby section below — running `gem` here
# would hit the macOS system Ruby, which asdf replaces.)

echo "------------------------------"
echo "image and media tools"

#image optim
install_or_upgrade "ghostscript"
install_or_upgrade "imagemagick"
install_or_upgrade gifsicle jhead jpegoptim jpeg optipng pngcrush pngquant advancecomp agg
install_or_upgrade "ffmpeg"


echo "------------------------------"
echo "Installing package managers: asdf, uv, bun (target stack), Java, Elixir"

# --- Target stack: asdf, uv, bun ---
# Server role: minimal, non-interactive, target stack only, no legacy managers.
if [ "$MACHINE_ROLE" = "server" ]; then
  echo "Server role: installing the target package managers (asdf, uv, bun) without prompting."
  install_or_upgrade "asdf"
  install_or_upgrade "uv"
  curl -fsSL https://bun.sh/install | bash
else
  if ask_to_install "asdf (Ruby, Node... version manager)"; then
    install_or_upgrade "asdf"
  fi

  if ask_to_install "uv (Python version/package manager)"; then
    install_or_upgrade "uv"
  fi

  if ask_to_install "bun (JS/TS runtime and package manager)"; then
    curl -fsSL https://bun.sh/install | bash
  fi
fi

if ask_to_install "Java (Temurin JDK)"; then
  # The `java` cask was removed from Homebrew; temurin is the successor.
  install_or_upgrade "--cask" "temurin"
fi

# --- Node.js, via asdf's nodejs plugin (target stack) ---
if ask_to_install "Node.js (via asdf)"; then
  asdf plugin add nodejs 2>/dev/null
  asdf install nodejs latest
  asdf set nodejs latest --home
fi

# pnpm/yarn are kept as an opt-in: some projects' lockfiles still
# require them. nvm is not offered — asdf's nodejs plugin replaces it.
if [ "$MACHINE_ROLE" = "workstation" ]; then
  if ask_to_install "pnpm and yarn (only for projects whose lockfile requires them — bun is the default)"; then
    install_or_upgrade "pnpm"
    install_or_upgrade "yarn"
  fi
else
  echo "Server role: skipping pnpm/yarn (bun is the default JS package manager)."
fi

# --- Python, via uv (target stack) ---
if ask_to_install "Python (via uv)"; then
  uv python install 3.13
fi

# --- Ruby and Rails, via asdf's ruby plugin (target stack) ---
if ask_to_install "Ruby and Rails (via asdf)"; then
  asdf plugin add ruby 2>/dev/null
  asdf install ruby latest
  asdf set ruby latest --home
  gem install bundler pry
  gem install rails
  gem install jekyll
  gem install colorls
fi

if ask_to_install "Elixir"; then
  install_or_upgrade "elixir"
  mix local.hex
  mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez
fi

if ask_to_install "PHP Composer"; then
  install_or_upgrade "composer"
fi

if ask_to_install "Go"; then
  install_or_upgrade "go"
fi


echo "------------------------------"
echo "Installing developer tools: Git and bash completion."

if ask_to_install "Git and GitHub CLI"; then
  install_or_upgrade "git"
  install_or_upgrade "hub"
  install_or_upgrade "gh"
  install_or_upgrade "git-lfs"
  install_or_upgrade "git-filter-repo"
fi

if ask_to_install "Git tools (lolcommits, gitmoji)"; then
  gem install lolcommits
  gem install lolcommits-slack
  npm i -g gitmoji-cli
fi

if ask_to_install "bash-completion"; then
  install_or_upgrade "bash-completion"
fi

# hooks/pre-commit lints this repo's shell scripts with it; without it
# the hook prints a note and lets the commit through.
if ask_to_install "shellcheck (shell linter, used by the repo's pre-commit hook)"; then
  install_or_upgrade "shellcheck"
fi

if ask_to_install "ngrok"; then
  install_or_upgrade "ngrok"
fi


echo "------------------------------"
echo "Installing devops tools: HashiCorp vault, Docker, Kubernetes..."

if ask_to_install "HashiCorp tools (Vault)"; then
  brew tap hashicorp/tap
  install_or_upgrade "hashicorp/tap/vault"
fi

if ask_to_install "Docker Desktop, Ansible, and Terraform"; then
  install_or_upgrade "--cask" "docker-desktop"
  install_or_upgrade "ansible"
  brew tap hashicorp/tap
  install_or_upgrade "hashicorp/tap/terraform"
fi

if ask_to_install "colima and the docker CLI (Docker Desktop alternative — same daemon, no GUI, preferred on the Mac mini server)"; then
  install_or_upgrade "colima"
  install_or_upgrade "docker"
fi

if ask_to_install "Kubernetes tools (kubectl, helm, k9s, kind, kubeseal)"; then
  install_or_upgrade "kubernetes-cli"
  install_or_upgrade "helm"
  install_or_upgrade "derailed/k9s/k9s"
  install_or_upgrade "kind"
  install_or_upgrade "kubeseal"
fi

echo "------------------------------"
echo "Installing clouds client: Heroku, Scaleway..."


if ask_to_install "Heroku CLI"; then
  install_or_upgrade "heroku/brew/heroku"
  install_or_upgrade "hivemind"
fi

if ask_to_install "Scaleway CLI"; then
  install_or_upgrade "scw"
fi

if ask_to_install "Cloudflare Tunnel (cloudflared)"; then
  install_or_upgrade "cloudflared"
fi

if ask_to_install "GCP CLI"; then
  install_or_upgrade "--cask" "gcloud-cli"
fi

if ask_to_install "asciinema and asciicast2gif tools"; then
  # cast and gif from terminal
  install_or_upgrade "asciinema"
  npm i -g asciicast2gif
fi

if ask_to_install "Misc CLI tools (macmon, summarize, swiftformat, swiftlint, xcodegen, sentry-wizard, pandoc, terraformer)"; then
  install_or_upgrade "macmon"
  install_or_upgrade "summarize"
  install_or_upgrade "swiftformat"
  install_or_upgrade "swiftlint"
  install_or_upgrade "xcodegen"
  install_or_upgrade "sentry-wizard"
  install_or_upgrade "pandoc"
  install_or_upgrade "terraformer"
fi

if ask_to_install "Local network services (dnsmasq, nginx)"; then
  install_or_upgrade "dnsmasq"
  install_or_upgrade "nginx"
fi

if ask_to_install "databases and datastores"; then
  echo "------------------------------"
  echo "Installing database/datastore: MySQL, PostgreSQL, MongoDB, Redis, Elasticsearch"

  if ask_to_install "MySQL"; then
    install_or_upgrade "mysql"
  fi

  if ask_to_install "PostgreSQL"; then
    # Explicit major: "postgresql" is only an alias for the current one,
    # so the version installed would silently change over time.
    install_or_upgrade "postgresql@18"
  fi

  if ask_to_install "MongoDB"; then
    brew tap mongodb/brew
    # 5.0 reached end of life in October 2024.
    install_or_upgrade "mongodb-community"
  fi

  if ask_to_install "Redis"; then
    install_or_upgrade "redis"
    install_or_upgrade "--cask" "medis"
  fi

  if ask_to_install "Elasticsearch"; then
    brew tap elastic/tap
    install_or_upgrade "elastic/tap/elasticsearch-full"
    install_or_upgrade "elastic/tap/apm-server-full"
  fi
  if ask_to_install "MQTTX"; then
    install_or_upgrade "--cask" "mqttx"
  fi

  # mqttx-cli is not in homebrew/core — it needs its upstream tap, which
  # isn't set up here. install_or_upgrade reports the failure and moves on.
  if ask_to_install "mqttx-cli"; then
    install_or_upgrade "mqttx-cli"
  fi
fi



# API blueprint
# #https://github.com/apiaryio/api-blueprint-sublime-plugin
# Drafter command line tool
# brew install --HEAD \
#   https://raw.github.com/apiaryio/drafter/master/tools/homebrew/drafter.rb

# https://github.com/jamiew/git-friendly
# the `push` command which copies the github compare URL to my clipboard is heaven
#sudo bash < <( curl https://raw.github.com/jamiew/git-friendly/master/install.sh)

# https://github.com/isaacs/nave
# needs npm, obviously.
# TODO: I think i'd rather curl down the nave.sh, symlink it into /bin and use that for initial node install.
#npm install -g nave


if ask_to_install "developer applications"; then
  echo "------------------------------"
  echo "Installing Developer apps: Ghostty, IDEs, Postman..."

  if ask_to_install "Ghostty terminal"; then
    #install_or_upgrade "--cask" "wezterm"
    install_or_upgrade "--cask" "ghostty"
  fi

  if ask_to_install "GPG Suite"; then
    install_or_upgrade "--cask" "gpg-suite"
  fi

  if ask_to_install "sublime text editor"; then
    install_or_upgrade "--cask" "sublime-text"
  fi

  if ask_to_install "VS code"; then
    install_or_upgrade "--cask" "visual-studio-code"
  fi

  if ask_to_install "Zed editor"; then
    install_or_upgrade "--cask" "zed"
  fi

  if ask_to_install "JetBrains IDEs (WebStorm, PhpStorm)"; then
    install_or_upgrade "--cask" "jetbrains-toolbox"
  fi

  if ask_to_install "Postman"; then
    install_or_upgrade "--cask" "postman"
  fi

  if ask_to_install "GitHub Desktop"; then
    install_or_upgrade "--cask" "github"
  fi
fi

if ask_to_install "AI applications"; then
  echo "------------------------------"
  echo "Installing AI apps: Ollama, cursor..."

  install_or_upgrade "--cask" "ollama-app"
  install_or_upgrade "--cask" "chatgpt"
  install_or_upgrade "--cask" "claude"
  install_or_upgrade "--cask" "lm-studio"
  install_or_upgrade "aider"
  install_or_upgrade "--cask" "claude-code"
  install_or_upgrade "--cask" "codex"
  install_or_upgrade "--cask" "codexbar"
  install_or_upgrade "portaudio"
  install_or_upgrade "--cask" "cursor"

  if ask_to_install "OpenHands and specify-cli (via uv tool)"; then
    uv tool install openhands
    uv tool install openhands-acp
    uv tool install specify-cli
  fi
fi


if ask_to_install "miscellaneous applications"; then
  echo "------------------------------"
  echo "Installing Misc apps: browsers, communication tools, productivity apps..."

  if ask_to_install "Web browsers (Chrome, Firefox)"; then
    install_or_upgrade "--cask" "arc"
    install_or_upgrade "--cask" "google-chrome"
    install_or_upgrade "--cask" "firefox"
  fi

  if ask_to_install "Communication tools (Slack, Gitter, Discord)"; then
    install_or_upgrade "--cask" "slack"
    # install_or_upgrade "--cask" "gitter"
    install_or_upgrade "--cask" "discord"
    install_or_upgrade "--cask" "telegram"
    install_or_upgrade "--cask" "zoom"
    install_or_upgrade "--cask" "microsoft-teams"
  fi

  if ask_to_install "Design tools (Figma)"; then
    install_or_upgrade "--cask" "figma"
  fi

  if ask_to_install "Note-taking and productivity apps (Typora, Notion, Miro)"; then
    install_or_upgrade "--cask" "typora"
    install_or_upgrade "--cask" "notion"
    install_or_upgrade "--cask" "miro"
    install_or_upgrade "--cask" "google-drive"
    install_or_upgrade "--cask" "superwhisper"
    # install_or_upgrade "asana"
    # Todo add slab
  fi

  if ask_to_install "Calendar client (Notion calendar)"; then
    install_or_upgrade "--cask" "notion-calendar"
  fi

  if ask_to_install "Productivity tools (Raycast, timing)"; then
    # install_or_upgrade "--cask" "alfred"
    install_or_upgrade "--cask" "raycast"
    install_or_upgrade "--cask" "timing"
  fi


  if ask_to_install "Other personal setup"; then
    if ask_to_install "Music (Spotify)"; then
      install_or_upgrade "--cask" "spotify"
    fi

    if ask_to_install "VLC media player"; then
      install_or_upgrade "--cask" "vlc"
    fi

    if ask_to_install "Raspberry Pi Imager"; then
      install_or_upgrade "--cask" "raspberry-pi-imager"
    fi

    # goplaces is not in homebrew/cask — it ships from a third-party tap
    # that isn't set up here (it is on the Mac mini). The step reports the
    # failure rather than aborting.
    if ask_to_install "Goplaces"; then
      install_or_upgrade "--cask" "goplaces"
    fi

    if ask_to_install "Stats (menu bar system monitor)"; then
      install_or_upgrade "--cask" "stats"
    fi
  fi
fi

if [ "$MACHINE_ROLE" = "workstation" ]; then
  if ask_to_install "Mac App Store applications (mas CLI + Airmail, Office, Keynote/Numbers/Pages, WhatsApp...)"; then
    echo "Note: mas can only install/update apps tied to the Apple ID already signed in via the App Store app — sign in there first if 'mas install' fails with an account error."

    install_or_upgrade "mas"

    mas install 918858936    # Airmail
    mas install 6738511300   # Microsoft Copilot
    mas install 640199958    # Apple Developer
    mas install 6474268307   # Enchanted (Ollama GUI)
    mas install 6636493997   # ExcalidrawZ
    mas install 409183694    # Keynote
    mas install 1480068668   # Messenger
    mas install 462058435    # Microsoft Excel
    mas install 462062816    # Microsoft PowerPoint
    mas install 1289197285   # MindNode 2
    mas install 1218718027   # MindNode Classic
    mas install 409203825    # Numbers
    mas install 823766827    # OneDrive
    mas install 409201541    # Pages
    mas install 1153157709   # Speedtest
    mas install 899247664    # TestFlight
    mas install 1568264476   # TypingLand
    mas install 310633997    # WhatsApp
  fi
else
  echo "Server role: skipping Mac App Store applications (personal/productivity apps, not needed on a headless server)."
fi


# Clean up
if ask_to_install "cleanup of outdated packages"; then
  echo "------------------------------"
  echo "Cleaning up outdated versions from the Homebrew cellar."
  brew cleanup
fi

echo "------------------------------"
echo "Installation complete!"
echo "You may want to restart your terminal to apply all changes."
