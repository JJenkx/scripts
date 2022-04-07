#!/bin/sh
# Last Change: 2022/04/07
# Apt-fast with Aria2 Pro Core https://github.com/P3TERX/Aria2-Pro-Core
# Modified from https://gist.github.com/voyeg3r/409041


# download: mkdir -p $HOME/.local/scripts && sudo wget -c https://gist.githubusercontent.com/JJenkx/adb7ce9e76038145adfdba6915ec9730/raw/4fd8eee8f0375f264374beab67af75051200439f/apt-fast -O $HOME/.local/scripts/apt_fast.sh && sudo chmod +x $HOME/.local/scripts/apt_fast.sh


# Auto add $HOME/.local/scripts to $PATH ?
# Uncomment and add to .bashrc file

# if [ -d "$HOME/.local/scripts" ]
# then
#   case :$PATH: # notice colons around the value
#     in *:$HOME/.local/scripts:*) ;; # do nothing, it's there
#        *) export PATH=$PATH:$HOME/.local/scripts ;;
#   esac
# fi


# apt-fast with proxy:
# aria2c -s 20 -j 10 --http-proxy=http://username:password@proxy_ip:proxy_port -i apt-fast.list

[ "`whoami`" = root ] || exec sudo "$0" "$@"

# If the user entered arguments contain upgrade, install, or dist-upgrade
if echo "$@" | grep -q "upgrade\|install\|dist-upgrade"; then
  echo "Working...";


  # Have apt-get print the information, including the URI's to the packages
  # Strip out the URI's, and download the packages with Aria2 Pro Core for speediness
  apt -y --print-uris $@ | egrep -o -e "(https?|ftp)://(www\.)?[^\']+" > /tmp/apt-fast.list;
  aria2c --continue=true --split=16 --max-connection-per-server=64 --max-concurrent-downloads=4 --min-split-size=8K --piece-length=1K --lowest-speed-limit=1K --dir="/var/cache/apt/archives" --input-file="/tmp/apt-fast.list" --connect-timeout=600 --timeout=600 -m0;

  # Perform the user's requested action via apt-get
  apt $@ -y;

  echo -e "\nDone! Verify that all packages were installed successfully. If errors are found, run apt-get clean as root and try again using apt-get directly.\n";

else
   apt $@;
fi

# Usage

# Update and Upgrade
# sudo apt update && sudo apt_fast.sh upgrade

# Install
# sudo apt_fast.sh install <PackageNames>



# My Aliases

# Install
# alias apti='sudo $HOME/.local/scripts/apt_fast.sh install'

#Update and Upgrade
# alias aptuu='sudo apt update && sudo $HOME/.local/scripts/apt_fast.sh upgrade'
