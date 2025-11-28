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

### Honeycomb AWS, SA access
export AWS_PROFILE=sandbox
export AWS_REGION=us-east-1
alias awslogin="aws sso login --sso-session sso-default"
# SA sandbox, I think:
# alias ecrlogin="aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin 465062709130.dkr.ecr.$AWS_REGION.amazonaws.com"

# Jessitron sandbox:
alias dockerlogin='aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin 414852377253.dkr.ecr.$(aws configure get region).amazonaws.com'


# rust
. "$HOME/.cargo/env"

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

# git push, except raise an error if it does not work
function gp() {
    if git push
	then
      echo "yay"
    else
        repo=$(git remote get-url origin | sed 's/.*\///')
    	alert "your push to $repo failed"
    fi
}

function gc() {
    message=${1:-"commit dangit"}
    git commit -n -m "$message"
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
  if [[ $where == "explore" ]] ; then
    where=exploreddd.github.com
  elif [[ $where == "otel-demo" ]] ; then
    where=opentelemetry-demo
  elif [[ $where == "oday" ]] ; then
    where=meminator-workshop
    echo "I think you mean, $where"
  elif [[ $where == "oquiz" ]] ; then
    where=observaquiz
    echo "I think you mean, $where"
  elif [[ $where == "devrel-demo" ]] ; then
    where=devrel-opentelemetry-demo
    echo "I think you mean, $where"
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

function 😱() {
  echo "Yeah, I feel that way too."
}


export CLAUDE_CODE_OUTPUT_HONEYCOMB_API_KEY=hcaik_01k1y42mbg8qs650rajqsqybp53w4sxhjdsz84bb3esh92et7nz4c2x60b
claude() {
    echo "Running claude with stats sent to modernity/claude-code $CLAUDE_CODE_OUTPUT_HONEYCOMB_API_KEY"
    OTEL_SERVICE_NAME="claude-code" \
    OTEL_EXPORTER_OTLP_HEADERS="x-honeycomb-team=$CLAUDE_CODE_OUTPUT_HONEYCOMB_API_KEY,x-honeycomb-dataset=claude_code_metrics" \
 CLAUDE_CODE_ENABLE_TELEMETRY=1 \
OTEL_METRICS_EXPORTER="otlp" \
OTEL_LOGS_EXPORTER="otlp" \
OTEL_EXPORTER_OTLP_PROTOCOL=grpc \
OTEL_EXPORTER_OTLP_ENDPOINT="api.honeycomb.io:443" \
OTEL_LOG_USER_PROMPTS=1 \
    command claude "$@"
}

honeycomb-whoami() {
  if [ -z "$HONEYCOMB_API_KEY" ]; then
    echo "no HONEYCOMB_API_KEY environment variable"
    return 0
  fi
  
  response=$(curl -s -H "X-Honeycomb-Team: $HONEYCOMB_API_KEY" \
                   "https://api.honeycomb.io/1/auth")
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch data from Honeycomb API."
    return 1
  fi
  
  team_slug=$(echo "$response" | jq -r '.team.slug')
  env_slug=$(echo "$response" | jq -r '.environment.slug')
  
  env_url="https://ui.honeycomb.io/${team_slug}/environments/${env_slug}/"
  echo "Look for traces in: $env_url"
}

alias aws-whoami="aws sts get-caller-identity"

alias claude-mcp="claude mcp add honeycomb --transport http https://mcp.honeycomb.io/mcp"

