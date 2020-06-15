
#!/bin/bash

# Symlink each dotfile in the home directory
# TODO : Backup existing dotfile first

for name in .{aliases,bash_profile,bash_prompt,bashrc,exports,functions,gitconfig,gitignore_global,zshrc}; do
  source="$PWD/$name"
  target="$HOME/$name"
  echo "-----> Symlinking $source to $target"
  ln -s "$source" "$target"
done

ln -s .dotfiles/custom .oh-my-zsh/custom
