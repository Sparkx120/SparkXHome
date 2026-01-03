#!/bin/bash
set -eu
set -o pipefail

printf "✨ Welcome to the SparkX Home Environment Intialization Script ✨"
printf "\n\nPress any key to continue..."

read -s -n 1

if ! hash sudo 2>/dev/null; then
    print "\nThis script requires sudo 🥹"
    exit 1
fi

printf "\n\nInstalling minimum requiements on your system"

if hash apt 2>/dev/null; then
    sudo apt install -y git curl
elif hash pacman 2>/dev/null; then
    sudo pacman -Sy --needed --noconfirm git curl
fi

printf "\n\nSetup an ssh key (Yn): "

read setup_ssh

printf "\n"

if [[ "${setup_ssh}" == "" || "${setup_ssh}" == "y" || "${setup_ssh}" == "Y" ]]; then
    mkdir -p ~/.ssh
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

    printf "\n\nYour public key is: "
    cat ~/.ssh/id_ed25519.pub
    printf "\nPlease add it to GitHub and anywhere else you wish and then press any key to continue..."
fi

cd ~
mkdir -p projects
cd projects

printf "\n\nUse ssh to clone repo (Yn): "

read use_ssh

printf "\n"

if [[ "${use_ssh}" == "" || "${use_ssh}" == "y" || "${use_ssh}" == "Y" ]]; then
    git clone --recurse-submodules git@github.com:Sparkx120/SparkXHome.git
else
    git clone --recurse-submodules https://github.com/Sparkx120/SparkXHome.git
fi

cd SparkXHome
./install.sh
