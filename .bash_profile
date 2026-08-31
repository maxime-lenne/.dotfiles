# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/maxime-lenne/.docker/bin"
# End of Docker Desktop section.

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

#Ajout des bin Homebrew dans le PATH
export PATH=/usr/local:/usr/local/bin:/usr/local/sbin:$PATH

export GPG_TTY=$(tty)

### Added by the Heroku Toolbelt
export PATH="$PATH:/usr/local/heroku/bin"
export PATH="$PATH:/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin"

complete -C /opt/homebrew/bin/terraform terraform

