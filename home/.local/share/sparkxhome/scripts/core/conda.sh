# Conda activation functions
SPARKX_HOME_DEFAULT_CONDA_ENV=${SPARKX_HOME_DEFAULT_CONDA_ENV:-base}
SPARKX_HOME_ALWAYS_ACTIVATE_CONDA=${SPARKX_HOME_ALWAYS_ACTIVATE_CONDA:-false}
SPARKX_HOME_CONDA_DIR=${SPARKX_HOME_CONDA_DIR:-$HOME/miniconda3}
function conda-activate() {
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$("$SPARKX_HOME_CONDA_DIR/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "$SPARKX_HOME_CONDA_DIR/etc/profile.d/conda.sh" ]; then
            . "$SPARKX_HOME_CONDA_DIR/etc/profile.d/conda.sh"
        else
            export PATH="$SPARKX_HOME_CONDA_DIR/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<

    conda config --set changeps1 False
    conda activate $1
}
if $SPARKX_HOME_ALWAYS_ACTIVATE_CONDA; then
  conda-activate $SPARKX_HOME_DEFAULT_CONDA_ENV
fi

export VIRTUAL_ENV_DISABLE_PROMPT=1
