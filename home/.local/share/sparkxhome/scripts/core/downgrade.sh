#!/bin/bash
function downgrade-linux-5.12.15 () {
    sudo pacman -U https://archive.archlinux.org/packages/l/linux/linux-5.12.15.arch1-1-x86_64.pkg.tar.zst
}
function downgrade-freetype-2.10.4-1() {
    sudo pacman -U https://archive.archlinux.org/packages/f/freetype2/freetype2-2.10.4-1-x86_64.pkg.tar.zst
}
