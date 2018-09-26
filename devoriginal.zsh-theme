function collapse_pwd {
  echo $(pwd | sed -e "s,^$HOME,~,")
}

PROMPT='%{$fg_bold[red]%}%n%{$reset_color%} at %B%{%F{172}%}%m%{$reset_color%}%B %{%F{226}%}$(collapse_pwd) $(git_prompt_info) $(rvm_prompt_info):$reset_color
> '
#End line
RPS1=''
# git theming
ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}on %B%{%F{141}%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%B"
ZSH_THEME_GIT_PROMPT_CLEAN="$fg_bold[green] ✔$reset_color"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%} ✗$reset_color"
ZSH_THEME_RVM_PROMPT_PREFIX="%{$reset_color%}with %B%{%F{141}%}"
ZSH_THEME_RVM_PROMPT_SUFFIX="%{$reset_color%}%B"
