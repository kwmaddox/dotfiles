#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

brew update
brew install \
  stow \
  git \
  zsh \
  neovim \
  tmux \
  starship \
  ripgrep \
  fd \
  fzf \
  zoxide \
  eza \
  node \
  uv \
  ruff \
  yaml-language-server

brew install --cask \
  wezterm \
  font-jetbrains-mono-nerd-font

"$DOTFILES_DIR/scripts/apply.sh" nvim tmux wezterm starship zsh

echo
echo "macOS bootstrap complete."
echo "Open a new shell or run: exec zsh"
