# dotfiles

gotta save them somewhere.

## What's in here

### Shell configs

- `mac.zshrc` — primary shell config on macOS. Path setup, aliases (`gs`, `ll`, `bp`, `reload`, `k`, `cod`, `awslogin`, `dockerlogin`), a custom prompt with git status, and functions: `gp` (git push with macOS alert on failure), `gc` (commit with `-n`), `get` (clone from GitHub into `~/code/<org>/<repo>` and set the right git email based on org), `be` (cd into a project by short name, looking through `~/.be_dirs` and `~/code/*`), `alert`, `title`, `honeycomb-whoami`, `aws-whoami`, plus a `claude` wrapper that runs Claude Code with OTel telemetry pointed at Honeycomb.
- `starship.toml.tmpl` → `starship.toml` — the [starship](https://starship.rs) prompt config. **Edit the `.tmpl`**, then run `bin/starship-colors --write-default` to regenerate `starship.toml` (generated, never hand-edited; linked into `~/.config/starship.toml`). Replaced the hand-rolled `vcs_info` prompt in `mac.zshrc` in August 2026; the old prompt is still in there, commented out, one line away from being restored. The left prompt is a powerline chain of color blocks — clock → directory (repo-relative, repo name bold) → git branch → git status — with 🌞 staged / ⏿ unstaged / 📦 stash-exists / `⇡n` unpushed commits; then mid-rebase state, command duration past 2s, decoded exit codes (`✘ SIGINT`) on failure only, and a green-or-red `$`. A right-hand prompt shows language versions only in a directory that uses them. **Needs a Nerd Font** — see `bin/iterm-set-font`.
- `mac.bash_profile` — older bash version of the mac config. Mostly historical now that zsh is the default.
- `windows-wsl-ubuntu.bashrc` — bash config for WSL Ubuntu environments.
- `aliases.sh` — early/standalone alias file with `be` and `get` in their original bash form.

### Git

- `one-time-git-setup.sh` — run once after cloning. Sets up global git aliases (`ll`, `ff`, `fix`, `home`, `note`, `jsdiff`), user name/email, and points `core.excludesFile` at `gitexcludes`.
- `gitexcludes` — global gitignore (carrot files, `.be`, `.DS_Store`, swap files, `.tool-versions`, project-local `.claude/settings.local.json`).
- `.gitexclude` — repo-local exclude.

### `bin/` — scripts on PATH

- `get` — clone a GitHub repo into `~/code/<org>/<repo>`.
- `ff` — fast-forward the current branch, stashing uncommitted work first if needed.
- `grb` — list recent remote branches sorted by activity, skipping bot commits.
- `pr` — open a pull request against the default branch from the current branch.
- `issue` — open the "new issue" page for the current repo's GitHub remote.
- `github-diff` — open GitHub's compare view between two refs.
- `setversion` — bump a snapshot version in `package.json` against a branch tag.
- `iterm-set-font` — set the font on *every* iTerm2 profile at once (13 of them here), preserving each profile's point size. iTerm2 has no global font setting, and it rewrites its whole plist on quit, so this must be run from Terminal.app with iTerm2 closed — the script refuses otherwise. `--list` shows installed Nerd Font PostScript names. Its header comment is the full story, including why newly installed fonts may need a restart before they render.
- `starship-colors` — renders `starship.toml.tmpl` with the 7 rainbow-chain colors taken from `STARSHIP_*_BG/FG` env vars (unset ones keep their defaults) and prints the path of the result, cached in `$TMPDIR/starship-colors/`. For a per-project prompt color, put `export STARSHIP_DIR_BG="#5f5fd7"` and `export STARSHIP_CONFIG="$(~/code/jessitron/dotfiles/bin/starship-colors)"` in that project's `.be`. Note the override sticks to the shell after you leave the project. `--write-default` regenerates `starship.toml` instead.
- `claude-statusline` — Claude Code's footer (`statusLine` in settings.json). Reads the session JSON on stdin and prints powerline blocks matching the prompt: account │ model │ directory │ context used (just tokens, e.g. `86k`); the account block (orange "jessitronbee" for `.claude-work`, purple "jessitron yo" for `.claude-personal`, red + dir name if unrecognized) comes from `$CLAUDE_CONFIG_DIR`. The context block's color (not its text) goes green → orange at 50% → red at 80%. Not starship — Claude Code runs this itself. Its header has a one-liner to test it by hand. Each config dir (`~/.claude-work`, `~/.claude-personal`) has its own `settings.json`, and each needs the `statusLine` entry pointing here.
- `with-be <command>` — run a command with the environment from `.be` at the current repo's root; in a worktree, which has no `.be`, the main checkout's. For agents, whose shells don't load `.be` and may be forbidden to `source` it.
- `aws-transcribe.sh` — automate Amazon Transcribe for a video file (uploads to S3, kicks off the job, downloads the result).
- `fix-claude-plugin-paths` — works around a Claude Code bug where plugins installed under a non-default `$CLAUDE_CONFIG_DIR` get recorded with hardcoded `~/.claude/plugins/...` paths and silently never load. Rewrites the recorded paths. Header comment has the full story.
- `node-fallback/` — `node`/`npm`/`npx` wrappers that sit ahead of mise shims on PATH: use the repo's mise pin when it resolves, otherwise (and always inside Claude Code plugin hooks) fall back to Homebrew's node.
- `honeycomb-whoami.sh` — standalone copy of the `honeycomb-whoami` skill's script (identify a Honeycomb key's team/environment). The skill's copy in `llm/skills/` is slightly newer.

### `llm/` — Claude Code config

- `claude-work.CLAUDE.md`, `claude-personal.CLAUDE.md` — the global instructions for each Claude account, symlinked to `~/.claude-work/CLAUDE.md` and `~/.claude-personal/CLAUDE.md`. They're separate files on purpose: they've drifted apart (🐝 vs 🥕 prefix, different commit tags, etc.) and nobody has synced them yet. Edit either one through the symlink or here; it's the same file.
- `claude-personal.settings.json` — the personal account's Claude Code settings, symlinked to `~/.claude-personal/settings.json`. Model, statusline, local plugin marketplaces (`tronijess-skills`, `iterate-on-docs`), and a generic auto-mode `hard_deny`. This repo is public: keep project-specific auto-mode rules and environment notes in that project's `.claude/settings.local.json`, not here. The work account's `settings.json` is not tracked.
- `skills/` — personal Claude Code skills (`honeycomb-events-api`, `honeycomb-whoami`). Each one is symlinked individually into each account's `skills/` dir; the directory as a whole is not linked, because the account dirs also hold app-synced skills.
- `instructions-for-augment.txt` — equivalent rules for the Augment AI assistant.

### `windows/` — PowerShell setup

- `profile.ps1` — PowerShell profile. Aliases, a git-aware prompt, `Open-Dotfiles`, etc.
- `yo-jess.ps1` — Windows toast notifications via `System.Windows.Forms.NotifyIcon` (uses `cat-yo.ico`).
- `get.ps1`, `be.ps1`, `bash-equivalents.ps1` — PowerShell versions of the mac shell helpers.
- `fix-stderr.ps1`, `title.ps1`, `renumber-tapas-shots.ps1` — odds and ends.
- `cat-yo.ico` — notification icon.
- `vscode/` — VS Code config snippets for Windows.

### Other

- `Camtasia Studio 9 sv2.pref` — saved Camtasia preferences.
- `install.sh` — currently empty; setup is done by hand via the steps below.
- `.vscode/` — VS Code workspace settings for editing this repo.

## Mac setup

```
mkdir -p ~/code/jessitron
cd ~/code/jessitron
git clone https://github.com/jessitron/dotfiles

ln -s ~/code/jessitron/dotfiles/mac.zshrc ~/.zshrc
source one-time-git-setup.sh

ln -s ~/code/jessitron/dotfiles/bin ~/bin
ln -s ~/code/jessitron/dotfiles/bin/with-be ~/.local/bin/with-be

# per-account Claude config (never create ~/.claude; use CLAUDE_CONFIG_DIR)
ln -s ~/code/jessitron/dotfiles/llm/claude-work.CLAUDE.md ~/.claude-work/CLAUDE.md
ln -s ~/code/jessitron/dotfiles/llm/claude-personal.CLAUDE.md ~/.claude-personal/CLAUDE.md
ln -s ~/code/jessitron/dotfiles/llm/claude-personal.settings.json ~/.claude-personal/settings.json
for acct in work personal; do
  mkdir -p ~/.claude-$acct/skills
  for s in ~/code/jessitron/dotfiles/llm/skills/*/; do
    ln -s "${s%/}" ~/.claude-$acct/skills/
  done
done

# prompt: starship + a Nerd Font for its glyphs
brew install starship
brew install --cask font-jetbrains-mono-nerd-font
mkdir -p ~/.config
ln -s ~/code/jessitron/dotfiles/starship.toml ~/.config/starship.toml
ln -s ~/code/jessitron/dotfiles/bin/iterm-set-font ~/.local/bin/iterm-set-font
# then quit iTerm2 and, from Terminal.app:
iterm-set-font
# if glyphs are still boxes after reopening iTerm2, restart the Mac
```

Note: `brew install starship` autoremoved `ripgrep` as an "unneeded formula"
on one machine. Check `which rg` afterwards and `brew install ripgrep` if it
went missing.

## Linux / WSL setup

### Set up an ssh key for github

`ssh-keygen`

`cat ~/.ssh/id-rsa.pub`

now log in to GitHub->settings->SSH keys->paste the new one in

### get these dotfiles

in $HOME: `git clone git@github.com:jessitron/dotfiles`

### link in the profile

I think this is

`ln -s ~/dotfiles/windows-wsl-ubuntu.bashrc ~/.bash_profile`

### git

configure git

`source ~/dotfiles/one-time-git-setup.sh`
