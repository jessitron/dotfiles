# we are here
echo "Good morning."

# essentials
alias gs='git status'
alias ll='ls -a'
alias bp='vi ~/.zshrc'
alias reload='source ~/.zshrc'

## prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' formats '%b%c%u '
zstyle ':vcs_info:git:*' stagedstr ' 🌞'
zstyle ':vcs_info:git:*' unstagedstr ' ⏿'
setopt PROMPT_SUBST
PROMPT='%F{#10aa20}%*%f %? %F{#EEEEE1}%1~%f %F{#FF2020}%f${vcs_info_msg_0_}$ '

#  history
export HISTFILE=~/.zsh_history
export SAVEHIST=1000


