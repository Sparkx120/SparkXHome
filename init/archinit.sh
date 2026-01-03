#!/bin/bash
##
# archinit
# v0.1.0
#
# A very opinionated initialization script for an arch system
#
# This script assumes a lot including:
# - The entire drive you select will be used for just Arch
# - You only have one OS, namely Arch installed and don't need a bootloader (UKI)
# - Partitioning and disk layout
# - Encryption setup
# - Basic software
# 
# Some References:
# - https://wiki.archlinux.org/title/Installation_guide
# - https://wiki.archlinux.org/title/User:Bai-Chiang/Arch_Linux_installation_with_unified_kernel_image_(UKI),_full_disk_encryption,_secure_boot,_btrfs_snapshots,_and_common_setups
#
# This script is meant to run from the arch installation environment
# See: https://archlinux.org/download/
##
if [[ "${DEBUG_SETUP}" == "true" ]]; then
    set -x
fi
set -euo pipefail


PACKAGES=(
    base
    linux
    linux-firmware
    efibootmgr
    zram-generator
    btrfs-progs
    dosfstools
    e2fsprogs
    exfatprogs
    cryptsetup
    sudo
    openssh
    man-db
    vim
    curl
    less
    pacman-contrib
    reflector
    ufw
    noto-fonts-cjk
    noto-fonts-emoji
    networkmanager
    iwd
)

declare -A CPU_PACKAGES=(
    ["intel"]="intel-ucode"
    ["amd"]="amd-ucode"
)

declare -A GPU_PACKAGES=(
    ["intel"]="mesa vulkan-intel intel-media-driver"
    ["nvidia"]="nvidia-open nvidia-utils"
    ["radeon"]="mesa vulkan-radeon"
    ["none"]=""
)

SETUP_HOSTNAME=
CPU_TYPE=
GPU_TYPE=
ROOT_UUID=
BOOT_UUID=
BOOT_DEV=

safe_sed_inplace() {
    local from=$1
    local to=$2
    local file=$3
    sed -i "s|$from|$to|gw /tmp/changelog.txt" $file
    if ! [[ -s /tmp/changelog.txt ]]; then
        printf "🥾 Error - sed manipulation failed 🥹...\nsed $@"
        exit 1
    fi
    rm /tmp/changelog.txt
}

verify_uefi_architecture() {
    if [[ "$(cat /sys/firmware/efi/fw_platform_size)" == "64" ]]; then
        printf "💻 Booted with UEFI in 64bit mode..."
    else
        printf "💻 Did not boot in expected mode 🥹..."
        exit 1
    fi
}

verify_internet() {
    printf "💻 Checking Internet connection..."
    if cat < /dev/null > /dev/tcp/1.1.1.1/53; then
        printf "💻 Internet connection verified..."
    else
        printf "💻 No Internet detected, please configure connection 🥹..."
        exit 1
    fi
}

set_hostname() {
    clear
    printf "💻 What should the hostname of your computer be (arch): "

    read in
    SETUP_HOSTNAME=$in

    if [[ "$SETUP_HOSTNAME" == "" ]]; then
        SETUP_HOSTNAME="arch"
    fi
}

set_cpu_type() {
    clear
    printf "💻 Processor Selection"
    printf "\n\nintel\namd"
    printf "\n\nWhat processessor are you using (amd): "

    read in
    CPU_TYPE=$in

    if [[ "$CPU_TYPE" == "" ]]; then
        CPU_TYPE="amd"
    fi
    if [[ "$CPU_TYPE" != "intel" && "$CPU_TYPE" != "amd" ]]; then
        printf "💻 Error - Invalid CPU Type selected 🥹..."
        exit 1
    fi 
}

set_gpu_type() {
    clear
    printf "💻 GPU Selection"
    printf "\n\nintel\nradeon\nnvidia\nnone"
    printf "\n\nWhat gpu are you using (none): "
    
    read in
    GPU_TYPE=$in
    
    if [[ "$GPU_TYPE" == "" ]]; then
        GPU_TYPE="none"    
    fi
    if [[ "$GPU_TYPE" != "intel" && "$GPU_TYPE" != "radeon" && "$GPU_TYPE" != "nvidia" && "$GPU_TYPE" != "none" ]]; then
        printf "💻 Error - Invalid GPU Type selected 🥹..."
        exit 1
    fi
}

setup_mirrors() {
    clear
    printf "🪞 Mirror Setup"
    printf "\n\n🪞 Choose a country by code or name\n(see reflector --list-countries for full list)\n\nExample: CA or Canada"
    
    local country=
    
    while [[ "${country}" == "" ]]; do
        printf "\n\n🪞 Please enter a country to use for your mirrors (CA): "
        read in_country

        if [[ "${in_country}" == "" ]]; then
            in_country=CA
        fi

        if reflector --list-countries | grep ${in_country} > /dev/null; then
            country=${in_country}
        else
            printf "\n🪞 Sorry the country selected is not available, check reflector -L for possible countries, please try again..."
        fi
    done

    printf "\n\n🪞 Checking for the fastest 5 mirrors and saving..."
    reflector -c $country --latest 10 --fastest 5 --save /etc/pacman.d/mirrorlist
}

setup_drive() {
    clear
    printf "📀 Drive Setup\n\n"
    lsblk

    local dev=
 
    while [[ "$dev" == "" ]]; do
        printf "📀 Please select a drive to format for Arch Linux (ex. sda): "
    
        read in_dev

        if [[ -b "/dev/${in_dev}" ]]; then
            dev="/dev/${in_dev}"
        else
            printf "📀 No such block device "${in_dev}" please try again..."
        fi
    done
 
    BOOT_DEV=${dev}
    local devp=${dev}

    if [[ "${dev}" == *"nvme"* ]]; then
        devp+='p'
    fi    

    printf "\n\n📀 Press any key to destroy all existing partition tables on ${dev} and reinitialize it..."

    read -s -n 1

    printf "\n\n"
    
    sgdisk -Z $dev
    partprobe $dev

    local drive_password=""
    while [[ "${drive_password}" == "" ]]; do
    
        printf "\n\n🔒 Please provide a passphrase for drive encryption: "
        read -s drive_password1
        printf "\n🔒 Please enter the same password again: "
        read -s drive_password2

        if [[ "${drive_password1}" == "${drive_password2}" ]]; then
            drive_password=${drive_password1}
        else
            printf "\n🔒 Sorry the passwords do not match please try again!"
        fi

        unset drive_password1
        unset drive_password2    
    done

    printf "\n\n📀 Creating Standard EFI Partition Layout with encryption..."
    
    sgdisk -n 1::+512M -t 1:ef02 -c "EFI System" $dev > /dev/null
    sgdisk -n 2:: -t 1:8309 -c "Linux" $dev > /dev/null

    echo "${drive_password}" | cryptsetup luksFormat -q ${devp}2 > /dev/null
    echo "${drive_password}" | cryptsetup open ${devp}2 cryptroot > /dev/null
    unset drive_password

    mkfs.fat ${devp}1
    mkfs.btrfs /dev/mapper/cryptroot

    BOOT_PARTUUID=$(lsblk -dno PARTUUID ${devp}1)
    ROOT_UUID=$(lsblk -dno UUID ${devp}2)    

    mount /dev/mapper/cryptroot /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@var_log
    btrfs subvolume create /mnt/@pacman_pkgs
    
    mkdir /mnt/@/home
    mkdir /mnt/@/.snapshots
    mkdir /mnt/@/efi
    mkdir -p /mnt/@/var/log
    mkdir -p /mnt/@/var/cache/pacman/pkg

    umount -R /mnt
 
    mount -o autodefrag,subvol=@ /dev/mapper/cryptroot /mnt
    mount -o autodefrag,nodev,subvol=@home /dev/mapper/cryptroot /mnt/home
    mount -o autodefrag,nodev,nosuid,noexec,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
    mount -o autodefrag,nodev,nosuid,noexec,subvol=@var_log /dev/mapper/cryptroot /mnt/var/log
    mount -o autodefrag,nodev,nosuid,noexec,subvol=@pacman_pkgs /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg

    mount -o fmask=0177,dmask=0077,noexec,nosuid,nodev ${devp}1 /mnt/efi
}

setup_pacstrap() {
    clear

    printf "📀 Pacstrapping installation...\n\n"

    # There is an error in mkinitcpio that causes vconsole.conf in sd-vconsole to fail if the file is missing
    # See: https://bbs.archlinux.org/viewtopic.php?pid=2272999#p2272999
    mkdir -p /mnt/etc
    cp /etc/vconsole.conf /mnt/etc/vconsole.conf

    pacstrap_cmd=(pacstrap -K /mnt "${PACKAGES[@]}" "${CPU_PACKAGES[$CPU_TYPE]}")
    if [[ "${GPU_PACKAGES[$GPU_TYPE]}" != "" ]]; then
        pacstrap_cmd+=("${CPU_PACKAGES[$CPU_TYPE]}")
    fi
    "${pacstrap_cmd[@]}"
   
    printf "📀 Setting Hostname and Configuring fstab..." 
    echo $SETUP_HOSTNAME > /mnt/etc/hostname 

    mkdir -p /mnt/etc
    genfstab -U /mnt >> /mnt/etc/fstab
    sed -i '/btrfs/s/subvolid=[0-9]*,//g' /mnt/etc/fstab

    printf "📀 Setting up common services..."
    arch-chroot /mnt systemctl enable NetworkManager.service
    arch-chroot /mnt systemctl enable paccache.timer
    arch-chroot /mnt systemctl enable ufw.service

    printf "📀 Optimize CFLAGS"
    echo todo
}

setup_region() {
    clear

    printf "⌚ Timezone Configuration:\n\n"
    printf "Africa\nAmerica\nAntarctica\nArctic\nAsia\nAtlantic\nEurope\nPacific\n\n"
    
    local region=
    while [[ "${region}" == "" ]]; do
        printf "⌚ Please select region: "
        read in_region

        if [[ -e" /usr/share/zoneinfo/${in_region}" ]]; then
            region=${in_region}
        else
            printf "⌚ Invalid Region please try again..."
        fi
    done

    clear

    printf "⌚ Timezone Configuration:\n\n"
    ls /usr/share/zoneinfo/$region
    
    local city=
    while [[ "${city}" == "" ]]; do
        printf "⌚ Please select closest city or country: "
        read in_city

        if [[ -e "/usr/share/zoneinfo/$region/${in_city}" ]]; then
            city=$in_city
        else
            printf "⌚ Invalid City/County please try again..."
        fi
    done
    
    printf "\n\n⌚ Setting the Timezone and Locale...\n\n"
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$region/$city
    arch-chroot /mnt hwclock --systohc
    arch-chroot /mnt systemctl enable systemd-timesyncd
    
    safe_sed_inplace "#en_US.UTF-8 UTF-8" "en_US.UTF-8 UTF-8" /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
}

setup_boot() {
    clear
    printf "🥾 Setting up Boot...\n\n"
    
    # Setup mkinitcpio.conf
    sed -i "s|MODULES=.*$|MODULES=\(keyboard usbhid xhci_hcd\)|" /mnt/etc/mkinitcpio.conf
    sed -i "s|HOOKS=.*$|HOOKS=\(base systemd autodetect microcode modconf kms keyboard keymap sd-vconsole block sd-encrypt filesystems fsck\)|" /mnt/etc/mkinitcpio.conf

    # Setup mkinitcpi.d/linux.preset for Unified Kernal Image
    sed -i "s|default_image|#default_image|" /mnt/etc/mkinitcpio.d/linux.preset
    sed -i "s|#default_uki|default_uki|" /mnt/etc/mkinitcpio.d/linux.preset   
   
    # Setup kernel commandline
    echo "root=/dev/mapper/cryptroot rootfstype=btrfs rootflags=subvol=/@ rw modprobe.blacklist=pcspkr zswap.enabled=0" > /mnt/etc/kernel/cmdline
    echo "root=/dev/mapper/cryptroot rootfstype=btrfs rootflags=subvol=/@ rw modprobe.blacklist=pcspkr zswap.enabled=0" > /mnt/etc/kernel/cmdline_fallback

    # Setup crypttab.initramfs
    echo "cryptroot  UUID=${ROOT_UUID}  -  password-echo=no,x-systemd.device-timeout=0,timeout=0,no-read-workqueue,no-write-workqueue,discard" > /mnt/etc/crypttab.initramfs

    mkdir -p /mnt/efi/EFI/Linux
    arch-chroot /mnt mkinitcpio -P
    # TODO cleanup leftover initramfs-*.img

    # Setup EFI Boot
    arch-chroot /mnt efibootmgr --create --disk ${BOOT_DEV} --part 1 --label "ArchLinux" --loader 'EFI\Linux\archLinux-linux.efi' --unicode
    arch-chroot /mnt efibootmgr -D 
    
    #arch-chroot /mnt efibootmgr > boot.txt
    #local new_entry=$(grep $BOOT_PARTUUID boot.txt | awk '{print $1}' | sed 's|Boot||' | sed 's|\*||')
    #local existing_boot_order=$(grep BootOrder boot.txt | awk '{print $2}')

    #if [[ "${new_entry}" == "" ]]; then
    #    printf "🥾 Error Manipulating EFI Boot, please check your efibootmgr state and fix as needed!!!"
    #    exit 1
    #fi

    #arch-chroot /mnt efibootmgr -a -b ${new_entry}
    #arch-chroot /mnt efibootmgr --bootorder ${new_entry},${existing_boot_order}
}

setup_user() {
    clear
    printf "🧝 User Setup"
    
    printf "\n\n🧝 Enter username: "
    
    read username

    local password=""
    while [[ "${password}" == "" ]]; do
    
        printf "\n\n🔒 Please enter a password: "
        read -s password1
        printf "\n🔒 Please enter the same password again: "
        read -s password2

        if [[ "${password1}" == "${password2}" ]]; then
            password=${password1}
        else
            printf "\n🔒 Sorry the passwords do not match please try again!"
        fi

        unset password1
        unset password2    
    done

    arch-chroot /mnt useradd -m ${username}
    # I know I could just use this directly but I have a style I am going for here :3
    printf "${password}\n${password}" | arch-chroot /mnt passwd ${username} 2&>1 /dev/null
    unset password
    
    arch-chroot /mnt usermod --append --groups wheel ${username}
    safe_sed_inplace "# \(.*\)wheel ALL=(ALL:ALL) ALL" "\1wheel ALL=(ALL:ALL) ALL" /mnt/etc/sudoers
    
    curl https://sparkx120.com/bulk/sparkxhome_init.sh > /mnt/home/${username}/sparkxhome_init.sh 2> /dev/null
    arch-chroot /mnt chown ${username} /home/${username}/sparkxhome_init.sh
    arch-chroot /mnt chmod +x /home/${username}/sparkxhome_init.sh
}

main() {
    verify_uefi_architecture
    verify_internet
    timedatectl
    
    clear
    printf "✨ Welcome to archinit ✨\n\n"
    printf "This script will setup a base Arch Linux system for you\n\n"
    
    printf "Press any key to continue..."
    
    read -s -n 1

    # Hardward Setup
    set_hostname
    set_cpu_type
    set_gpu_type
    
    # SSH is open by default, we don't want that
    systemctl stop sshd

    # Mirror Setup
    setup_mirrors
    # Drive Setup
    setup_drive

    # Pacstrap
    setup_pacstrap
    setup_region
    setup_boot
    setup_user

    clear
    printf "🎉 Setup Complete 🎉"
    printf "\n\nYou may continue working on the archinstall iso or reboot into the system"
    printf "\nA copy of sparkxhome_init.sh has been conveniently left in your home directory to finish setting up"
    printf "\n\nHave a wonderful day 😄\n\n"
}

if [[ $BASH_SOURCE == $0 ]]; then
    main
fi
