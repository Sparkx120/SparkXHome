# ~/.bashrc: executed by bash(1) for non-login shells.

# Used to tell other scripts that this is a live shell
export SPARKX_HOME_RUNTIME=shell

# Setup XDG Base Directory Paths
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

# Setup SparkX Script Paths
export SPARKX_SCRIPT_BASE=$XDG_DATA_HOME/sparkxhome/scripts

# Load SparkX Conf if it exists
mkdir -p $XDG_CONFIG_HOME/sparkxhome
if [ -f ~/.sparkxconf ]; then # Deprecated (migrate)
    mv ~/.sparkxconf ~/.sparkx.conf
elif [ -f ~/.sparkx.conf ]; then
    mv ~/.sparkx.conf $XDG_CONFIG_HOME/sparkxhome/config
fi
if [ -f $XDG_CONFIG_HOME/sparkxhome/config ]; then
    source $XDG_CONFIG_HOME/sparkxhome/config
fi

# Setup PATH
# export PATH=~/miniconda3/bin:$PATH
export PATH=~/.local/bin:$PATH
export PATH=~/.cargo/bin:$PATH

# Export Global Shell Variables
#export DISPLAY=localhost:0.0
#export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}'):0.0
export EDITOR=`which vim`
export GIT_EDITOR=$EDITOR
export VISUAL=$EDITOR
export BROWSER=firefox
export GPG_TTY=$(tty)

source $SPARKX_SCRIPT_BASE/core/.init.sh

# Local PS1
GIT_STATUS="\$(if git status > /dev/null 2>&1; then echo \"\342\224\200[\[\[\033[0;33m\]\$(git branch --show-current) \$(git rev-parse --short HEAD)\$(git diff --shortstat | awk '{print \" \" \$1 \"f\" \$4 \"i\" \$6 \"d\"}')\[\033[0;37m\]]\"; fi)"
CONDA_STATUS="\$([[ \"\$CONDA_DEFAULT_ENV\" != \"\" ]] && echo \"\342\224\200[\[\033[0;33m\]\$CONDA_DEFAULT_ENV\[\033[0;37m\]]\")"
VENV_STATUS="\$([[ \"\$VIRTUAL_ENV\" != \"\" ]] && echo \"\342\224\200[\[\033[0;33m\]\$(basename \$VIRTUAL_ENV)\[\033[0;37m\]]\")"

PS1="\n\[\033[0;37m\]\342\224\214\342\224\200\$([[ \$? != 0 ]] && echo \"[\[\033[0;31m\]\342\234\227\[\033[0;37m\]]\342\224\200\")[$(if [[ ${EUID} == 0 ]]; then echo '\[\033[0;31m\]\h'; else echo '\[\033[1;33m\]\u\[\033[0;37m\]@\[\033[1;31m\]\h'; fi)\[\033[0;37m\]]\342\224\200[\[\033[1;32m\]\$( pwd )\[\033[0;37m\]]$CONDA_STATUS$VENV_STATUS$GIT_STATUS\n\[\033[0;37m\]\342\224\224\342\224\200\[\033[0m\] "
