# Put your custom themes in this folder.
# Example:

# # -Solarized theme (https://github.com/altercation/solarized/)

function user_info {
  echo "%B%{%F{160}%}%n@%m%f%b"
}

function pwd_info {
  CURRENT_PATH="$(pwd | sed -e 's,^$HOME,~,' )"
  echo " %B%{%F{166}%}$CURRENT_PATH%f%b"
}
function git_info() {
  if [ -z "$(git_prompt_info)" ]
  then
        echo ""
  else
        echo " $(git_prompt_info)"
  fi
}
function env_info {
  if [ -z "$(docker_prompt_info)" ] && [ -z "$(ruby_prompt_info)" ] && [ -z "$(npm_prompt_info)" ] && [ -z "$(yarn_prompt_info)" ] && [ -z "$(node_prompt_info)" ] && [ -z "$(ts_prompt_info)" ] && [ -z "$(exl_prompt_info)" ];
  then
        echo ""
  else
        echo " with %B%{%F{33}%}( $(docker_prompt_info)$(ruby_prompt_info)$(npm_prompt_info)$(yarn_prompt_info)$(node_prompt_info)$(ts_prompt_info)$(exl_prompt_info))%f%b"
  fi
}

# $(rvm_prompt_info)
PROMPT='$(user_info)$(pwd_info) $(git_provider_promp_info)$(git_info)$(env_info)%{$reset_color%} :
🚀  %{$reset_color%}'
#End line
RPS1=""

# git theming
ZSH_THEME_GIT_PROMPT_PREFIX="\ue725 %B%{%F{136}%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f%b"
ZSH_THEME_GIT_PROMPT_CLEAN="%B%{%F{37}%} ✔%f%b"
ZSH_THEME_GIT_PROMPT_DIRTY="%B%{%F{160}%} ✗%f%b"
ZSH_THEME_PROVIDER_PROMPT_PREFIX="\uf09b "
ZSH_THEME_PROVIDER_PROMPT_PREFIX="\uf296 "
ZSH_THEME_PROVIDER_PROMPT_PREFIX="\uf171 "
ZSH_THEME_DOCKER_PROMPT_PREFIX="\uf308 "
ZSH_THEME_NPM_PROMPT_PREFIX="\ue71e "
ZSH_THEME_YARN_PROMPT_PREFIX="yarn@"
ZSH_THEME_NODE_PROMPT_PREFIX="\uf898 "
ZSH_THEME_TS_PROMPT_PREFIX="\ufbe4 "
ZSH_THEME_EXL_PROMPT_PREFIX="\ue62d "
ZSH_THEME_RUBY_PROMPT_PREFIX="\ue739 "
# ZSH_THEME_RVM_PROMPT_PREFIX="%B%{%F{226}%}"
# ZSH_THEME_RVM_PROMPT_SUFFIX="%{$reset_color%}%B"
