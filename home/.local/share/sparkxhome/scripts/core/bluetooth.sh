#!/bin/bash

# Generic Helpers
_bt-init() {
    bluetoothctl power on
    sleep 1
    bluetoothctl agent on
    sleep 1
}
_bt-connect() {
    _bt-init
    bluetoothctl connect $1
}
_bt-pair() {
    _bt-init
    bluetoothctl trust $1
    bluetoothctl pair $1
    bluetoothctl connect $1
}

bt-pair-generic() {
    _bt-pair $1
}

bt-get-devices() {
    _bt-nit
    bluetoothctl scan on
}


bt-on() {
    _bt-init
}

bt-off() {
    bluetoothctl power off
}
