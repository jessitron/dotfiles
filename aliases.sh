echo "Good morning!"

alias bp='code ~/dotfiles/aliases.sh'
alias reload='source ~/.bash_profile'

alias gs='git status'
alias gp='git push || echo "DAMMIT"'

alias c='git add . && git commit -m rebaseme'
alias x='chmod u+x $(ls -tr | tail -1)'

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

  # check every directory in my most favorite directory
  for dir in $(ls ~/code); do
     if [[ -d "$HOME/code/$dir/$where" ]] ; then
      cd ~/code/$dir
      echo $dir/$where
      break
    fi
  done

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
