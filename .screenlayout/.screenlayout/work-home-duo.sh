#!/bin/sh
#xrandr --output DP-1 --off --output HDMI-1 --mode None --pos 0x0 --rotate normal --output eDP-1 --primary --mode 3200x1800 --pos 1920x0 --rotate normal --output HDMI-2 --off
xrandr \
    --output DP1 --off \
    --output HDMI1 --mode 1680x1050 --rotate normal \
    --output eDP1 --primary --scale 0.5x0.5 --mode 3200x1800 --right-of HDMI1

