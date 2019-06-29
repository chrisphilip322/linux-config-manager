#!/bin/bash

echo 'source $HOME/.config/common-bashrc.bash' >> $HOME/.bashrc
echo 'source $HOME/.config/common-vimrc' >> $HOME/.vimrc
echo '[include]' >> $HOME/.gitconfig
echo '    path = ~/.config/common-gitconfig' >> $HOME/.gitconfig
