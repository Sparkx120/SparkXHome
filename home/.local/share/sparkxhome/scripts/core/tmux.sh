sparkx-tmux-new-session() {
    # Start a new tmux session with motd
    tmux new-session $XDG_DATA_HOME/sparkxhome/motd.sh $@
}

sparkx-tmux-reattach() {
    # Reattach to an existing tmux session if one exists
    if [[ -z $TMUX ]]; then
        local SESSIONS=`tmux list-session 2> /dev/null | grep -v "attached" | wc -l` 
        if [[ "$SESSIONS" == "1" ]]; then
            # If there is only one session attach to it
            echo "Reattching to single tmux session"
            tmux attach
            exit
        fi
        # If there are many detached sessions we need to the user to determine which one they want to attach
        if ((SESSIONS > 1)); then
            echo "There are multiple detached tmux sessions going to bash only"
            tmux list-sessions
        fi
    fi
}

_sparkx-tmux-always-init() {
    if [[ -z $TMUX ]]; then
        # Run TMUX on terminal startup
        echo "starting tmux manager"
        if [[ -z `tmux list-sessions | grep -v "attached"` ]]; then
            # Start a new session if there are no detached sessions
            sparkx-tmus-new-session
            exit
        else
            sparkx-tmux-reattach
        fi
    fi
}

if $SPARKX_HOME_TMUX_INIT_ALWAYS; then
    _sparkx-tmux-always-init
elif $SPARKX_HOME_TMUX_REATTACH_ONLY; then
    sparkx-tmux-reattach
fi
