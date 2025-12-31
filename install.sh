#!/bin/bash
# Installs SparkX120 Symlinked Environment

SPARKX_HOME_CLONE_DIR=${SPARKX_HOME_CLONE_DIR:-`pwd`}
SPARKX_HOME_RUNTIME=${SPARKX_HOME_RUNTIME:-setup}
if [[ "$SPARKX_HOME_RUNTIME" == "setup" ]]; then
    set -e
fi

sparkx-install-get-packages() {
    # Usage get-packages <system> <group>
    local system=$1
    shift
    local groups=()

    while [ "$#" -gt 0 ]; do
        groups+=($1)
        shift
    done
    
    SPARKX_INSTALL_PACKAGES=${SPARKX_INSTALL_PACKAGES:-()}

    for group in ${groups[@]}; do
        < $SPARKX_HOME_CLONE_DIR/packages/$system/$group mapfile -O ${#SPARKX_INSTALL_PACKAGES[@]} SPARKX_INSTALL_PACKAGES
    done
}

sparkx-install-core-arch() {
    echo "Install common base software on Arch Base"
    echo "sudo will be required"

    sparkx-install-get-packages arch $@

    sudo pacman -Sy --needed --noconfirm "${SPARKX_INSTALL_PACKAGES[@]}"
}

sparkx-install-core-debian() {
    echo "Install common base software on Debian Base"
    echo "sudo will be required"

    sparkx-install-get-packages debian $@

    sudo apt update
    sudo apt install -y "${SPARKX_INSTALL_PACKAGES[@]}"
}


sparkx-install-core() {
    echo "Installing core SparkXHome environment."

    if hash apt 2>/dev/null; then
        sparkx-install-core-debian
    elif hash pacman 2>/dev/null; then
        sparkx-install-core-arch
    fi
}

sparkx-install-sparkx-conf-default() {
    if [[ ! -f $XDG_CONFIG_HOME/sparkxhome/config ]]; then
        cp $SPARKX_HOME_CLONE_DIR/default.config $XDG_CONFIG_HOME/sparkxhome/config
        echo "SPARKX_HOME_CLONE_DIR=$SPARKX_HOME_CLONE_DIR" >> $XDG_CONFIG_HOME/sparkxhome/config
        echo "Installed default $XDG_CONFIG_HOME/sparkxhome/config"
    else
        echo "$XDG_CONFIG_HOME/sparkxhome/config already exists, skipping default load (please check for any new vars)"
    fi
}

sparkx-install-link-home() {
    echo "Setup Home directory"
    cd $SPARKX_HOME_CLONE_DIR/home/
    mkdir -p ~/homebackup
    shopt -s dotglob
    for f in *; do
        if [[ "$f" == ".config" || "$f" == ".local" ]]; then
            :
        elif [[ -h ~/$f ]]; then
            echo "$f already linked..."
        else
            echo "Linking $f"
            if [[ -f ~/$f || -d ~/$f ]]; then
                echo "Found existing version of $f, backing up"
                mv ~/$f ~/homebackup
            fi
            ln -s `pwd`/$f ~/$f
        fi
    done
    shopt -u dotglob

    # TODO have a proper directory setup system for default dirs
    # TODO create a bootstrap script to get the rest of the setup on sparkx120.com
    mkdir -p ~/projects

    cd -
}

sparkx-install-link-config() {
    echo "Setup config directory"
    mkdir -p $SPARKX_HOME_CLONE_DIR/home/.config
    cd $SPARKX_HOME_CLONE_DIR/home/.config
    mkdir -p ~/.config/configbackup
    shopt -s dotglob
    for f in *; do
        if [[ -h ~/.config/$f ]]; then
            echo "$f already linked..."
        else
            if [[ -f ~/.config/$f || -d ~/.config/$f ]]; then
                mv ~/.config/$f ~/.config/configbackup
                echo "Found existing version of $f, backing up"
            fi
            ln -s `pwd`/$f ~/.config/$f
        fi
    done
    shopt -u dotglob
    cd -
}

sparkx-install-local() {
    echo "Setup .local"

    local link=false

    while [ "$#" -gt 0 ]; do
        case $1 in
            link) link=true ;;
        esac
        shift
    done

    mkdir -p ~/.local/bin
    mkdir -p ~/.local/share/sparkxhome/scripts/plugins

    if [[ "$link" == "false" ]]; then
        cp -R $SPARKX_HOME_CLONE_DIR/home/.local/share/sparkxhome/scripts/core/ ~/.local/share/sparkxhome/scripts/
    else
        if [[ -h $SPARKX_HOME_CLONE_DIR/home/.local/share/sparkxhome/scripts/core ]]; then
            echo ".local already linked..."
        else
            ln -s $SPARKX_HOME_CLONE_DIR/home/.local/share/sparkxhome/scripts/core ~/.local/share/sparkxhome/scripts/core
        fi
    fi
}

sparkx-install-main() {
    echo "Welcome to the SparkXHome Environment Installation Script ✨"
    echo "Press any key to continue..."

    read -n -s 1

    echo "Installing SparkXHome Environment ✨"
    sparkx-install-core
    sparkx-install-sparkx-conf-default
    sparkx-install-link-home
    sparkx-install-link-config
    sparkx-install-local link
    echo "Finished installing environment 🥳"
}

if [[ $BASH_SOURCE != $0 ]]; then
    if [[ "$SPARKX_HOME_RUNTIME" == "setup" ]]; then
        echo "Welcome to the SparkXHome interactive shell setup!"
    fi
else
    sparkx-install-main
fi
