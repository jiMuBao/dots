#!/bin/sh
xrandr --output DP1 --mode 1680x1050 --rotate left --left-of eDP1 --output eDP1 --primary --mode 3200x1800 --scale 0.5x0.5 --rotate normal --output HDMI1 --mode 1680x1050 --right-of eDP1 --rotate normal --output HDMI2 --off --output VIRTUAL1 --off
