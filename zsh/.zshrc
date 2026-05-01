# Keep this file host-neutral. Put machine-specific exports in ~/.zshrc.local.

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  source "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
  source "$NVM_DIR/bash_completion"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

bindkey -v
export KEYTIMEOUT=1

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if [ -r "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
