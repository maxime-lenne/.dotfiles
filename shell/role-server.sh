# shellcheck shell=bash
# shell/role-server.sh — loaded by shell/index.sh when MACHINE_ROLE is
# "server" (the Mac mini).
#
# Deliberately almost empty. It exists so index.sh can source
# "role-$MACHINE_ROLE.sh" without a conditional, and so there is an obvious
# home for the first headless-only need that shows up (colima helpers,
# remote administration shortcuts). Do not delete it for being empty.
:
