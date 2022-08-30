#!/usr/bin/env bash
# Restore plasma desktop layout from backup
if [ $UID -ne 0 ]; then
echo "run with sudo"
else
sudo cp /home/jjenkx/.config/plasma-org.kde.plasma.desktop-appletsrc.bak /home/jjenkx/.config/plasma-org.kde.plasma.desktop-appletsrc

sudo cp /home/jjenkx/.config/plasmashellrc.bak /home/jjenkx/.config/plasmashellrc

sudo chmod 400 /home/jjenkx/.config/plasma-org.kde.plasma.desktop-appletsrc /home/jjenkx/.config/plasmashellrc

timeout 5 kquitapp5 plasmashell

pgrep -U $USER -x plasmashell &>/dev/null && pkill -U $USER -x plasmashell

pgrep -U $USER -x plasmashell &>/dev/null && pkill -U $USER -x -9 plasmashell # here the process does not get to clean-up.

killall -9 plasmashell #sends a signal to all processes running any of the specified commands

pgrep -U $USER -x plasmashell &>/dev/null && echo "ERROR: cannot kill plasmashell"

sudo chmod 600 /home/jjenkx/.config/plasma-org.kde.plasma.desktop-appletsrc /home/jjenkx/.config/plasmashellrc

sleep 2s

setsid >/dev/null 2>&1 </dev/null nohup kstart5 plasmashell 2>&1 >/dev/null & 

echo "Script done"

fi
