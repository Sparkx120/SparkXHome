#!/bin/bash
set -eu
set -o pipefail

echo "Welcome to the SparkX Home Environment Intialization Script ✨"
echo "Press any key to continue..."

read -s -n 1

if ! hash sudo 2>/dev/null; then
    echo "This script requires sudo 🥹"
    exit 1
fi

echo "Installing minimum requiements on your system"

if hash apt 2>/dev/null; then
    sudo apt install -y git curl
elif hash pacman 2>/dev/null; then
    sudo pacman -Sy --needed --noconfirm git curl
fi

cd ~
mkdir -p projects
cd projects
git clone https://github.com/Sparkx120/SparkXHome.git
cd SparkXHome
./install.sh
