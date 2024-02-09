echo "Good morning!"

# f you mac
# alias git="/usr/local/bin/git"
alias k=kubectl
alias p="git push"

[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

[ -f $HOME/.bash_profile_secrets ] && . $HOME/.bash_profile_secrets

export PATH="$PATH:$HOME/bin:/usr/local/bin"
export PIP_REQUIRE_VIRTUALENV=true

# kubectl package manager
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

### Do this sometimes
alias dockerlogin='aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin 414852377253.dkr.ecr.$(aws configure get region).amazonaws.com'


# hound (Honeycomb)
eval "$(direnv hook bash)"
. $HOME/.asdf/asdf.sh

export GOPRIVATE=github.com/honeycomb.io
export PATH=$PATH:$GOPATH/bin

# Some of the code uses a lot of connections
ulimit -n 8192
## end hound

alias gh-whoami="$fetch_github_user && $fetch_github_scopes"

alias x='chmod u+x $(ls -tr | tail -1)'

alias ll='ls -la'
alias gs='git status'
alias bp='vi ~/.bash_profile'
alias reload='source ~/.bash_profile'

alias gtouch='git commit --allow-empty -m touch'

alias cod="code ."

alias grecent='git ll $(git for-each-ref --sort=-committerdate --count=3 --format="%(refname:short)" refs/remotes/origin)'
# this one doesn't work right :-( I want to see most recently updated branches
alias glr='git ll $(git for-each-ref --sort=-committerdate --count=3 --format="%(refname:short)" refs/heads/*)'

# reset to upstream
alias grh='git reset --hard $(git rev-parse --abbrev-ref --symbolic-full-name @{u})'
alias cm='git checkout master'

alias sign='git commit --allow-empty -m "sign"'

#I hate macs sometimes
alias pr="$HOME/bin/pr"

function timecurl() {
  url=$1
  time curl -s -o /dev/null -w @/Users/jessitron/.curl-format.txt  $url
}

# this is a great alias
function gitexclude() {
  pattern=$1

  echo $1 >> $(git config --get core.excludesfile)
}

function alert() {
	local message=$1
	local begin='tell application (path to frontmost application as text) to display dialog "'
    local quote="'"
    local rest='" buttons {"Ratfish"} with icon stop'
	local scriptie=$quote$begin$message$rest$quote
	echo $scriptie | xargs osascript -e
}

function gp() {
    repo=$(git remote get-url origin | sed 's/.*\///')

	if git push
	then
      echo "yay"
    else
    	alert "your push to $repo failed"
    fi
}

function gpf() {
	if git push -f
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

  #  if [[ -e "package.json" ]]
  #  then
  #  	  npm ci
  #  fi
   else
	echo "That didn't work"
   fi
}

function title {
    echo -ne "\033]0;"$*"\007"
}

function whereami {
  # current path relative to home directory
  python -c "import os.path; print os.path.relpath('$(pwd)', '$HOME')"
}

# change directories, plus title the window
function be {
  where=$1
  if [ -z "$where" ] ; then
  	echo "Usage: be <some-likely-directory>"
  	echo "This function will look for it in the parent directories listed in ~/.be_dirs"
    return
  fi
  # overrides
  if [ $where == "otel-demo" ] ; then
    where=opentelemetry-demo
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

# search and replace on many files
function sed_in_place {
  quote="'"
  expr=$1
  echo "Expression is: $quote $quote$expr -----"
  shift 1
  files=$*
  for file in $files
  do
    backup=$file.bak
    sed "$expr" $file > $file.bak
    if [ $? -eq 0 ]; then
      mv $file.bak $file
    else
      echo "didn't work on $file"
      break
    fi
  done
}

function ghopen() {
  path=$1
  line_number=$2
  BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
  REPO=$(git remote get-url origin | cut -d ':' -f 2)  # assuming git@github:

  if [ -n $line_number ] 
  then
    LINE="#L$line_number"  
  else
    LINE=""
  fi

  open "https://github.com/${REPO}/blob/$BRANCH/$path$LINE"

}

### Prompt
alias simpleprompt='export PS1="\[\e[33m\]\\$\[\e[m\] "'

function nonzero_return() {
  RETVAL=$?
  [ $RETVAL -ne 0 ] && echo "$RETVAL"
}

# get current branch in git repo
function parse_git_branch() {
  BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
  if [ ! "${BRANCH}" == "" ]
  then
    STAT=`parse_git_dirty`
    echo "[${BRANCH}${STAT}]"
  else
    echo ""
  fi
}

# get current status of git repo
function parse_git_dirty {
  status=`git status 2>&1 | tee`
  dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
  untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
  ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
  newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
  renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
  deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
  bits=''
  if [ "${renamed}" == "0" ]; then
    bits=">${bits}"
  fi
  if [ "${ahead}" == "0" ]; then
    bits="*${bits}"
  fi
  if [ "${newfile}" == "0" ]; then
    bits="+${bits}"
  fi
  if [ "${untracked}" == "0" ]; then
    bits="?${bits}"
  fi
  if [ "${deleted}" == "0" ]; then
    bits="x${bits}"
  fi
  if [ "${dirty}" == "0" ]; then
    bits="!${bits}"
  fi
  if [ ! "${bits}" == "" ]; then
    echo " ${bits}"
  else
    echo ""
  fi
}

function foreach() {
	local do="$@"

	for dir in $(ls)
	do
		cd $dir
		$do
		cd -
	done

}

export PS1="\`parse_git_branch\` \W \[\e[31m\]\`nonzero_return\`\[\e[m\]\[\e[33m\]\\$\[\e[m\] "

### thanks ezprompt.net
### end prompt

# personal
# satellite-of-love
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# demos
alias c='git commit -am "commit it all right now" && git push'

function one_time_config() {
	# mostly this is a place to record stuff

	# I have people mapped to short names
	git config --global mailmap.file ~/.mailmap
	# to look nice in this format
	git config --global pretty.favorite "format:%C(yellow)%h %C(green)%aN%C(auto)%d %s %C(red)%N"
}

function latest() {
	npm view $1 --json | jq '."dist-tags".latest'
}
# honeycomb 
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# me
function wtf() {
  printf "####\n What cluster am I in?\n####\n"
  kubectl config get-contexts
  printf "##\nWho does k8s think I am? "
  kubectl whoami
  printf '####\nWho does AWS think I am?\n###\n'
  aws sts get-caller-identity
}
