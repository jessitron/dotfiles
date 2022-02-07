echo "Good morning!"
export EDITOR=vi

alias bp='code ~/dotfiles/aliases.sh'
alias reload='source ~/.bash_profile'

alias gs='git status'
alias gp='git push || echo "DAMMIT"'

alias c='git add . && git commit -m rebaseme' # useful when live coding
alias x='chmod u+x $(ls -tr | tail -1)'

# wanna save it somewhere
alias how-many-hours='git log --format="%cD" | cut -d : -f 1 | sort -u | wc -l'

function cod {
  if [[ $1 == "e." ]]
  then
     # I'm quite sure what I meant
     code .
  else
     echo "I'm guessing you meant 'code .'"
     code .
  fi
}

alias ghopen="git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//'"

function be {

  where=$1
  if [ -z "$where" ] ; then
  	echo "Usage: be <some-likely-directory>"
    return
  fi
  # overrides
  if [[ "$where" == "stdev" ]]
  then
    where=systemsthinking-dev.github.io
  fi
  if [[ "$where" == "catchupto" ]]
  then
    where=sixmilebridge
  fi

  # check every directory in my most favorite directory
  for dir in $(ls ~/code); do
  echo "Looking in code/$dir"
     if [[ -d "$HOME/code/$dir/$where" ]] ; then
      cd ~/code/$dir
      echo $dir/$where
      break
    fi
  done

  echo $where
  cd $where

  if [[ -e ".be" ]] ; then 
  	source .be
  fi
}

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
   if git clone git@github.com:$org/$repo
   then

    cd $repo

    if [[ -e "package.json" ]]
    then
        npm ci
    fi
   else
      echo "Clone didn't work"
   fi
}

# Can we not start in /mnt/c on WSL
if [[ $(pwd) == /mnt/c* ]]
then
  cd
fi
