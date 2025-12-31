#!/bin/bash

sparkx-weather() {
    curl -s wttr.in/
}

sparkx-weather-hourly() {
    curl -s v2.wttr.in/
}

sparkx-weather-watch() {
    while true; do
        clear
        sparkx-weather
        sleep 3600
    done
}

sparkx-weather-hourly-watch() {
    while true; do
        clear
        sparkx-weather-hourly
        sleep 3600
    done
}
