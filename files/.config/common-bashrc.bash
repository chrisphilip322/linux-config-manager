alias ls="ls --color=auto"
alias x="xargs"

export PYTHONIOENCODING=UTF-8
export EDITOR=vim
export TERM=xterm-256color

export PATH=""
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/bin"
export PATH="$PATH:/usr/sbin"
export PATH="$PATH:/usr/bin"

if [ -f ~/.fzf.bash ]
then
    source ~/.fzf.bash
    export FZF_DEFAULT_COMMAND='ag --nocolor -g ""'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='
      --color fg:242,bg:236,hl:65,fg+:15,bg+:239,hl+:108
      --color info:108,prompt:109,spinner:108,pointer:168,marker:168
    '
else
    echo 'No fzf found, consider installing https://github.com/junegunn/fzf#installation'
fi

. $HOME/.bash-completion/git-completion.bash
. $HOME/.config/common-functions.bash
