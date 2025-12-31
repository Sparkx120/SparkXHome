# SparkXHome Environment

This is a home environment configuration system that implements my own variation of dot files + system configuration all in one.
It has a basic plugin architecture but is still very much in a beta/alpha state and built primarily for my own use.

If you would like to try it out feel free!

## System Requirements

- Arch Linux or Debian Linux
- git

## Features

- git managed dotfiles based on this repo (if you want them to be different you will have to fork)
  - .config/
    - alacritty
    - cava
    - i3
    - i3status
    - mc
    - sway
  - .tmux/
    - tmux-sensible
    - tmux-themepack
    - tpm
    - tmux-powerline
  - .vim/
    - ale
    - copilor.vim
    - fu.vim
    - nerdtree
    - rust.vim
    - tabluar
    - vim-airline-themes
    - vim-airline
    - vim-fugitive
    - vim-javascript
    - vim-jsx-pretty
    - vim-markdown
    - vim-minimap
    - vim-ollama
    - vimwiki
    - Vundle.vim # Planning on moving entirely to vim's built in package management
  - .bash_aliases
  - .bashrc
  - .hostart.txt
  - .motd.sh
  - .tmux.conf
  - .vimrc
- git managed bash scripts and aliases
- A full bash environment with various helper functions namespaced under sparkx-
- System Initialization
  - Standard Packages for each distro supported
  - System Setup
