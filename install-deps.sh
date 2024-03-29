# up to you (me) if you want to run this as a file or copy paste at your leisure

#install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

function install_or_upgrade { brew ls | grep $1 > /dev/null; if (($? == 0)); then brew upgrade $1; else brew install $1; fi }


#echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile

sudo chown -R $USER:admin /usr/local

echo "------------------------------"
echo "Installing Xcode Command Line Tools."
xcode-select --install


install_or_upgrade "openssl"
install_or_upgrade "libxml2"
install_or_upgrade "libxslt"
install_or_upgrade "libiconv"

echo "------------------------------"
echo "Installing Java, NPM, rvm, ruby, rails, elixir"
# install languages
brew install --cask java


# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
nvm install --lts
#nvm
npm install -g npm@latest
install_or_upgrade "yarn"

npm install -g coffee-script
# npm install -g grunt-cli
npm install -g jshint
npm install -g less

# https://rvm.io
# rvm for the rubiess
curl -L https://get.rvm.io | bash -s stable --ruby
gem install bundler pry hub

gem install rails

gem install jekyll

# elixir
install_or_upgrade "elixir"
mix local.hex
mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez

install_or_upgrade "composer"


echo "------------------------------"
echo "Installing developer tools : Git and bash completion."
# install git
install_or_upgrade "git"
install_or_upgrade "hub"
install_or_upgrade "gh"

# bash completion
install_or_upgrade "bash-completion"
install_or_upgrade "heroku/brew/heroku"

brew tap hashicorp/tap
# brew install hashicorp/tap/vault
arch -arm64 brew install hashicorp/tap/vault

install_or_upgrade "docker"
install_or_upgrade "ansible"
install_or_upgrade "terraform"

# fonts
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

#Ho my zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
gem install colorls

gem install lolcommits
gem install lolcommits-slack

install_or_upgrade "hivemind"

#image optim
install_or_upgrade "imagemagick"
install_or_upgrade "advancecomp gifsicle jhead jpegoptim jpeg optipng pngcrush pngquant"
install_or_upgrade "ffmpeg"

# cast and gif from terminal
install_or_upgrade "asciinema"
npm i -g asciicast2gif

npm i -g gitmoji-cli

echo "------------------------------"
echo "Installing database/datastore: postgresql, mongoDB, Redis"

install_or_upgrade "mysql"
install_or_upgrade "postgresql"
brew tap mongodb/brew
install_or_upgrade "mongodb-community@5.0"
install_or_upgrade "redis"
brew tap elastic/tap
install_or_upgrade "elastic/tap/elasticsearch-full"
install_or_upgrade "elastic/tap/apm-server-full"



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


echo "------------------------------"
echo "Installing Developer apps : hyper term, atom..."
brew install --cask hyper
hyper i hyper-electron-highlighter

apm install file-icons

brew install --cask gpg-suite
brew install --cask authy

# install sublime 3
# and package control :
# https://packagecontrol.io/installation#st3

# Package controle installé :
# monokai extended
# Sublime Linter3
# markdown extended
# api blueprint
brew install --cask --appdir="/Applications" atom
brew install --cask webstorm
brew install --cask phpstorm

brew install --cask postman

brew install --cask github


echo "------------------------------"
echo "Installing Misc apps: chrome, firefox, slack, evernote..."
# Misc casks
brew install --cask --appdir="/Applications" google-chrome
brew install --cask --appdir="/Applications" firefox

brew install --cask --appdir="/Applications" slack
brew install --cask --appdir="/Applications" gitter
brew install --cask --appdir="/Applications" discord

brew install --cask figma

brew install --cask --appdir="/Applications" evernote
brew install --cask --appdir="/Applications" typora
brew install --cask notion
brew install --cask miro
brew install --cask asana
# Todo add slab

brew install --cask --appdir="/Applications" airmail
brew install --cask alfred

brew install --cask spotify


# homebrew!
# you need the code CLI tools YOU FOOL.
ruby <(curl -fsSkL raw.github.com/mxcl/homebrew/go)

# https://github.com/rupa/z
# z, oh how i love you
#mkdir -p ~/code/z
#curl https://raw.github.com/rupa/z/master/z.sh > ~/code/z/z.sh
#chmod +x ~/code/z/z.sh
# also consider moving over your current .z file if possible. it's painful to rebuild :)


# add this to the bash_profile file if it aint there.
#   . ~/code/z/z.sh


# Remove outdated versions from the cellar.
brew cleanup
