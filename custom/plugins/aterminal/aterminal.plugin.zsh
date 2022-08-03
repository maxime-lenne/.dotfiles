# Git provider info
git_provider_promp_info() {
  ZSH_THEME_PROVIDER_PROMPT_PREFIX=""
  ZSH_THEME_PROVIDER_PROMPT_SUFFIX=""
  local REMOTE_ORIGIN_URL=`git config --get remote.origin.url`
  if [[ ! -z "$(echo $REMOTE_ORIGIN_URL | grep 'github')" ]]
  then
    # ZSH_THEME_PROVIDER_PROMPT_PREFIX="github "
    ZSH_THEME_PROVIDER_PROMPT_PREFIX="\uf09b "
  fi
  if [[ ! -z "$(echo $REMOTE_ORIGIN_URL | grep 'gitlab')" ]]
  then
    # ZSH_THEME_PROVIDER_PROMPT_PREFIX="gitlab "
    ZSH_THEME_PROVIDER_PROMPT_PREFIX="\uf296 "
  fi
  if [[ ! -z "$(echo $REMOTE_ORIGIN_URL | grep 'bitbucket')" ]]
  then
    # ZSH_THEME_PROVIDER_PROMPT_PREFIX="bitbucket "
    ZSH_THEME_PROVIDER_PROMPT_PREFIX="\uf171 "
  fi
  echo "$ZSH_THEME_PROVIDER_PROMPT_PREFIX$DOCKER_VERSION$ZSH_THEME_PROVIDER_PROMPT_SUFFIX"
}

local git_provider_info='$(git_provider_promp_info)'

# Docker info
docker_prompt_info() {
  if which docker 2>/dev/null 1>/dev/null && [[ -f "./Dockerfile" ]] ; then
    local DOCKER_VERSION="$(docker -v | awk '{print substr($3, 0, length($3)-1)}')"
    # ZSH_THEME_DOCKER_PROMPT_PREFIX="docker@"
    ZSH_THEME_DOCKER_PROMPT_PREFIX="\uf308 "
    ZSH_THEME_DOCKER_PROMPT_SUFFIX=" "
    echo "$ZSH_THEME_DOCKER_PROMPT_PREFIX$DOCKER_VERSION$ZSH_THEME_DOCKER_PROMPT_SUFFIX"
  fi
}

local docker_info='$(docker_prompt_info)'

# NPM info
npm_prompt_info() {
  if which npm 2>/dev/null 1>/dev/null && [[ -f "./package-lock.json" ]] ; then
    local NPM_VERSION="$(npm -v)"
    # ZSH_THEME_NPM_PROMPT_PREFIX="npm@"
    ZSH_THEME_NPM_PROMPT_PREFIX="\ue71e "
    ZSH_THEME_NPM_PROMPT_SUFFIX=" "
    echo "$ZSH_THEME_NPM_PROMPT_PREFIX$NPM_VERSION$ZSH_THEME_NPM_PROMPT_SUFFIX"
  fi
}

local npm_info='$(npm_prompt_info)'

# Yarn info
yarn_prompt_info() {
 if which yarn 2>/dev/null 1>/dev/null && [[ -f "./yarn.lock" ]] ; then
   local YARN_VERSION="$(yarn -v)"
   ZSH_THEME_YARN_PROMPT_PREFIX="yarn@"
   ZSH_THEME_YARN_PROMPT_SUFFIX=" "
   echo "$ZSH_THEME_YARN_PROMPT_PREFIX$YARN_VERSION$ZSH_THEME_YARN_PROMPT_SUFFIX"
 fi
}

local yarn_info='$(yarn_prompt_info)'

# Node info
node_prompt_info() {
  if which node 2>/dev/null 1>/dev/null && [[ ! -z "$(ls | grep \.js$ | head -1)" ]]; then
    local NODE_VERSION="$(node -v | awk '{print substr($1,2); }')"
    # ZSH_THEME_NODE_PROMPT_PREFIX="node@"
    ZSH_THEME_NODE_PROMPT_PREFIX="\uf898 "
    ZSH_THEME_NODE_PROMPT_SUFFIX=" "
    echo "$ZSH_THEME_NODE_PROMPT_PREFIX$NODE_VERSION$ZSH_THEME_NODE_PROMPT_SUFFIX"
  fi
}

local node_info='$(node_prompt_info)'

# TypeScript info
ts_prompt_info() {
  if which tsc 2>/dev/null 1>/dev/null && [[ ! -z "$(ls | grep '\.ts$' | head -1)" || -f "./tsconfig.json" ]]; then
    local TS_VERSION="$(tsc -v | awk '{print substr($2, 0, length($2))}')"
    # ZSH_THEME_TS_PROMPT_PREFIX="typescript@"
    ZSH_THEME_TS_PROMPT_PREFIX="\ufbe4 "
    ZSH_THEME_TS_PROMPT_SUFFIX=" "
    echo "$ZSH_THEME_TS_PROMPT_PREFIX$TS_VERSION$ZSH_THEME_TS_PROMPT_SUFFIX"
  fi
}

local ts_info='$(ts_prompt_info)'

# Python info
python_prompt_info() {
  if which python 2>/dev/null 1>/dev/null && [[ ! -z "$(ls | grep \.py$ | head -1)" ]]; then
    local PYTHON_VERSION="$(python -c 'import platform; print(platform.python_version())')"
    ZSH_THEME_PYTHON_PROMPT_PREFIX="python@"
    ZSH_THEME_PYTHON_PROMPT_SUFFIX=" "
    echo "$ZSH_THEME_PYTHON_PROMPT_PREFIX$PYTHON_VERSION$ZSH_THEME_PYTHON_PROMPT_SUFFIX"
  fi
}

local python_info='$(python_prompt_info)'

# GVM info
go_prompt_info() {
  if which go 2>/dev/null 1>/dev/null && [[ ! -z "$(ls | grep \.go$ | head -1)" ]]; then
    local GO_VERSION="$(go version | awk '{print $3}')"
    ZSH_THEME_GVM_PROMPT_PREFIX="go@"
    ZSH_THEME_GVM_PROMPT_SUFFIX=" "
    echo "$ZSH_THEME_GVM_PROMPT_PREFIX$GO_VERSION$ZSH_THEME_GVM_PROMPT_SUFFIX"
  fi
}

local go_info='$(go_prompt_info)'

# Elixir info
exl_prompt_info() {
  if which elixir 2>/dev/null 1>/dev/null && [[ ! -z "$(ls | grep '\.ex$' | head -1)" ]] || [[ ! -z "$(ls | grep '\.exs$' | head -1)" ]] ; then
    local EXL_VERSION="$(elixir -v | grep Elixir | awk '{print $2}')"
    # ZSH_THEME_EXL_PROMPT_PREFIX="elixir@"
    ZSH_THEME_EXL_PROMPT_PREFIX="\ue62d "
    ZSH_THEME_EXL_PROMPT_SUFFIX=" "
    echo "$ZSH_THEME_EXL_PROMPT_PREFIX$EXL_VERSION$ZSH_THEME_EXL_PROMPT_SUFFIX"
  fi
}

local exl_info='$(exl_prompt_info)'

# Ruby info
ruby_prompt_info() {
  if which ruby 2>/dev/null 1>/dev/null && [[ ! -z "$(ls | grep \.rb$ | head -1)" ]] || [[ -f 'Gemfile' || -f 'config.rb' || -f '.ruby-version' ]]; then
    local RUBY_VERSION="$(ruby -v | awk '{print $2}')"
    ZSH_THEME_RUBY_PROMPT_PREFIX="\ue739 "
    # ZSH_THEME_RUBY_PROMPT_PREFIX="ruby@"
    ZSH_THEME_RUBY_PROMPT_SUFFIX=" "
    echo "$ZSH_THEME_RUBY_PROMPT_PREFIX$RUBY_VERSION$ZSH_THEME_RUBY_PROMPT_SUFFIX"
  fi
}

local ruby_info='$(ruby_prompt_info)'

# TODO : Rails info
rails_prompt_info() {

}



RPROMPT="${docker_info} ${npm_info}  ${node_info}  ${python_info}  ${go_info}  ${exl_info}  ${ruby_info} "

concat_prompt_info() {
  echo "${docker_info} ${npm_info} ${node_info} ${python_info} ${go_info} ${exl_info} ${ruby_info}"
}
