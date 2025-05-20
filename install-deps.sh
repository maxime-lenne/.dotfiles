#!/bin/bash

# Function to ask user if they want to install a section
ask_to_install() {
  local section_name=$1
  read -p "Do you want to install $section_name? (y/n): " choice
  case "$choice" in
    y|Y ) return 0;;
    * ) return 1;;
  esac
}

function install_or_upgrade {
  if [[ "$1" == "--cask" ]]; then
    local cask_flag="--cask"
    local package=$2
  else
    local cask_flag=""
    local package=$1
  fi

  if [[ "$cask_flag" == "--cask" ]]; then
    brew list --cask | grep $package > /dev/null
  else
    brew ls | grep $package > /dev/null
  fi

  if (($? == 0)); then
    brew upgrade $cask_flag $package
  else
    brew install $cask_flag $package
  fi
}

echo "Welcome to the dotfiles installation script!"
echo "This script will guide you through installing various development tools and applications."
echo "You can choose which sections to install."
echo ""

# Install homebrew
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

sudo chown -R $(whoami):admin /opt/homebrew

echo "------------------------------"
echo "Installing Xcode Command Line Tools."
xcode-select --install
sudo xcodebuild -license accept

echo "------------------------------"
echo "Installing basic libraries..."
sudo chown -R $USER:admin /usr/local
install_or_upgrade "openssl"
install_or_upgrade "libxml2"
install_or_upgrade "libxslt"
install_or_upgrade "libiconv"

echo "------------------------------"
echo "fonts and terminal customization"

# fonts
install_or_upgrade "--cask" "font-hack-nerd-font"

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
gem install colorls

echo "------------------------------"
echo "image and media tools"

#image optim
install_or_upgrade "ghostscript"
install_or_upgrade "imagemagick"
install_or_upgrade "gifsicle jhead jpegoptim jpeg optipng pngcrush pngquant"
install_or_upgrade "ffmpeg"


echo "------------------------------"
echo "Installing Java, NPM, rvm, ruby, rails, elixir"

if ask_to_install "Java"; then
  install_or_upgrade "--cask" "java"
fi

if ask_to_install "Node.js and npm packages"; then
  # install nvm
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  exec bash -l
  nvm install --lts
  exec bash -l
  npm install -g npm@latest
  install_or_upgrade "yarn"
fi

if ask_to_install "Python"; then
  install_or_upgrade "pyenv"
  pyenv install -v 3.13.3
  pyenv global 3.13.3
fi


if ask_to_install "Ruby and Rails"; then
  # https://rvm.io
  \curl -sSL https://get.rvm.io | bash -s stable --rails
  gem install bundler pry hub
  gem install rails
  gem install jekyll
fi

if ask_to_install "Elixir"; then
  install_or_upgrade "elixir"
  mix local.hex
  mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez
fi

if ask_to_install "PHP Composer"; then
  install_or_upgrade "composer"
fi


echo "------------------------------"
echo "Installing developer tools: Git and bash completion."

if ask_to_install "Git and GitHub CLI"; then
  install_or_upgrade "git"
  install_or_upgrade "hub"
  install_or_upgrade "gh"
fi

if ask_to_install "Git tools (lolcommits, gitmoji)"; then
  gem install lolcommits
  gem install lolcommits-slack
  npm i -g gitmoji-cli
fi

if ask_to_install "Bash completion and "; then
  install_or_upgrade "bash-completion"
fi

if ask_to_install "ngrok "; then
  install_or_upgrade "ngrok"
fi
ngrok


echo "------------------------------"
echo "Installing devops tools: HashiCorp vault, Docker, Kubernetes..."

if ask_to_install "HashiCorp tools (Vault)"; then
  brew tap hashicorp/tap
  arch -arm64 brew install hashicorp/tap/vault
fi

if ask_to_install "Docker, Ansible, and Terraform"; then
  install_or_upgrade "docker"
  install_or_upgrade "ansible"
  install_or_upgrade "terraform"
fi

if ask_to_install "Kubernetes tools (kubectl, helm, k9s)"; then
  install_or_upgrade "kubectl"
  install_or_upgrade "helm"
  install_or_upgrade "derailed/k9s/k9s"
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

if ask_to_install "asciinema and asciicast2gif tools"; then
  # cast and gif from terminal
  install_or_upgrade "asciinema"
  npm i -g asciicast2gif
fi

if ask_to_install "databases and datastores"; then
  echo "------------------------------"
  echo "Installing database/datastore: MySQL, PostgreSQL, MongoDB, Redis, Elasticsearch"

  if ask_to_install "MySQL"; then
    install_or_upgrade "mysql"
  fi

  if ask_to_install "PostgreSQL"; then
    install_or_upgrade "postgresql"
  fi

  if ask_to_install "MongoDB"; then
    brew tap mongodb/brew
    install_or_upgrade "mongodb-community@5.0"
  fi

  if ask_to_install "Redis"; then
    install_or_upgrade "redis"
    install_or_upgrade "--cask""medis"
  fi

  if ask_to_install "Elasticsearch"; then
    brew tap elastic/tap
    install_or_upgrade "elastic/tap/elasticsearch-full"
    install_or_upgrade "elastic/tap/apm-server-full"
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
  echo "Installing Developer apps: Hyper terminal, Atom, IDEs..."

  if ask_to_install "Hyper terminal"; then
    install_or_upgrade "--cask" "hyper"
    hyper i hyper-electron-highlighter
  fi

  if ask_to_install "GPG Suite"; then
    install_or_upgrade "--cask" "gpg-suite"
  fi

  if ask_to_install "Atom editor"; then
    install_or_upgrade "--cask" "atom"
    apm install file-icons
  fi

  if ask_to_install "VS code"; then
    install_or_upgrade "--cask" "visual-studio-code"
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

if ask_to_install "nocode applications"; then
  echo "------------------------------"
  echo "Installing nocode apps: Airtable..."

  install_or_upgrade "--cask" "airtable"
fi

if ask_to_install "AI applications"; then
  echo "------------------------------"
  echo "Installing AI apps: Ollama, cursor..."

  install_or_upgrade "--cask" "ollama"
  install_or_upgrade "--cask" "lm-studio"
  install_or_upgrade "aider"
  install_or_upgrade "cursor"
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
    install_or_upgrade "--cask" "gitter"
    install_or_upgrade "--cask" "discord"
    install_or_upgrade "--cask" "telegram"
    install_or_upgrade "--cask" "zoom"
    install_or_upgrade "--cask" "microsoft-teams"
  fi

  if ask_to_install "Design tools (Figma)"; then
    install_or_upgrade "--cask" "figma"
  fi

  if ask_to_install "Note-taking and productivity apps (Evernote, Typora, Notion, Miro)"; then
    install_or_upgrade "--cask" "evernote"
    install_or_upgrade "--cask" "typora"
    install_or_upgrade "--cask" "notion"
    install_or_upgrade "--cask" "miro"
    install_or_upgrade "--cask" "superwhisper"
    # install_or_upgrade "asana"
    # Todo add slab
  fi

  if ask_to_install "Email client (Notion mail)"; then
    install_or_upgrade "--cask" "notion-mail"
  fi

  if ask_to_install "Calendar client (Notion calendar)"; then
    install_or_upgrade "--cask" "notion-calendar"
  fi

  if ask_to_install "Productivity tools (Raycast, timing)"; then
    # brew install --cask alfred
    install_or_upgrade "--cask" "raycast"
    install_or_upgrade "--cask" "timing"
  fi


  if ask_to_install "Other personal setup"; then
    if ask_to_install "Music (Spotify)"; then
      install_or_upgrade "--cask" "spotify"
    fi
  fi
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
