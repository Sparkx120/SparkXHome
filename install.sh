#!/bin/bash
# Installs SparkX120 Symlinked Environment

# Constants
declare -rA OS_NAME_MAP=(["arch"]="Arch Linux" ["debian"]="Debian Linux")

# Setup XDG Base Directory Paths
XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}

SPARKX_HOME_CLONE_DIR=${SPARKX_HOME_CLONE_DIR:-`pwd`}
SPARKX_HOME_RUNTIME=${SPARKX_HOME_RUNTIME:-setup}
if [[ "$SPARKX_HOME_RUNTIME" == "setup" ]]; then
    set -euo pipefail
fi

declare -a SPARKX_INSTALL_PACKAGES=() 

sparkx-install-os-detect() {
    if hash apt 2>/dev/null; then
        echo debian
    elif hash pacman 2>/dev/null; then
        echo arch
    else
        echo unknown
    fi
}

sparkx-install-get-groups() {
    ls -1 $SPARKX_HOME_CLONE_DIR/packages/$(sparkx-install-os-detect) | xargs -L 1 basename | cut -f 1 -d '.' | uniq | tr '\n' ' '
}

sparkx-install-get-packages() {
    # Usage get-packages <system> <group>
    local system=$1
    shift
    local groups=()

    printf "\n⚙️  Installing packages defined in groups...\n"
    
    while [ "$#" -gt 0 ]; do
        groups+=(${1}.group.packages)
        shift
    done    

    for group in ${groups[@]}; do
        < $SPARKX_HOME_CLONE_DIR/packages/$system/$group mapfile -t -O ${#SPARKX_INSTALL_PACKAGES[@]} SPARKX_INSTALL_PACKAGES
    done
}

sparkx-install-core-arch() {
    printf "Installing packages"
    printf "sudo will be required"

    sparkx-install-get-packages arch $@
    
    sudo pacman -Sy
    cmd=(sudo pacman -S --noconfirm "${SPARKX_INSTALL_PACKAGES[@]}")
    echo "${cmd[@]}"
    "${cmd[@]}"

    for group in ${@}; do
        local post_install_script=$SPARKX_HOME_CLONE_DIR/packages/arch/${group}.group.post
        if [[ -f $post_install_script ]]; then
            bash $post_install_script
        fi
    done
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
    mkdir -p $XDG_CONFIG_HOME/SparkXHome/
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
    mkdir -p $XDG_DATA_HOME

    if [[ -h $XDG_DATA_HOME/SparkXHome ]]; then
        echo ".local updating old link..."
        rm $XDG_DATA_HOME/SparkXHome
    else
        ln -s $SPARKX_HOME_CLONE_DIR/home/.local/share/SparkXHome $XDG_DATA_HOME/SparkXHome
    fi
}

sparkx-install-main() {
    clear
    printf "\n✨ Welcome to the SparkXHome Environment Installation Script ✨\n"
    
    local os=$(sparkx-install-os-detect)
    if [[ "$os" == "unknown" ]]; then
        printf "😱Unsupported Operating System"
        exit 1
    fi

    printf "\n💽 ${OS_NAME_MAP[$os]} base system detected\n"

    printf "\nℹ️  The following script will guide you through the setup of the SparkXHome Environment\n"
    printf "Please note that sudo is required if you wish to install packages\n"
    printf "Installing packages may cause issues on your computer unless you are doing first time setup\n"
    printf "This script will stop if any part of the script fails, if that occurs you will need to cleanup manually.\n"
    
    printf "\nThe following package groups are available for installation:\n"
    for g in $(sparkx-install-get-groups); do echo $g; done


    printf "\nPlease specify which groups you would like to install by listing them with spaces (you must include base):\n"
    
    read group_selection

    if [[ $group_selection != *"base"* ]]; then
        printf "\nThe base package will be automatically installed as it is required for SparkXHome components to work\n"
        group_selection="base $group_selection"
    fi
    
    printf "\nThe following packages have been selected:\n${group_selection}\n\nPress any key to begin installation:"
    read -s -n 1

    printf "\n🚀 Installing SparkXHome Environment!"
    if [[ "$os" == "arch" ]]; then
        sparkx-install-core-arch $group_selection
    elif [[ "$os" == "debian" ]]; then
        sparkx-install-core-debian $group_selection
    fi
    sparkx-install-sparkx-conf-default
    sparkx-install-link-home
    sparkx-install-link-config
    sparkx-install-link-local
    printf "\n\n🎉 Finished installing environment 🎉\n\nPress any key to reboot or ctrl-c to exit"
    
    read -s -n 1

    sudo systemctl reboot 
}

if [[ $BASH_SOURCE != $0 ]]; then
    if [[ "$SPARKX_HOME_RUNTIME" == "setup" ]]; then
        printf "Welcome to the SparkXHome interactive shell setup!\n"
    fi
else
    sparkx-install-main
fi
