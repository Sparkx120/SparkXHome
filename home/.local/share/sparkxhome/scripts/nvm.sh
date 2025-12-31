# Only load NVM if we need it
SPARKX_HOME_ALWAYS_ACTIVATE_NVM=${SPARKX_HOME_ALWAYS_ACTIVATE_NVM:-false}
nvm-activate() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}
if $SPARKX_HOME_ALWAYS_ACTIVATE_NVM; then
    nvm-activate
fi

