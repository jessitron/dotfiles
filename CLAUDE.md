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
