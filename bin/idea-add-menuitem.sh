#!/bin/bash
#
# Resolve the location of the installation.
# This includes resolving any symlinks.
PRG=$0
while [ -h "$PRG" ]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '^.*-> \(.*\)$' 2>/dev/null`
    if expr "$link" : '^/' 2> /dev/null >/dev/null; then
        PRG="$link"
    else
        PRG="`dirname "$PRG"`/$link"
    fi
done

PRG_BIN=`dirname "$PRG"`

# absolutize dir
oldpwd=`pwd`
cd "${PRG_BIN}"
PRG_BIN=`pwd`
cd "${oldpwd}"

ICON_NAME=jetbrains-idea
TMP_DIR=`mktemp --directory`
DESKTOP_FILE=$TMP_DIR/jetbrains-idea.desktop
cat << EOF > $DESKTOP_FILE
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=Intellij IDEA
Keywords=java;intellij;idea
GenericName=Java Integrated Development Environment
Type=Application
Categories=Development;Programming
Terminal=false
StartupNotify=true
Exec="$PRG_BIN/idea.sh" %u
Icon=$ICON_NAME.png
EOF

xdg-desktop-menu install $DESKTOP_FILE
xdg-icon-resource install --size 128 "$PRG_BIN/$ICON_NAME.png" $ICON_NAME

rm $DESKTOP_FILE
rm -R $TMP_DIR
