# Notes for agents working in dotfiles

See README.md for what each file is.

## starship prompt

- Edit `starship.toml.tmpl`, never `starship.toml`. Then run
  `bin/starship-colors --write-default` to regenerate `starship.toml`, and
  commit both.
- Private-use Nerd Font / powerline glyphs (U+E000–U+F8FF, e.g. the arrow
  U+E0B0, branch U+E0A0, node U+E718) get silently dropped when text goes
  through a shell heredoc or a text-replacement tool. After any edit near
  them, check the bytes survived (`grep ... | xxd`). In comments, name the
  codepoint (`U+E0A0`) instead of pasting the glyph.
- Sanity check after a change: `starship prompt >/dev/null && echo ok`.

## claude-statusline (Claude Code footer)

- It is a plain script that Claude Code runs, not starship. Don't go looking
  in `starship.toml*` for the footer.
- There are Claude accounts with separate config dirs: `~/.claude-work`,
  `~/.claude-personal`, and `~/.claude-anonymous`. Each has its own `settings.json` (personal's is
  `llm/claude-personal.settings.json`; work's is untracked); a `statusLine`
  entry must be in each or that account gets no footer.
- The account block is chosen from `$CLAUDE_CONFIG_DIR`. A new account dir
  needs a new `case` branch in the script.

## Claude account config (llm/)

- A third config dir, `~/.claude-anonymous` (`CLAUDE_USE=other`), is
  deliberately bare: API-key auth, none of my config. Its only config is
  `llm/claude-anonymous.settings.json` (just the `statusLine`), which the
  `claude` wrapper symlinks in. Don't add CLAUDE.md, skills, or plugins.
- Never create `~/.claude`; it is a guard file. Everything is per-account
  (`~/.claude-work`, `~/.claude-personal`) via `$CLAUDE_CONFIG_DIR`.
- Tracked here, symlinked into the account dirs: both `CLAUDE.md`s, the
  personal `settings.json`, and each skill in `llm/skills/` individually.
  The `claude` wrapper links each skill on launch, so a new skill needs only
  its directory here. Don't symlink the whole `skills/` dir — the account
  dirs hold app-synced skills too.
- This repo is public. Project-specific auto-mode rules/environment notes go
  in that project's gitignored `.claude/settings.local.json`, not here.
