#!/usr/bin/env bash
# Restore plasma desktop layout from backup
sudo cp $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc.bak $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc
sudo cp $HOME/.config/plasmashellrc.bak $HOME/.config/plasmashellrc
sudo chmod 400 $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/plasmashellrc
timeout 5 kquitapp5 plasmashell
pgrep -U $USER -x plasmashell &>/dev/null && sudo pkill -U $USER -x plasmashell
sleep 1s
pgrep -U $USER -x plasmashell &>/dev/null && sudo pkill -U $USER -x -9 plasmashell &>/dev/null # here the process does not get to clean-up.
sleep 1s
sudo killall -9 plasmashell &>/dev/null #sends a signal to all processes running any of the specified commands
sleep 1s
pgrep -U $USER -x plasmashell &>/dev/null && echo "ERROR: cannot kill plasmashell"
sudo chmod 600 $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/plasmashellrc
sleep 2s
setsid >/dev/null 2>&1 </dev/null nohup kstart5 plasmashell 2>&1 >/dev/null & 
echo "Script done"
