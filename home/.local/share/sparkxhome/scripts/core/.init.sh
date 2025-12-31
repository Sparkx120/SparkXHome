##
# This file should only be sourced by .bashrc
##

# Load sparkx plugin scripts
for s in $SPARKX_SCRIPT_BASE/core/*; do
    if [[ -f $s ]] && [[ ".init.sh" != "$s" ]]; then
        source $s
    fi
done

# Load any plugins
for p in $SPARKX_SCRIPT_BASE/plugins/*; do
    if [[ -d $p ]]; then
        _SPARKX_PLUGIN_DIR=$p
        source $p/.init.sh
        unset _SPARKX_PLUGIN_DIR
    fi
done
