# shellcheck shell=bash
# shell/aliases.sh — was ~/.aliases until 2026-09-15.
# Role-independent only; GUI and kubeconfig aliases are in
# shell/role-workstation.sh.

# Easier navigation: .., ..., ~ and -
alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

alias ls='ls -AGl'
alias tree='tree -CA'

# IP addresses. en0 since 2026-09-15: these targeted en1, which has had no
# address on either machine — en0 is the live interface.
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"

alias whois="whois -h whois-servers.net"

# Flush the DNS cache. dscacheutil alone stopped being enough years ago:
# mDNSResponder keeps its own cache (second half added 2026-09-15).
alias flush="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"

alias trimcopy="tr -d '\n' | pbcopy"
alias cleanup="find . -name '*.DS_Store' -type f -ls -delete"
alias fs="stat -f \"%z bytes\""
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; rm -rfv ~/.Trash"

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec \$SHELL -l"

# Laravel. Kept although php/composer are absent (2026-09-15): it resolves
# vendor/bin/sail inside a project, so it costs nothing until one exists.
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'

# Removed 2026-09-15, each verified absent or broken on the machine:
#   find=gfind          findutils is not installed and install-deps.sh never
#                       installed it, so this alias made `find` unusable.
#   sniff, httpdump     ngrep absent, and both listened on en1 (no address).
#   ftp_server_*        /System/Library/LaunchDaemons/ftp.plist no longer
#                       ships with macOS.
#   postgresql_server_*, redis_*
#                       no such plist present; `brew services` is the way.
#   undopush            `git push -f origin HEAD^:master` — a force-push with
#                       the branch hardcoded.
#   md5sum              a commented-out line that had never run.
#   ips                 not dropped, relocated to shell/functions.sh — an
#                       alias can't use $1 (SC2142).
