# we are here
echo "Good morning."

# path
PATH="/usr/local/bin:/opt/homebrew/bin/:$PATH"

# essentials
alias gs='git status'
alias ll='ls -la'
alias bp='vi ~/.zshrc'
alias reload='source ~/.zshrc'
alias k=kubectl
alias x='chmod +x *(om[1])' # this is interesting here

## prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' formats '%b%c%u '
zstyle ':vcs_info:git:*' stagedstr ' 🌞'
zstyle ':vcs_info:git:*' unstagedstr ' ⏿'
setopt PROMPT_SUBST
PROMPT='%F{#10aa20}%*%f %? %F{#EEEEE1}%1~%f %F{#FF2020}%f${vcs_info_msg_0_}$ '
# PROMPT='> '

#  history ... does this work?
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt appendhistory

# because
alias cod='code .'

# fucking work
export GPG_TTY=$(tty)

# Honeycomb
eval "$(direnv hook zsh)"
. "$HOME/.asdf/asdf.sh"
# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

function alert() {
	local message=$1
	local begin='tell application (path to frontmost application as text) to display dialog "'
    local quote="'"
    local rest='" buttons {"Ratfish"} with icon stop'
	local scriptie=$quote$begin$message$rest$quote
	echo $scriptie | xargs osascript -e
}

function title {
    echo -ne "\e]1;$*\a"
}

function gp() {
    if git push
	then
      echo "yay"
    else
        repo=$(git remote get-url origin | sed 's/.*\///')
    	alert "your push to $repo failed"
    fi
}

# clone a repo
function get() {
   repo=$1
   if [ -z "$2" ] # org not specified
   then
   	 org=$(pwd | sed 's#.*/##') # org is the current directory
   else
   	 org=$2
   	 if [[ "$org" == "sol" ]]
   	 then
   	    org="satellite-of-love"
   	 fi
     cd ~/code # here is my place where I clone things
     if [[ ! -d $org ]]
     then
       echo "Creating ~/code/$org"
       mkdir $org
     fi
     cd $org 
   fi
   echo "cloning $org/$repo"
   if git clone https://github.com/$org/$repo
   then

        cd $repo
        title $repo

        if [[ "$org" == "honeycombio" ]]
        then
            git config --local user.email "jessitron@honeycomb.io"
        else
            git config --local user.email "jessitron@gmail.com"
        fi
    else
	    echo "That didn't work"
    fi
}


# change directories, plus title the window
function be() {
  where=$1
  if [[ -z "$where" ]] ; then
  	echo "Usage: be <some-likely-directory>"
  	echo "This function will look for it in the parent directories listed in ~/.be_dirs"
    return
  fi
  # overrides
  if [[ $where == "otel-demo" ]] ; then
    where=opentelemetry-demo
  elif [[ $where == "oquiz" ]] ; then
    echo "I think you mean, observaquiz-ui"
    where=observaquiz-ui
  elif [[ $where == "oday" ]] ; then
    echo "I think you mean, observability-day"
    where=observability-day-workshop
  fi

  # check my favorite directories
  for dir in $(cat ~/.be_dirs); do
    if [ -d "$dir/$where" ] ; then
      cd $dir
      echo $dir/$where
      break
    fi
  done

  # check every directory in my most favorite directory
  for dir in $(ls ~/code); do
     if [[ -d "$HOME/code/$dir/$where" ]] ; then
      cd ~/code/$dir
      echo $dir/$where
      break
    fi
  done

  cd $where
  title $where

  if [[ -e ".be" ]] ; then 
  	source .be
  fi
}
