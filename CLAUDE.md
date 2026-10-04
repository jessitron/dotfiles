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
- There are two Claude accounts with separate config dirs: `~/.claude-work`
  and `~/.claude-personal`. Each has its own `settings.json`, outside this
  repo; a `statusLine` entry must be in *both* or that account gets no footer.
- The account block is chosen from `$CLAUDE_CONFIG_DIR`. A new account dir
  needs a new `case` branch in the script.
