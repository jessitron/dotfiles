# dotfiles

gotta save them somewhere.

## What's in here

### Shell configs

- `mac.zshrc` — primary shell config on macOS. Path setup, aliases (`gs`, `ll`, `bp`, `reload`, `k`, `cod`, `awslogin`, `dockerlogin`), a custom prompt with git status, and functions: `gp` (git push with macOS alert on failure), `gc` (commit with `-n`), `get` (clone from GitHub into `~/code/<org>/<repo>` and set the right git email based on org), `be` (cd into a project by short name, looking through `~/.be_dirs` and `~/code/*`), `alert`, `title`, `honeycomb-whoami`, `aws-whoami`, plus a `claude` wrapper that runs Claude Code with OTel telemetry pointed at Honeycomb.
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
- `aws-transcribe.sh` — automate Amazon Transcribe for a video file (uploads to S3, kicks off the job, downloads the result).
- `claude-hook`, `claude-approval-hook`, `claude-notification-hook`, `send_otlp_log.sh` — symlinks into `../my-claude-hooks/`. These are the hook scripts referenced by `llm/claude-settings.json`. Clone [`jessitron/my-claude-hooks`](https://github.com/jessitron/my-claude-hooks) alongside this repo for them to resolve.

### `llm/` — Claude Code config

- `CLAUDE.md` — global instructions for Claude (linked into `~/.claude/CLAUDE.md`). Personality, working style, `RESPONSE_PREFIX` system, "end session" notes convention, commit style ("- claude" tag).
- `claude-settings.json` — global Claude Code settings (linked into `~/.claude/settings.json`). Sets the model, wires up hooks for every event (`PreToolUse`, `PostToolUse`, `Notification`, `SessionStart`, `SessionEnd`, `Stop`, etc.) to the scripts in `bin/`, enables the Honeycomb and gopls plugins, and disables some MCP servers. NOTE: those scripts in bin/ live in jessitron/my-claude-hooks
- `skills/` — personal Claude Code skills, symlinked into `~/.claude/skills/` so they're available in every project. Each skill is a directory with a `SKILL.md` describing when to invoke it. To wire it up:
  ```
  mkdir -p ~/.claude
  ln -s ~/code/jessitron/dotfiles/llm/skills ~/.claude/skills
  ```
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

get my-claude-hooks jessitron # some of the important files are here, why
ln -s ~/code/jessitron/dotfiles/bin ~/bin

mkdir ~/.claude (if it doesn't exist)
ln -s ~/code/jessitron/dotfiles/llm/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/code/jessitron/dotfiles/llm/claude-settings.json ~/.claude/settings.json
```

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
