# Various Vim aliases and functions

alias vimwiki='vim -c VimwikiIndex'
alias vimdiary='vim -c VimwikiDiaryIndex'

vimtree() {
    if [[ -n $TMUX ]]; then
        local project_name=`basename $PWD`
        local window_name="vim-$project_name"
        tmux renamew $window_name
        tmux splitw -l 10
        tmux select-pane -U
    fi
    vim -c 'NERDTree'
}
