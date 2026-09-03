#!/bin/bash

# Symlink each dotfile in the home directory

for name in .{aliases,bash_profile,bash_prompt,bashrc,exports,functions,gitconfig,gitignore_global,zshrc}; do
  source="$PWD/$name"
  target="$HOME/$name"
  mv "$target" "$target.backup"
  echo "-----> Symlinking $source to $target"
  ln -s "$source" "$target"
done

# Machine-local secrets. The values live in .env at the root of this repo —
# kept out of every commit by .gitignore — and $HOME gets a symlink named
# .env.local, which is what .exports sources. Same shape as the dotfiles
# above: one file to edit, in the repo, linked into place.
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
