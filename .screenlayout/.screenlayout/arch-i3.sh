#!/bin/sh
xrandr --newmode 1920x1080_60.00  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
xrandr --addmode eDP-1 1920x1080_60.00
xrandr --output DP-1 --mode 1920x1080 --pos 0x0 --rotate left --output HDMI-1 --off --output eDP-1 --primary --mode 1920x1080_60.00 --pos 1080x0 --rotate normal --output HDMI-2 --off
