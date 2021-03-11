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
#install languages
brew cask install java
# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
install_or_upgrade "yarn"

npm install -g coffee-script
#npm install -g grunt-cli
npm install -g jshint
npm install -g less
gem install jekyll

# https://rvm.io
# rvm for the rubiess
curl -L https://get.rvm.io | bash -s stable --ruby
gem install bundler pry hub
# gem install yarn
gem install rails

# elixir
install_or_upgrade "elixir"
mix local.hex
mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez

echo "------------------------------"
echo "Installing developer tools : Git and bash completion."
# install git
install_or_upgrade "git"
install_or_upgrade "hub"

# bash completion
install_or_upgrade "bash-completion"
install_or_upgrade "heroku/brew/heroku"

# fonts
brew tap homebrew/cask-fonts
brew cask install font-hack-nerd-font

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
npm install --global asciicast2gif

echo "------------------------------"
echo "Installing Daveloper apps : hyper term, atom..."
brew cask install hyper
hyper i hyper-electron-highlighter

brew cask install --appdir="/Applications" atom
apm install file-icons

brew cask install postman

# install sublime 3
# and package control :
# https://packagecontrol.io/installation#st3

# Package controle installé :
# monokai extended
# Sublime Linter3
# markdown extended
# api blueprint


echo "------------------------------"
echo "Installing Misc apps: chrome, firefox, slack, evernote..."
# Misc casks
brew cask install --appdir="/Applications" google-chrome
brew cask install --appdir="/Applications" firefox
brew cask install --appdir="/Applications" slack
brew cask install --appdir="/Applications" evernote


echo "------------------------------"
echo "Installing database/datastore: postgresql, mongoDB, Redis"
#brew install mysql
install_or_upgrade "postgresql"
install_or_upgrade "mongo"
install_or_upgrade "redis"
install_or_upgrade "elasticsearch"



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
