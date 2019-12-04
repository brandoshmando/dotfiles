#### Tracking Instructions

*Create alias for bare repo:*

`alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'`

*Clone bare repo:*

`git clone --bare git@github.com:brandoshmando/dotfiles.git $HOME/.cfg`

*Hide untracked files:*

`config config --local status.showUntrackedFiles no`

*Checkout files to $HOME dir:*

`config checkout`
