##
# Shell
##
function sparkx-reload {
    source ~/.bashrc
}

##
# System
##
function sparkx-power-draw() {
	echo - | awk "{printf \"%.1f\", \
	$(( \
		$(cat /sys/class/power_supply/BAT1/current_now) * \
		$(cat /sys/class/power_supply/BAT1/voltage_now) \
	)) / 1000000000000 }" ; echo " W "
}

##
# Package Management
##
function sparkx-aur-install() {
    makepkg -sir 
}

function sparkx-pacman-update() {
    sudo pacman -Syu
}

function sparkx-pacman-orphaned() {
    sudo pacman -Qtdq
}

function sparkx-pacman-orphaned-clean() {
    sudo pacman -R $(pacman -Qtdq)
}

function sparkx-pacman-clean-cache () {
    sudo pacman -Sc
}

function sparkx-nvidia-force-composite-pipeline() {
    #https://techknowfile.dev/how-to-fix-screen-tearing-on-i3-wm-ubuntu-18-04/
    sudo nvidia-settings --assign CurrentMetaMode="nvidia-auto-select +0+0 { ForceFullCompositionPipeline = On }, HDMI-1-1: nvidia-auto-select +3840+0 {ForceCompositionPipeline=On}"
}

##
# Processes
##
sparkx-ps() {
    ps aux | grep "$1" | head -n -1
}

sparkx-kill() {
    sparkx-ps $1 | tee >(cat >&2) | awk '{print $2}' | xargs kill -9
}

sparkx-gnome-scope() {
    systemctl status --all 2> /dev/null | grep "app-gnome-.*$1.*[0-9]\.scope" | grep -v 'grep' | sed 's|.*app-gnome|app-gnome|g' | sort | uniq
}

sparkx-gnome-scope-kill() {
    sparkx-gnome-scope $1 | xargs systemctl --user stop
}

function sparkx-clear-caches() {
    sudo sync
    sudo sh -c "/usr/bin/echo 3 > /proc/sys/vm/drop_caches"
}

##
# Network
##
sparkx-netstat() {
    if [[ "$1" == '-r' ]]; then
        sudo netstat -t -u -e -N -W -p -a 2>/dev/null | tail -n +3 | column -t
    else
        netstat -t -u -e -N -W -p -a 2>/dev/null | tail -n +3 | column -t
    fi
}

sparkx-netstat-log() {
    touch netstat_record
    sparkx-netstat > netstat_realtime
    sort netstat_realtime netstat_record | column -t | uniq > netstat_sort
    mv netstat_sort netstat_record
}

sparkx-netstat-log-watch() {
    while true; do sparkx-netstat-log; sleep 1; done;
}

sparkx-net-ss-listeners() {
    ss -tulp
}

sparkx-net-ss-connections() {
    ss -tup
}

sparkx-net-application-connections() {
    sparkx-net-ss-connections | awk '{print $6 ", " $7}' | tail -n +2 | sed -e 's/\([0-9]\):.*, users:(("/\1, /' -e 's/]:.*, users:(("/], /' | sed 's|",pid.*$||g'
}

sparkx-secure-string() {
    length="${1:-16}"
    < /dev/urandom tr -dc 'a-zA-Z0-9' | head -c $length; echo
}

sparkx-clean-old-files() {
    echo "🔎 - Searching for all files older than $2 days in $1"
    find $1 -type f -mtime +$2 > $SPARKX_HOME_TMP_DIR/clean_old_files_list
    local file_count=`wc -l $SPARKX_HOME_TMP_DIR/clean_old_files_list | awk '{print $1}'`
    if [ "$file_count" -gt 0 ]; then
        echo -e "$file_count Files to be deleted!!!"
        read -rp "Are you sure you want to continue? [y/N] " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            xargs -d '\n' rm < $SPARKX_HOME_TMP_DIR/clean_old_files_list
        else
            echo "Aborted."
        fi
    else
        echo "No files older than $2 days in $1 found..."
    fi
}

