# / we are here ... what happened to this line
echo "Good morning."

# path
PATH="/usr/local/bin:$HOME/.local/bin:/Users/jessitron/.cargo/bin:/opt/homebrew/bin/:$PATH"

# essentials
alias gs='git status'
alias ll='ls -la'
alias bp='vi ~/.zshrc; reload'
alias reload='source ~/.zshrc'
alias k=kubectl
alias x='chmod +x *(om[1])' # this is interesting here

# not essential
alias init-seamap='claude plugin install seamapping@tronijess-skills --scope project'

## prompt
if [[ "$ITERM_PROFILE" == "graceful.dev" ]]; then
  echo "Grow your programming practice"
  PROMPT='$ '
else
  # starship prompt (https://starship.rs). Config: ~/.config/starship.toml
  eval "$(starship init zsh)"

  # -- previous hand-rolled prompt, kept for easy revert: comment out the
  # -- starship eval above and uncomment this block to go back.
  # autoload -Uz vcs_info
  # precmd() { vcs_info }
  # zstyle ':vcs_info:git:*' check-for-changes true
  # zstyle ':vcs_info:git:*' formats '%b%c%u '
  # zstyle ':vcs_info:git:*' stagedstr ' 🌞'
  # zstyle ':vcs_info:git:*' unstagedstr ' ⏿'
  # setopt PROMPT_SUBST
  # PROMPT='%F{#10aa20}%*%f %? %F{#EEEEE1}%1~%f %F{#FF2020}%f${vcs_info_msg_0_}$ '
fi
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

# # Honeycomb
# eval "$(direnv hook zsh)"
# # initialise completions with ZSH's compinit
# autoload -Uz compinit && compinit

### Honeycomb AWS, SA access
export AWS_PROFILE=sandbox
export AWS_REGION=us-east-1
alias awslogin="aws sso login --sso-session sso-default"
# SA sandbox, I think:
# alias ecrlogin="aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin 465062709130.dkr.ecr.$AWS_REGION.amazonaws.com"

# Jessitron sandbox:
alias dockerlogin='aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin 414852377253.dkr.ecr.$(aws configure get region).amazonaws.com'


# rust
# b

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
    git commit -n -m "🙂 $message"
}


# clone a repo
function get() {
   repo=$1
   org=$2 
   # if $1 is a github URL, set repo and org accordingly
   if [[ "$repo" == https://github.com/* ]]
   then
     org=$(echo $repo | sed 's#https://github.com/\([^/]*\)/\(.*\)#\1#')
     repo=$(echo $repo | sed 's#https://github.com/\([^/]*\)/\(.*\)#\2#')
     if [[ $repo == *.git ]]
     then
       repo=$(echo $repo | sed 's/\.git$//')
     fi
     echo $repo $org
   fi
   if [ -z "$org" ] # org not specified
   then
   	 org=$(pwd | sed 's#.*/##') # org is the current directory
   else
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
  original_where=$1
  if [[ -z "$where" ]] ; then
  	echo "Usage: be <some-likely-directory>"
  	echo "This function will look for it in the parent directories listed in ~/.be_dirs"
    return
  fi
  # overrides
  if [[ $where == "." ]]; then
     where=$(pwd)
  elif [[ $where == "episodes" ]]; then
    where="/Users/jessitron/Library/CloudStorage/ZohoWorkDriveTrueSync-ShipRiseLLC/Episodes"
  elif [[ $where == "battleships" ]] ; then
    where="$HOME/code/battleships-hq"
  elif [[ $where == "explore" ]] ; then
    where=exploreddd.github.com
  elif [[ $where == "zoho" ]] ; then 
    where="/Users/jessitron/Library/CloudStorage/ZohoWorkDriveTrueSync-ShipRiseLLC/"
  elif [[ $where == "ms-demo" ]] ; then
    where=microservices-demo
  elif [[ $where == "mtg" ]] ; then
    where=mtg-deck-shuffler
  elif [[ $where == "life" ]] ; then
  elif [[ $where == "mtg-colors" ]] ; then
    where=mtg-sparrow
  elif [[ $where == "life" ]] ; then
    where=basic-text-organization-work
  elif [[ $where == "otel-demo" ]] ; then
    where=opentelemetry-demo
  elif [[ $where == "tronijess" ]] ; then
    where=tronijess-skills
    echo "I think you mean, $where"
  elif [[ $where == "cyndibot" ]] ; then
    where=cynditaylor-com-bot
    echo "I think you mean, $where"
  elif [[ $where == "oday" ]] ; then
    where=meminator-workshop
    echo "I think you mean, $where"
  elif [[ $where == "oquiz" ]] ; then
    where=observaquiz
    echo "I think you mean, $where"
  elif [[ $where == "devrel-demo" ]] ; then
    where=devrel-opentelemetry-demo
    echo "I think you mean, $where"
  elif [[ $where == "claude-log" || $where == "convo-story" ]] ; then
    where=conversation-explorer
    echo "I think you mean, $where"
  elif [[ $where == "seamap" || $where == "tracking-skills" ]] ; then
    where=tronijess-skills
    echo "I think you mean, $where"
  fi

  # check my favorite directories
  for dir in $(cat ~/.be_dirs); do
    if [ -d "$HOME/$dir/$where" ] ; then
      cd $HOME/$dir
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
  title $original_where

  if [[ -e ".be" ]] ; then 
  	source .be
  fi
}

function 😱() {
  echo "Yeah, I feel that way too."
}


export CLAUDE_CODE_OUTPUT_HONEYCOMB_API_KEY=hcaik_01k1y42mbg8qs650rajqsqybp53w4sxhjdsz84bb3esh92et7nz4c2x60b
claude() {
    if [[ -z "$CLAUDE_CONFIG_DIR" ]]; then
       if [[ "$CLAUDE_USE" =~ "work" ]]; then
          export CLAUDE_CONFIG_DIR="$HOME/.claude-work"
       elif [[ "$CLAUDE_USE" =~ "personal" ]]; then
          export CLAUDE_CONFIG_DIR="$HOME/.claude-personal"
       elif [[ "$CLAUDE_USE" =~ "other" ]]; then
          export CLAUDE_CONFIG_DIR="$HOME/.claude-anonymous"
       else
           local answer
           read -r "answer?Is this personal, work, or other (API key, none of my config)? [w/p/o, anything else cancels] "
           case "$answer" in
             w|work)     export CLAUDE_USE=work
                         export CLAUDE_CONFIG_DIR="$HOME/.claude-work" ;;
             p|personal) export CLAUDE_USE=personal
                         export CLAUDE_CONFIG_DIR="$HOME/.claude-personal" ;;
             o|other)    export CLAUDE_USE=other
                         export CLAUDE_CONFIG_DIR="$HOME/.claude-anonymous" ;;
             *) return ;;
           esac
           # remember it for next time, in this directory's .be (sourced by `be`)
           echo "export CLAUDE_USE=$CLAUDE_USE" >> .be
           echo "Appended CLAUDE_USE=$CLAUDE_USE to $(pwd)/.be"
       fi
    fi
    if [[ "$CLAUDE_CONFIG_DIR" =~ ".claude-work" ]]; then
       echo " ------------------ Claude for WORK -----------------------"
    elif [[ "$CLAUDE_CONFIG_DIR" =~ ".claude-anonymous" ]]; then
       # not logged in: auth comes from ANTHROPIC_API_KEY, usually in the repo's .be
       if [[ -z "$ANTHROPIC_API_KEY" ]]; then
          echo "CLAUDE_USE=other needs ANTHROPIC_API_KEY; put it in this repo's .be" >&2
          return 1
       fi
       mkdir -p "$CLAUDE_CONFIG_DIR"
       echo " ------------------ Claude for OTHER (API key, no config) ------------------"
    else
       echo " ----------------------- Claude for PERSONAL -----------------------"
    fi
    echo "Running claude with telemetry sent to the local claude code collector"
    # the parentheses start a subshell, so that I'm not changing env vars in the current shell
    (source ~/code/jessitron/claude-collector/claude-env.sh && declare -p CLAUDE_CONFIG_DIR  && command claude --enable-auto-mode "$@")
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

aws-whoami() {
    local identity=$(aws sts get-caller-identity --output json 2>&1)
    
    if [ $? -ne 0 ]; then
        echo "Error calling AWS STS:"
        echo "$identity"
        return 1
    fi
    
    local account=$(echo "$identity" | jq -r '.Account')
    local arn=$(echo "$identity" | jq -r '.Arn')
    local user_id=$(echo "$identity" | jq -r '.UserId')
    
    # Map account numbers to friendly names
    local account_name
    case "$account" in
        465062709130)
            account_name="SalesEngineerAccess"
            ;;
        414852377253)
            account_name="jessitron-sandbox (EKS cluster) [profile: sandbox]"
            ;;
        657166037864)
            account_name="devrel-sandbox"
            ;;
        *)
            account_name="Unknown"
            ;;
    esac
    
    echo "Account: $account ($account_name)"
    echo "ARN: $arn"
    echo "UserId: $user_id"
}

alias claude-mcp="claude mcp add honeycomb --transport http https://mcp.honeycomb.io/mcp"

eval "$(mise activate zsh)"

# bun completions
[ -s "/Users/jessitron/.bun/_bun" ] && source "/Users/jessitron/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# yx completion
source /Users/jessitron/.zsh/completions/yx

# herdr: a new pane opens in its workspace's directory, so load that repo's .be.
# Like with-be, a worktree (no .be of its own) falls back to the main checkout's.
function load_be() {
  local root be
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
  be="$root/.be"
  if [[ ! -f $be ]] && git rev-parse --git-dir >/dev/null 2>&1; then
    be="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")/.be"
  fi
  [[ -f $be ]] || return 0
  set -a; source "$be"; set +a
  echo "loaded $be"
}
[[ -n "$HERDR_ENV" ]] && load_be
