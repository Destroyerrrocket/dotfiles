# dotfiles

Personal zsh setup: oh-my-zsh + powerlevel10k + autosuggestions/syntax-highlighting.

Used with the VS Code Dev Containers **dotfiles** feature so my shell config
follows me into every container without being baked into any project's
`devcontainer.json`.

## Manual install

```bash
git clone <this-repo-url> ~/dotfiles && ~/dotfiles/install.sh
```

## VS Code dotfiles feature

In your **user** `settings.json` (Settings Sync — never in a repo):

```jsonc
"dotfiles.repository": "<owner>/dotfiles",
"dotfiles.installCommand": "install.sh"
```

`install.sh` is idempotent: installs oh-my-zsh, the theme, and the plugins if
missing, then symlinks `.zshrc` and `.p10k.zsh` into `$HOME`.
