#!/bin/bash

##
# SparkXHome Message of the Day Art Generator
# TODO Massive Cleanup and Refactoring and Modernizing
##

_trim_special() {
    sed "s,[\x01-\x1F\x7F]\[[0-9;]*[a-zA-Z],,g"
}

_trim_length() {
    awk '{ if (length($0) > max) {max = length($0); maxline = $0} } END { print length(maxline) }'
}

_max_length() {
    $@ | _trim_special | _trim_length
}

draw_ascii_art() {
    local MOTD_ART=${SPARKX_HOME_MOTD_ART:-$XDG_DATA_HOME/sparkxhome/hostart.txt}
    local MOTD_USE_HOST_ART=${SPARKX_HOME_MOTD_USE_HOST_ART:-false}
    local MOTD_NAME=${SPARKX_HOME_MOTD_NAME:-`whoami`}
    local MOTD_HOST_FONT=${SPARKX_HOME_MOTD_HOST_FONT:-roman}
    local MOTD_WELCOME_FONT=${SPARKX_HOME_MOTD_WELCOME_FONT:-binary}
    local MOTD_USERNAME_FONT=${SPARKX_HOME_MOTD_USERNAME_FONT:-mini}
    local MOTD_WIDTH=$1
    # Draw the ascii art
    figlet -f $SPARKX_HOME_CLONE_DIR/fonts/figlet/$MOTD_HOST_FONT.flf -w $MOTD_WIDTH -c "$HOSTNAME"
    figlet -f $SPARKX_HOME_CLONE_DIR/fonts/figlet/$MOTD_WELCOME_FONT.flf -w $MOTD_WIDTH -c "welcome"
    figlet -f $SPARKX_HOME_CLONE_DIR/fonts/figlet/$MOTD_USERNAME_FONT.flf -w $MOTD_WIDTH -c `echo $MOTD_NAME | sed -e 's/\(.\)/\1 /g'`
}

draw_original_art() {
    local TERM_WIDTH=$1
    local MOTD_WIDTH=$2
    local MOTD_ART=${SPARKX_HOME_MOTD_ART:-$XDG_DATA_HOME/sparkxhome/hostart.txt}
    local MOTD_USE_HOST_ART=${SPARKX_HOME_MOTD_USE_HOST_ART:-false}
    local MOTD_INDENT=`expr $TERM_WIDTH - $MOTD_WIDTH`
    local MOTD_INDENT=`expr $MOTD_INDENT / 2`
    local MOTD_SPACES=`head -c $MOTD_INDENT < /dev/zero | tr '\0' ' '`

    clear
    cat $MOTD_ART | sed "s/^/$MOTD_SPACES/"
    echo ""
    draw_ascii_art $TERM_WIDTH
}

draw_os_art() {
    local TERM_WIDTH=$1
    local MOTD_WIDTH=$2
    local ART_LENGTH=`neofetch -L | tail -n +2 | head -n -1 | _trim_special | _trim_length`
    local ART_INDENT=`expr $TERM_WIDTH - $ART_LENGTH`
    local ART_INDENT=`expr $ART_INDENT / 2`
    local ART_INDENT=`expr $ART_INDENT - 1`
    if (( $ART_INDENT > 0 )); then
        local ART_SPACES=`head -c $ART_INDENT < /dev/zero | tr '\0' ' '`
    else
        local ART_SPACES=0
    fi
    clear
    neofetch -L | sed "s/^/$ART_SPACES/"
    echo ""
    draw_ascii_art $TERM_WIDTH
}

draw_custom_art() {
    local TERM_WIDTH=$1
    local MOTD_WIDTH=$2
    local ART_FILE=$3
    local MOTD_ART=${SPARKX_HOME_MOTD_ART:-$XDG_DATA_HOME/sparkxhome/hostart.txt}
    local MOTD_USE_HOST_ART=${SPARKX_HOME_MOTD_USE_HOST_ART:-false}
    local IMG_WIDTH=`expr $TERM_WIDTH \* 3 / 4 `
    local ART="$SPARKX_HOME_CLONE_DIR/$ART_FILE"

    if [[ "$ART" == *.gif ]]; then
        convert "$ART[0]" /tmp/art.png
        local ART_LENGTH=`_max_length catimg /tmp/art.png -w $IMG_WIDTH`
        local ART_HEIGHT=`catimg /tmp/art.png -w $IMG_WIDTH | _trim_special | wc -l`
        rm /tmp/art.png
    else
        local ART_LENGTH=`_max_length catimg $ART -w $IMG_WIDTH`
        local ART_HEIGHT=`catimg $ART -w $IMG_WIDTH | _trim_special | wc -l`
    fi
    local MAX_WIDTH=`expr $TERM_WIDTH - $ART_LENGTH`
    if $MOTD_USE_HOST_ART; then
        local MOTD_INDENT=`expr $MAX_WIDTH - $MOTD_WIDTH`
        local MOTD_INDENT=`expr $MOTD_INDENT / 2`
        if (( $MOTD_INDENT > 0 )); then
            local MOTD_SPACES=`head -c $MOTD_INDENT < /dev/zero | tr '\0' ' '`
        else
            local MOTD_SPACES=" "
        fi
        cat $MOTD_ART | sed "s/^/$MOTD_SPACES/" >> /tmp/temp_motd_msg
        echo "" >> /tmp/temp_motd_msg
    fi
    draw_ascii_art $MAX_WIDTH >> /tmp/temp_motd_msg
    local MOTD_HEIGHT=`wc -l /tmp/temp_motd_msg | awk '{print $1}'`
    local DELTA=`expr $ART_HEIGHT - $MOTD_HEIGHT`
    local DELTA=`expr $DELTA / 2`
    
    if (( $DELTA > 0 )); then
        for i in `seq 1 $DELTA`; do
            echo "" >> /tmp/temp_motd_pad
        done
        cat /tmp/temp_motd_pad /tmp/temp_motd_msg > /tmp/temp_motd
        rm /tmp/temp_motd_pad
        rm /tmp/temp_motd_msg
    elif (( $DELTA < 0)); then
        local DELTA=`expr 0 - $DELTA`
        for i in `seq 1 $DELTA`; do
            echo "" >> /tmp/temp_img_pad
        done
        local IMG_PAD=`cat /tmp/temp_img_pad`
        cat /tmp/temp_motd_msg > /tmp/temp_motd
        rm /tmp/temp_motd_msg
        # rm /tmp/temp_img_pad
    else
        cat /tmp/temp_motd_msg > /tmp/temp_motd
        rm /tmp/temp_motd_msg
    fi

    tput clear
    if $ANIMATED; then
        catimg $ART -w $IMG_WIDTH -l 0 | sed '1 i\n\n' | paste - /tmp/temp_motd | sed "s/^/$ART_SPACES/"
    else
        catimg $ART -w $IMG_WIDTH | sed '1 i\\n\n' | paste - /tmp/temp_motd | sed "s/^/$ART_SPACES/"
    fi

    rm /tmp/temp_motd
}

draw_login() {
    # TODO Remove the need to load the conf here...
    # Setup XDG Base Directory Paths
    XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}

    # Load SparkX Conf if it exists
    if [ -f ~/.sparkxconf ]; then # Deprecated (migrate)
        mv ~/.sparkxconf ~/.sparkx.conf
    elif [ -f ~/.sparkx.conf ]; then
        mv ~/.sparkx.conf $XDG_CONFIG_HOME/sparkxhome/config
    fi
    if [ -f $XDG_CONFIG_HOME/sparkxhome/config ]; then
        source $XDG_CONFIG_HOME/sparkxhome/config
    fi

    # Set vars
    local MOTD_USE_OS_ART=${SPARKX_HOME_MOTD_USE_OS_ART:-true}
    local MOTD_USE_CUSTOM_ART=${SPARKX_HOME_MOTD_USE_CUSTOM_ART:-}
    local MOTD_WIDTH=${SPARKX_HOME_MOTD_WIDTH:-80}
    local TERM_WIDTH=`tput cols`
    
    # Draw the host art
    if $MOTD_USE_OS_ART; then
        draw_os_art $TERM_WIDTH $MOTD_WIDTH
    elif [[ -n "$MOTD_USE_CUSTOM_ART" ]]; then
        draw_custom_art $TERM_WIDTH $MOTD_WIDTH "$MOTD_USE_CUSTOM_ART"
    else
        draw_original_art $TERM_WIDTH $MOTD_WIDTH
    fi
    
}
if [[ $BASH_SOURCE == $0 ]]; then
    draw_login
    if [[ $# -gt 0 ]]; then
        bash -ic "$@"
    else
        bash
    fi
    exit
fi
