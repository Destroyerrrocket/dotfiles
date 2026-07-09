#!/usr/bin/env bash
# Personal dotfiles installer.
#
# VS Code's Dev Containers "dotfiles" feature clones this repo into every
# container and runs this script. It installs oh-my-zsh (if missing), the
# powerlevel10k theme, the zsh-autosuggestions / zsh-syntax-highlighting
# plugins, then symlinks .zshrc and .p10k.zsh into $HOME. Safe to re-run.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

clone_if_missing() {
	local url="$1" dest="$2"
	if [[ ! -d "$dest" ]]; then
		git clone --depth=1 "$url" "$dest"
	fi
}

# oh-my-zsh (unattended so it doesn't overwrite our .zshrc or launch a shell)
if [[ ! -d "$ZSH_DIR" ]]; then
	RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Theme + plugins
clone_if_missing https://github.com/romkatv/powerlevel10k.git       "$CUSTOM/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git "$CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM/plugins/zsh-syntax-highlighting"

# Symlink configs (back up any pre-existing real files first)
link() {
	local src="$1" dst="$2"
	if [[ -e "$dst" && ! -L "$dst" ]]; then
		mv "$dst" "$dst.bak.$$"
	fi
	ln -sfn "$src" "$dst"
}

link "$DOTFILES_DIR/.zshrc"   "$HOME/.zshrc"
link "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

# ---------------------------------------------------------------------------
# Persist zsh history across dev container rebuilds (repo-agnostic).
#
# A container's filesystem is wiped on rebuild, so $HOME/.zsh_history is lost.
# The only host-backed location that survives without editing the container's
# devcontainer.json is the workspace bind mount under /workspaces. Point
# HISTFILE there via ~/.zshenv, which zsh sources before oh-my-zsh — whose own
# `[ -z "$HISTFILE" ]` guard then leaves our choice intact. Uses whatever repo
# happens to be mounted, so it works in any dev container.
persist_history() {
	local ws="" d
	for d in /workspaces/*/; do
		[[ -d "$d" ]] && { ws="${d%/}"; break; }
	done
	[[ -n "$ws" ]] || return 0   # not a /workspaces dev container; skip

	local histfile gitdir
	if gitdir="$(git -C "$ws" -c safe.directory='*' rev-parse --absolute-git-dir 2>/dev/null)"; then
		histfile="$gitdir/.zsh_history"   # inside .git -> invisible to `git status`
	else
		histfile="$ws/.zsh_history"       # not a repo: a dotfile on the mount
	fi

	local marker="# persist-history (dotfiles)"
	if ! grep -qsF "$marker" "$HOME/.zshenv"; then
		printf '%s\nexport HISTFILE=%s\n' "$marker" "\"$histfile\"" >> "$HOME/.zshenv"
	fi
	touch "$histfile" 2>/dev/null || true
}
persist_history

echo "dotfiles installed."
