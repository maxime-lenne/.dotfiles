#!/bin/bash

# Symlink each dotfile in the home directory
# TODO : Backup existing dotfile first

for name in .{aliases,bash_profile,bash_prompt,bashrc,exports,functions,gitconfig,gitignore_global,zshrc}; do
  source="$PWD/$name"
  target="$HOME/$name"
  mv "$target" "$target.backup"
  echo "-----> Symlinking $source to $target"
  ln -s "$source" "$target"
done

# Point git at the repo's own hooks/ directory. core.hooksPath lives in
# .git/config, which isn't versioned, so a fresh clone needs this run
# once before hooks/pre-commit (shellcheck) does anything.
echo "-----> Enabling the repo's git hooks (hooks/)"
git -C "$PWD" config core.hooksPath hooks
