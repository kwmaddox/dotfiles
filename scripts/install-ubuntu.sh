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

install_neovim() {
  if command -v nvim >/dev/null 2>&1 && [ "${FORCE_SOURCE_BUILD:-0}" != "1" ]; then
    return
  fi

  local url
  url=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
    | python3 -c "import json,sys; r=json.load(sys.stdin); print(next(a['browser_download_url'] for a in r['assets'] if a['name'] == 'nvim-linux-x86_64.tar.gz'))")

  curl -fsSL "$url" | tar -xz -C /tmp
  cp /tmp/nvim-linux-x86_64/bin/nvim "$LOCAL_PREFIX/bin/nvim"
  cp -r /tmp/nvim-linux-x86_64/share/nvim "$LOCAL_PREFIX/share/" 2>/dev/null || true
  rm -rf /tmp/nvim-linux-x86_64
}

build_tmux() {
  if command -v tmux >/dev/null 2>&1 && [ "${FORCE_SOURCE_BUILD:-0}" != "1" ]; then
    return
  fi

  local version
  version=$(curl -fsSL https://api.github.com/repos/tmux/tmux/releases/latest \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])")

  local src="$SRC_DIR/tmux-$version"
  if [ ! -d "$src" ]; then
    curl -fsSL "https://github.com/tmux/tmux/releases/download/$version/tmux-${version#v}.tar.gz" \
      | tar -xz -C "$SRC_DIR"
    mv "$SRC_DIR/tmux-${version#v}" "$src" 2>/dev/null || true
  fi

  (cd "$src" && ./configure --prefix="$LOCAL_PREFIX" && make && make install)
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

if ! command -v cargo-binstall >/dev/null 2>&1; then
  curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
fi

cargo binstall --no-confirm \
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

install_neovim
build_tmux
install_wezterm
install_nerd_font

"$DOTFILES_DIR/scripts/apply.sh" nvim tmux wezterm starship zsh i3 polybar

echo
echo "Ubuntu bootstrap complete."
echo "Make sure $LOCAL_PREFIX/bin and $HOME/.cargo/bin are on PATH before starting i3."
