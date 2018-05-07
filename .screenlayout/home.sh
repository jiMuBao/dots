#!/bin/sh
xrandr --output DP-1 --off --output HDMI-1 --mode 2048x1080 --pos 3200x0 --rotate normal --output eDP-1 --scale 0.5x0.5 --primary --mode 3200x1800 --pos 0x0 --rotate normal --output HDMI-2 --off
# xrandr --output DP-1 --mode 1920x1080 --pos 0x0 --rotate left --output HDMI-1 --off --output eDP-1 --scale 0.5x0.5 --primary --mode 3200x1800 --pos 1080x0 --rotate normal --output HDMI-2 --off