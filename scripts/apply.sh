#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${TARGET_DIR:-$HOME}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)}"

if ! command -v stow >/dev/null 2>&1; then
  echo "stow is required. Install it first, then rerun this script." >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  PACKAGES=("$@")
else
  PACKAGES=(nvim tmux wezterm starship zsh)
fi

backup_target() {
  local package="$1"
  local source_path="$2"
  local rel_path="${source_path#"$DOTFILES_DIR/$package/"}"
  local target_path="$TARGET_DIR/$rel_path"

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    if [ -L "$target_path" ] && [ "$(realpath "$target_path" 2>/dev/null || true)" = "$(realpath "$source_path")" ]; then
      return
    fi

    mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
    mv "$target_path" "$BACKUP_DIR/$rel_path"
    echo "Backed up $target_path -> $BACKUP_DIR/$rel_path"
  fi
}

for package in "${PACKAGES[@]}"; do
  if [ ! -d "$DOTFILES_DIR/$package" ]; then
    echo "Unknown package: $package" >&2
    exit 1
  fi

  while IFS= read -r -d '' source_path; do
    backup_target "$package" "$source_path"
  done < <(find "$DOTFILES_DIR/$package" -type f -print0)

  stow --dir="$DOTFILES_DIR" --target="$TARGET_DIR" --restow "$package"
done

echo "Applied packages: ${PACKAGES[*]}"
if [ -d "$BACKUP_DIR" ]; then
  echo "Backups: $BACKUP_DIR"
fi
