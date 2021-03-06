#!/bin/sh
# xrandr --output DP-1 --mode 1920x1080 --pos 0x0 --rotate left --output
#  HDMI-1 --mode 1920x1080 --pos 1080x0 --rotate normal --output 
# eDP-1 --primary --scale 0.5x0.5 --mode 3200x1800 --pos 3000x0 --rotate normal 
# --output HDMI-2 --off

xrandr \
    --output DP1 --mode 1920x1080 --rotate left --left-of HDMI1 \
    --output HDMI1 --mode 1920x1080 --rotate normal \
    --output eDP1 --primary --scale 0.5x0.5 --mode 3200x1800 --right-of HDMI1
