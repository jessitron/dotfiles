# dotfiles
gotta save them somewhere.

# Mac

```
mkdir -p ~/code/jessitron
cd ~/code/jessitron
git clone https://github.com/jessitron/dotfiles

ln -s ~/code/jessitron/dotfiles/mac.zshrc ~/.zshrc
source one-time-git-setup.sh

get my-claude-hooks jessitron # some of the important files are here, why
ln -s ~/code/jessitron/dotfiles/bin ~/bin

mkdir ~/.claude (if it doesn't exist)
ln -s ~/code/jessitron/dotfiles/llm/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/code/jessitron/dotfiles/llm/claude-settings.json ~/.claude/settings.json
```
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
