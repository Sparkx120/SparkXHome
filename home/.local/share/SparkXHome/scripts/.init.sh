##
# This file should only be sourced by .bashrc
##

# Load sparkx plugin scripts
for s in $SPARKX_HOME_SCRIPTS/*; do
    if [[ -f $s ]] && [[ ".init.sh" != "$s" ]]; then
        source $s
    fi
done

# Load any plugins
for p in $SPARKX_HOME_PLUGINS/*; do
    if [[ -d $p ]]; then
        _SPARKX_PLUGIN_DIR=$p
        source $p/.init.sh
        unset _SPARKX_PLUGIN_DIR
    fi
done
