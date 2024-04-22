
git config --global alias.ll 'log --oneline --graph'
git config --global alias.ff 'merge --ff-only'
git config --global alias.fix 'commit --amend --no-edit'
git config --global alias.home 'rev-parse --show-toplevel'
git config --global alias.note 'commit --allow-empty -m'
git config --global alias.jsdiff 'diff -w -- . ":(exclude)**/package-lock.json"'

git config --global user.name "Jessica Kerr"
git config --global user.email "jessitron@gmail.com"

git config --global core.excludesFile $(pwd)/gitexcludes
