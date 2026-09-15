#!/bin/bash

# Symlink each dotfile into the home directory.
#
# The list shrank on 2026-09-15: .aliases, .exports, .functions and
# .bash_prompt moved into shell/, which .zshrc and .bashrc reach through
# shell/index.sh. $HOME keeps three shell files instead of nine.

DOTFILES_DIR="$PWD"

# Symlinks this script used to create and no longer should. Left in place
# they would dangle, since their targets no longer exist in the repo.
# Only removed when they really are OUR symlink: a real file means a
# machine that was never set up this way, and it is not ours to delete.
for name in .aliases .exports .functions .bash_prompt; do
  link="$HOME/$name"
  if [ -L "$link" ] && [ ! -e "$link" ]; then
    echo "-----> Removing the now-dangling $link"
    rm "$link"
  elif [ -L "$link" ] && case "$(readlink "$link")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
    echo "-----> Removing $link (moved into shell/)"
    rm "$link"
  elif [ -e "$link" ]; then
    echo "-----> Leaving $link alone: a real file, not one of ours"
  fi
done

for name in .bashrc .bash_profile .zshrc .gitconfig .gitignore_global; do
  source="$DOTFILES_DIR/$name"
  target="$HOME/$name"

  # Idempotent since 2026-09-15 (the TODO this file used to carry): an
  # unconditional `mv` errored when the target did not exist yet and
  # overwrote the previous backup on every re-run. This change forces a
  # re-run on both machines, so it had to be fixed first.
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    echo "-----> $target already points at $source"
    continue
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    backup="$target.backup.$(date +%Y%m%d%H%M%S)"
    echo "-----> Backing up $target to $backup"
    mv "$target" "$backup"
  fi
  echo "-----> Symlinking $source to $target"
  ln -s "$source" "$target"
done

# Machine-local secrets. The values live in .env at the root of this repo —
# kept out of every commit by .gitignore — and $HOME gets a symlink named
# .env.local, which is what shell/index.sh sources. Same shape as the
# dotfiles above: one file to edit, in the repo, linked into place.
# Note the asymmetry with the rest: .env is deliberately NOT versioned, so
# a fresh clone has none and it is seeded from .env.example.
env_file="$PWD/.env"
env_link="$HOME/.env.local"

if [ ! -e "$env_file" ]; then
  if [ -f "$env_link" ] && [ ! -L "$env_link" ]; then
    # A real file left by an earlier setup: move it in rather than lose the
    # secrets it may already hold.
    echo "-----> Moving the existing $env_link into $env_file"
    mv "$env_link" "$env_file"
  else
    echo "-----> Creating $env_file from .env.example"
    cp "$PWD/.env.example" "$env_file"
  fi
fi
chmod 600 "$env_file"

# Unlike the loop above, this one does not clobber: .env.local is the only
# copy of the secrets on a machine that has not been set up this way yet.
if [ -L "$env_link" ] && [ "$(readlink "$env_link")" = "$env_file" ]; then
  echo "-----> $env_link already points at $env_file"
else
  if [ -e "$env_link" ] || [ -L "$env_link" ]; then
    echo "-----> Backing up $env_link to $env_link.backup"
    mv "$env_link" "$env_link.backup"
  fi
  echo "-----> Symlinking $env_file to $env_link"
  ln -s "$env_file" "$env_link"
fi

# Point git at the repo's own hooks/ directory. core.hooksPath lives in
# .git/config, which isn't versioned, so a fresh clone needs this run
# once before hooks/pre-commit (shellcheck) does anything.
echo "-----> Enabling the repo's git hooks (hooks/)"
git -C "$PWD" config core.hooksPath hooks
