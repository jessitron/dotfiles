# dotfiles
gotta save them somewhere.

# Usual setup: linux

## Set up an ssh key for github

`ssh-keygen`

`cat ~/.ssh/id-rsa.pub`

now log in to GitHub->settings->SSH keys->paste the new one in

## get these dotfiles

in $HOME: `git clone git@github.com:jessitron/dotfiles` 

## link in the profile

I think this is 

`ln -s ~/dotfiles/windows-wsl-ubuntu.bashrc ~/.bash_profile`

## git

configure git

`source ~/dotfiles/one-time-git-setup.sh`
