#!/bin/bash
# Installs SparkX120 Symlinked Environment

SPARKX_HOME_CLONE_DIR=${SPARKX_HOME_CLONE_DIR:-`pwd`}
SPARKX_HOME_RUNTIME=${SPARKX_HOME_RUNTIME:-setup}
if [[ "$SPARKX_HOME_RUNTIME" == "setup" ]]; then
    set -eo pipefail
fi

sparkx-install-os-detect() {
    if hash apt 2>/dev/null; then
        echo debian
    elif hash pacman 2>/dev/null; then
        echo arch
    else
        echo unknown
    fi
}

sparkx-install-get-packages() {
    # Usage get-packages <system> <group>
    local system=$1
    shift
    local groups=()

    while [ "$#" -gt 0 ]; do
        groups+=($1)
        shift
    done
    
    for group in ${groups[@]}; do
        < $SPARKX_HOME_CLONE_DIR/packages/$system/$group mapfile -t -O ${#SPARKX_INSTALL_PACKAGES[@]} SPARKX_INSTALL_PACKAGES
    done
}

sparkx-install-core-arch() {
    echo "Install common base software on Arch Base"
    echo "sudo will be required"

    sparkx-install-get-packages arch $@
    
    sudo pacman -Sy
    cmd=(sudo pacman -S --noconfirm "${SPARKX_INSTALL_PACKAGES[@]}")
    echo "${cmd[@]}"
    "${cmd[@]}"
}

sparkx-install-core-debian() {
    echo "Install common base software on Debian Base"
    echo "sudo will be required"

    sparkx-install-get-packages debian $@

    sudo apt update
    cmd=(sudo apt install -y "${SPARKX_INSTALL_PACKAGES[@]}")
    echo "${cmd[@]}"
    "${cmd[@]}"
}


sparkx-install-sparkx-conf-default() {
    if [[ ! -f $XDG_CONFIG_HOME/SparkXHome/config ]]; then
        cp $SPARKX_HOME_CLONE_DIR/default.config $XDG_CONFIG_HOME/SparkXHome/config
        echo "SPARKX_HOME_CLONE_DIR=$SPARKX_HOME_CLONE_DIR" >> $XDG_CONFIG_HOME/SparkXHome/config
        echo "Installed default $XDG_CONFIG_HOME/SparkXHome/config"
    else
        echo "$XDG_CONFIG_HOME/SparkXHome/config already exists, skipping default load (please check for any new vars)"
    fi
}

sparkx-install-link-home() {
    echo "Setup Home directory"
    cd $SPARKX_HOME_CLONE_DIR/home/
    mkdir -p ~/homebackup
    shopt -s dotglob
    for f in *; do
        if [[ "$f" == ".config" || "$f" == ".local" ]]; then
            continue
        elif [[ -h ~/$f ]]; then
            echo "$f updating old link..."
            rm ~/$f
        fi
        echo "Linking $f"
        if [[ -f ~/$f || -d ~/$f ]]; then
            echo "Found existing version of $f, backing up"
            mv ~/$f ~/homebackup
        fi
        ln -s `pwd`/$f ~/$f
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
            echo "$f updating old link..."
            rm ~/.config/$f
        fi
        if [[ -f ~/.config/$f || -d ~/.config/$f ]]; then
            mv ~/.config/$f ~/.config/configbackup
            echo "Found existing version of $f, backing up"
        fi
        ln -s `pwd`/$f ~/.config/$f
    done
    shopt -u dotglob
    cd -
}

sparkx-install-link-local() {
    echo "Setup .local"

    mkdir -p ~/.local/bin

    if [[ -h ~/.local/share/SparkXHome ]]; then
        echo ".local updating old link..."
        rm ~/.local/share/SparkXHome
    else
        ln -s $SPARKX_HOME_CLONE_DIR/home/.local/share/SparkXHome ~/.local/share/SparkXHome
    fi
}

sparkx-install-main() {
    clear
    echo "Welcome to the SparkXHome Environment Installation Script ✨"
    
    local os=$(sparkx-install-os-detect)
    if [[ "$os" == "unknown" ]]; then
        echo "Unsupported Operating System 😱"
        exit 1
    fi

    echo "$os detected! 🎉"
    
    local available_groups=`ls -p packages/$os | grep -v /`

    echo ""
    echo "The following package groups are available for installation:"
    for g in $available_groups; do echo $g; done

    echo ""
    echo "Please specify which groups you would like to install by listed them with spaces (you must include base):"
    
    read group_selection

    echo "Installing SparkXHome Environment ✨"
    if [[ "$os" == "arch" ]]; then
        sparkx-install-core-arch $group_selection
    elif [[ "$os" == "debian" ]]; then
        sparkx-install-core-debian $group_selection
    fi
    sparkx-install-sparkx-conf-default
    sparkx-install-link-home
    sparkx-install-link-config
    sparkx-install-link-local
    echo "Finished installing environment 🥳"
}

if [[ $BASH_SOURCE != $0 ]]; then
    if [[ "$SPARKX_HOME_RUNTIME" == "setup" ]]; then
        echo "Welcome to the SparkXHome interactive shell setup!"
    fi
else
    sparkx-install-main
fi
