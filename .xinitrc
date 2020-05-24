#!/bin/sh

# /etc/X11/xinit/xinitrc
#
# global xinitrc file, used by all X sessions started by xinit (startx)

# invoke global X session script
. /etc/X11/Xsession
[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources

[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap

#xrandr --newmode "1920x1080_60.00"  173.00  1920 2048 2248 2576  1080 1083 1088 1120 -hsync +vsync
#xrandr --addmode eDP-1 1920x1080_60.00

~/.fehbg &
