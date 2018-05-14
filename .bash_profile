# Load ~/.bash_prompt, ~/.exports, ~/.aliases and ~/.functions
# ~/.extra can be used for settings you don’t want to commit
for file in ~/.{bash_prompt,exports,aliases,functions}; do
	[ -r "$file" ] && source "$file"
done
unset file


#init git autocompletation
source $(brew --prefix)/etc/bash_completion.d/git-completion.bash
#source $(brew --prefix)/etc/bash_completion.d/hub.bash_completion.sh
if [ -f $(brew --prefix)/etc/bash_completion ]; then
. $(brew --prefix)/etc/bash_completion
fi

#JDK1.7
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-10.0.1.jdk/Contents/Home/"
export PATH=$PATH:$JAVA_HOME/bin:$PATH

#Ajout des bin Homebrew dans le PATH
export PATH=/usr/local:/usr/local/bin:/usr/local/sbin:$PATH

# init rvm (/!\ in the bottom of bash_profile)

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

export GPG_TTY=$(tty)

### Added by the Heroku Toolbelt
export PATH="$PATH:/usr/local/heroku/bin"
export PATH="$PATH:/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin"
