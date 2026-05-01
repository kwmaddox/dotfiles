# Dotfiles

Stow-managed configuration for:

- Neovim
- tmux
- WezTerm
- Starship
- zsh
- i3

The theme baseline is Catppuccin Mocha across the editor, terminal, prompt,
tmux, and i3.

## Layout

Each top-level directory is a GNU Stow package:

```text
nvim/.config/nvim
tmux/.tmux.conf
wezterm/.wezterm.lua
starship/.config/starship.toml
zsh/.zshrc
i3/.config/i3/config
```

## Apply Dotfiles

Apply the default workstation packages:

```sh
./scripts/apply.sh
```

Apply a specific set:

```sh
./scripts/apply.sh nvim tmux wezterm starship zsh
./scripts/apply.sh i3
```

The apply script backs up conflicting files into:

```text
~/.dotfiles-backup/<timestamp>
```

## Bootstrap macOS

```sh
./scripts/install-macos.sh
```

This installs Homebrew if needed, installs the main CLI/GUI dependencies, then
applies the non-Linux dotfile packages.

## Bootstrap Ubuntu

```sh
./scripts/install-ubuntu.sh
```

The Ubuntu script targets 22.04 or newer. It uses apt for OS and i3 desktop
components, cargo/source installs for fast-moving CLI tools, and source builds
for Neovim and tmux when missing.

By default WezTerm is installed from its official apt repository. To build it
from source instead:

```sh
BUILD_WEZTERM_FROM_SOURCE=1 ./scripts/install-ubuntu.sh
```

To force Neovim and tmux source rebuilds:

```sh
FORCE_SOURCE_BUILD=1 ./scripts/install-ubuntu.sh
```

## Local Overrides

Keep machine-specific shell settings out of this repo. Put them in:

```text
~/.zshrc.local
```

That file is sourced by the managed `.zshrc` if present.
