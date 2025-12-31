#!/bin/bash
function dockerized-wayland() {
    if [ -z "$1" ]; then
        local CONTAINER_IMAGE="ubuntu:20.04"
    else
        local CONTAINER_IMAGE="$1"
    fi
    docker run -d --rm --name sparkx-wayland --net=host \
               -v /run/user/$(id -u)/pulse:/run/user/0/pulse \
               -v /tmp/.X11-unix:/tmp/.X11-unix \
               -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY \
               -e XDG_RUNTIME_DIR=/tmp \
               -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
               -e QT_QPA_PLATFORM=wayland \
               -e GDK_BACKEND=wayland \
               -e CLUTTER_BACKEND=wayland \
               -e DISPLAY=$DISPLAY \
               $CONTAINER_IMAGE /bin/bash -c "while true; do sleep 1; done;"
    docker exec sparkx-wayland /bin/bash -c "apt update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata"
    docker exec sparkx-wayland /bin/bash -c "apt install -y --no-install-recommends pulseaudio"
}

function dockerized-wayland-install-ff() {
    docker exec sparkx-wayland /bin/bash -c "apt install -y firefox"
}

function dockerized-wayland-exec() {
    docker exec sparkx-wayland /bin/bash -c "$@"
}

function dockerized-wayland-stop() {
    docker stop sparkx-wayland
}
