#!/usr/bin/env bash
# Backup plasma desktop layout
if [ $UID -ne 0 ]; then
echo "run with sudo"
else

sudo cp /home/jjenkx/.config/plasma-org.kde.plasma.desktop-appletsrc /home/jjenkx/.config/plasma-org.kde.plasma.desktop-appletsrc.bak

sudo cp /home/jjenkx/.config/plasmashellrc /home/jjenkx/.config/plasmashellrc.bak

fi
