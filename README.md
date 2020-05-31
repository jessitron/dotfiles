# dotfiles
gotta save them somewhere.

# vscode

## administrator privileges required!1! !!!#!

cd ~/AppData/Roaming/Code/User
mv settings.json before-settings.json
mv keybindings.json before-keyboards.json
new-item -ItemType SymbolicLink -Target $HOME/dotfiles/windows/vscode/settings.json -Path settings.json
new-item -ItemType SymbolicLink -Target $HOME/dotfiles/windows/vscode/keybindings.json -Path keybindings.json