#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${SRC_DIR:-$HOME/.local/src}"
LOCAL_PREFIX="${LOCAL_PREFIX:-$HOME/.local}"
NVM_VERSION="${NVM_VERSION:-v0.40.3}"

export PATH="$HOME/.cargo/bin:$LOCAL_PREFIX/bin:$PATH"

sudo apt-get update
sudo apt-get install -y \
  autoconf \
  automake \
  bison \
  build-essential \
  ca-certificates \
  cmake \
  curl \
  dex \
  dmenu \
  feh \
  fontconfig \
  gettext \
  git \
  gnupg \
  i3 \
  i3lock \
  i3status \
  libevent-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libssl-dev \
  libx11-dev \
  libxcb1-dev \
  libxkbcommon-dev \
  libxkbcommon-x11-dev \
  libxrandr-dev \
  libxrender-dev \
  libxtst-dev \
  libncurses-dev \
  network-manager-gnome \
  ninja-build \
  nodejs \
  picom \
  pkg-config \
  pulseaudio-utils \
  python3 \
  python3-pip \
  python3-venv \
  rofi \
  stow \
  unzip \
  xclip \
  xorg \
  xsel \
  xss-lock \
  zsh

mkdir -p "$SRC_DIR" "$LOCAL_PREFIX/bin"

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
fi

if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
fi

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default lts/*
fi

build_neovim() {
  if command -v nvim >/dev/null 2>&1 && [ "${FORCE_SOURCE_BUILD:-0}" != "1" ]; then
    return
  fi

  if [ ! -d "$SRC_DIR/neovim/.git" ]; then
    git clone --filter=blob:none --branch stable https://github.com/neovim/neovim "$SRC_DIR/neovim"
  fi

  git -C "$SRC_DIR/neovim" fetch --tags origin stable
  git -C "$SRC_DIR/neovim" checkout stable
  make -C "$SRC_DIR/neovim" CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$LOCAL_PREFIX"
  make -C "$SRC_DIR/neovim" install
}

build_tmux() {
  if command -v tmux >/dev/null 2>&1 && [ "${FORCE_SOURCE_BUILD:-0}" != "1" ]; then
    return
  fi

  if [ ! -d "$SRC_DIR/tmux/.git" ]; then
    git clone https://github.com/tmux/tmux "$SRC_DIR/tmux"
  fi

  git -C "$SRC_DIR/tmux" pull --ff-only
  (cd "$SRC_DIR/tmux" && sh autogen.sh && ./configure --prefix="$LOCAL_PREFIX" && make && make install)
}

install_nerd_font() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  if [ -d "$font_dir" ]; then
    return
  fi

  mkdir -p "$font_dir"
  curl -fsSL -o /tmp/JetBrainsMono.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -o /tmp/JetBrainsMono.zip -d "$font_dir"
  fc-cache -f "$font_dir"
}

install_wezterm() {
  if command -v wezterm >/dev/null 2>&1 && [ "${FORCE_SOURCE_BUILD:-0}" != "1" ]; then
    return
  fi

  if [ "${BUILD_WEZTERM_FROM_SOURCE:-0}" = "1" ]; then
    if [ ! -d "$SRC_DIR/wezterm/.git" ]; then
      git clone --recursive https://github.com/wez/wezterm "$SRC_DIR/wezterm"
    fi
    git -C "$SRC_DIR/wezterm" pull --ff-only
    git -C "$SRC_DIR/wezterm" submodule update --init --recursive
    cargo build --manifest-path "$SRC_DIR/wezterm/Cargo.toml" --release --bin wezterm --bin wezterm-gui
    ln -sf "$SRC_DIR/wezterm/target/release/wezterm" "$LOCAL_PREFIX/bin/wezterm"
    ln -sf "$SRC_DIR/wezterm/target/release/wezterm-gui" "$LOCAL_PREFIX/bin/wezterm-gui"
  else
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | \
      sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y wezterm
  fi
}

cargo install --locked \
  ripgrep \
  fd-find \
  zoxide \
  eza \
  starship

if [ ! -d "$HOME/.fzf/.git" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
fi
"$HOME/.fzf/install" --bin
ln -sf "$HOME/.fzf/bin/fzf" "$LOCAL_PREFIX/bin/fzf"

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

uv tool install ruff || uv tool upgrade ruff
npm config set prefix "$HOME/.local"
npm install -g yaml-language-server

build_neovim
build_tmux
install_wezterm
install_nerd_font

"$DOTFILES_DIR/scripts/apply.sh" nvim tmux wezterm starship zsh i3

echo
echo "Ubuntu bootstrap complete."
echo "Make sure $LOCAL_PREFIX/bin and $HOME/.cargo/bin are on PATH before starting i3."
