
#!/bin/bash

# Symlink each dotfile in the home directory
# TODO : Backup existing dotfile first

for name in .{bash_prompt,exports,aliases,functions,bashrc,zshrc,bash_profile,gitconfig,gitignore_global}; do
  source="$PWD/$name"
  target="$HOME/$name"
  echo "-----> Symlinking $source to $target"
  ln -s "$source" "$target"
done
