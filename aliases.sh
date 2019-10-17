
alias bp='code ~/dotfiles/aliases.sh'
alias reload='source ~/.bash_profile'

alias gs='git status'
alias gp='git push || echo "DAMMIT"'

alias c='git add . && git commit -m rebaseme'


alias asln='atomist start --local --no-compile'
alias aalr='atomist analyze local repositories --localDirectory=$(pwd)'

export ATOMIST_PROJECTS=$HOME/code