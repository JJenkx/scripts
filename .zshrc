# Use powerline
USE_POWERLINE="true"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi





# Install this script. Will backup your current file and replace it with this one

# cp ~/.zshrc ~/.zshrc$(date +%Y%m%d%H%M%S%N).bak ; wget -O- -q "https://github.com/JJenkx/Personal/raw/main/.zshrc" >~/.zshrc ; exec zsh

# Some of the dependencies
# sudo pacman -S --needed exa imagemagick libwebp mpv parallel pigz ripgrep rsync whois
# pip3 install aggregate6 yt-dlp 





# Set custom paths
PathList='
$HOME/.local/bin
$HOME/.local/scripts
'
AbsoluteHome="$(echo $HOME | perl -pe 's/(\/)/\\$1/g')"
RealPathHome="$(echo $PathList | sed "s/\$HOME/$AbsoluteHome/g" )"
append_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}
for line in $(echo $RealPathHome); do
  dir="$line";
  if [ -d "$dir" ]
  then
    append_path "$line"
  fi
done
export PATH=$(tr ':' '\n' <<< "$PATH" | LC_ALL=C sort -u | perl -0777 -pe 's/[^\A]\K\n+(?!\Z)/:/gm')
unset -f append_path





# Install Ruby Gems to ~/gems
export GEM_HOME=$HOME/gems
export PATH=$HOME/gems/bin:$PATH
export PATH=$HOME/.local/share/gem/ruby/3.0.0/bin:$PATH





# Get Facebook/Meta Ip addresses for blocking them
function updatefacebookip {
#!/usr/bin/env sh
if ! command -v whois 1>/dev/null 2>&1 ; then
  printf "\n\nNeed to install whois dependency.\n\n"
#  read -r -p "${1:-Are you sure? [Y/n]} " installwhois
vared -p 'Run "sudo pacman -S --needed whois" ? [Y/n]: ' -c installwhois
  case "$installwhois" in
      [yY][eE][sS]|[yY]|"") 
          unset installwhois
          sudo pacman -S --needed whois
          ;;
      *)
          unset installwhois
          false
          ;;
  esac
fi
if ! command -v aggregate6 1>/dev/null 2>&1 ; then
  printf "\n\nNeed to install aggregate6 dependency.\n\n" ; 
#  read -r -p "${1:-Are you sure? [Y/n]} " installaggregate
vared -p 'Run "pip3 install aggregate6" ? [Y/n]: ' -c installaggregate
  case "$installaggregate" in
      [yY][eE][sS]|[yY]|"") 
          unset installaggregate
          pip3 install aggregate6
          ;;
      *)
          unset installaggregate
          false
          ;;
  esac
fi
BLOCKFILEDIR="$HOME/.local/firewall/"
mkdir -p "$BLOCKFILEDIR"
whois -h whois.radb.net -- '-i origin AS32934' | grep -ioP '^route:.*\s\K\d.*' | aggregate6 >"$BLOCKFILEDIR"facebook.ipv4
printf "\n\ncat "$BLOCKFILEDIR"facebook.ipv4"":\n\n""$(cat "$BLOCKFILEDIR"facebook.ipv4)\n\n\n"
whois -h whois.radb.net -- '-i origin AS32934' | grep -ioP '^route6:.*\s\K\d.*' | aggregate6 >"$BLOCKFILEDIR"facebook.ipv6
printf "\n\ncat "$BLOCKFILEDIR"facebook.ipv6"":\n\n""$(cat "$BLOCKFILEDIR"facebook.ipv6)\n\n\n\n\n"
unset BLOCKFILEDIR
return 0
}





# Block Facebook/Meta IPs after running "updatefacebookip"
function blockfacebook {
BLOCKFILEDIR="$HOME/.local/firewall/"
mkdir -p "$BLOCKFILEDIR"

if [[ -e "$BLOCKFILEDIR"facebook.ipv4 ]]; then
    printf "\n\nBlocking IPV4 IPs in iptables chains:\n    FORWARD, OUTPUT, and INPUT.\n\n"
    cat "$BLOCKFILEDIR"facebook.ipv4 | 
    while IFS= read -r line ; do {
        sudo iptables -t filter -I FORWARD -s "$line" -j DROP
        sudo iptables -A OUTPUT -d "$line" -j DROP
        sudo iptables -A INPUT -d "$line" -j DROP
    }; done
    printf "\n\ncat "$BLOCKFILEDIR"facebook.ipv4"":\n\n""$(cat "$BLOCKFILEDIR"facebook.ipv4)\n\n\n"
    unset IFS
else
    printf "\n\n"$BLOCKFILEDIR"facebook.ipv4 not found.\nRun updatefacebookip to generate it\n\n\n"
fi

if [[ -e "$BLOCKFILEDIR"facebook.ipv6 ]]; then
    printf "Blocking IPV6 IPs in ip6tables chains:\n    FORWARD, OUTPUT, and INPUT.\n\n"
    cat $HOME/.local/firewall/facebook.ipv6 | 
    while IFS= read -r line ; do {
        sudo ip6tables -t filter -I FORWARD -s "$line" -j DROP
        sudo ip6tables -A OUTPUT -d "$line" -j DROP
        sudo ip6tables -A INPUT -d "$line" -j DROP
    }; done
    printf "\n\ncat "$BLOCKFILEDIR"facebook.ipv6"":\n\n""$(cat "$BLOCKFILEDIR"facebook.ipv6)\n\n\n"
    unset IFS
else
    printf "\n\n"$BLOCKFILEDIR"facebook.ipv6 not found.\nRun updatefacebookip to generate it\n\n\n"
fi
unset BLOCKFILEDIR
}





# MPV

# Return mpv watch history newest to oldest. Need line "write-filename-in-watch-later-config=yes" in mpv.conf
function .mpvhist {
WATCH_LATER_DIR='/home/jjenkx/.config/mpv/watch_later/'
HOW_MANY_TO_RETURN=1000
cat $(find "$WATCH_LATER_DIR" -type f -printf "%T@ %p\n" | sort | cut -c23- | tail -$HOW_MANY_TO_RETURN) | perl -0777 -pe 's/^[^#].*\n|# (.+\/)(.*)/'\''$1$2'\''\n$2/gm' | rg --colors 'match:none' --colors 'match:fg:0,200,0' --colors 'match:bg:0,0,0' --colors 'match:style:bold' -B1 -P "^[^'\/].*" 
unset WATCH_LATER_DIR
}

# Open MPV without binding to terminal
function .mpv {
setsid >/dev/null 2>&1 </dev/null mpv "$@" 2>&1 >/dev/null & 
}

# Open the newest file recorded in $WATCH_LATER_DIR. Need line "write-filename-in-watch-later-config=yes" in mpv.conf
function .mpvlast {
WATCH_LATER_DIR='/home/jjenkx/.config/mpv/watch_later/'
.mpv "$(cat $(echo /home/jjenkx/.config/mpv/watch_later/$(exa --reverse -s modified /home/jjenkx/.config/mpv/watch_later/ | head -1)) | head -1 | cut -c3-)"
unset WATCH_LATER_DIR
}
#alias .mpvlast='nohup mpv "$(cat $(echo /home/jjenkx/.config/mpv/watch_later/$(exa --reverse -s modified /home/jjenkx/.config/mpv/watch_later/ | head -1)) | head -1 | cut -c3-)"  &>/dev/null & '





# Tracking shipments
# Turn UPS tracking number into url
ups () { 
printf "https://ups.com/track?tracknum=$@\n"
}

# Turn USPS tracking number into url
usps () {
printf "https://tools.usps.com/go/TrackConfirmAction_input?strOrigTrackNum=$@\n"
}





# Testing
alias sortfast='sort -S$(($(sed '\''/MemF/!d;s/[^0-9]*//g'\'' /proc/meminfo)/2048)) $([ `nproc` -gt 1 ]&&echo -n --parallel=`nproc`)'





# aria2c compiled with limits removed https://github.com/JJenkx/aria2 . ffmpeg fixed builds https://github.com/yt-dlp/FFmpeg-Builds#ffmpeg-static-auto-builds https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz

# Download youtube
alias yt='noglob yt-dlp --output '\''$HOME/Videos/yt-dlp/%(channel)s/%(upload_date>%Y-%m-%d)s_%(title)s/%(title)s_%(duration>%H-%M-%S)s_%(upload_date>%Y-%m-%d)s_%(resolution)s_Channel_(%(channel_id)s)_URL_(%(id)s).%(ext)s'\'' --ffmpeg-location /home/jjenkx/.local/bin.notpath/ --restrict-filenames --external-downloader aria2c --downloader-args "aria2c: -s 32 -x 32 -j 8 -c -k 8K --piece-length=128K --lowest-speed-limit=10K --retry-wait=2 --continue=true " --write-description --write-info-json --write-thumbnail --prefer-free-formats --remux-video mkv --embed-chapters --sponsorblock-remove "sponsor,selfpromo,interaction,intro,outro,preview " --download-archive $HOME/Videos/yt-dlp/.yt-dlp-archived-done.txt '

# Download youtube and open in mpv
alias yp='noglob yt-dlp --exec '\''nohup mpv '\''%(filepath)q'\'' &>/dev/null & '\'' --output '\''$HOME/Videos/yt-dlp/%(channel)s/%(upload_date>%Y-%m-%d)s_%(title)s/%(title)s_%(duration>%H-%M-%S)s_%(upload_date>%Y-%m-%d)s_%(resolution)s_Channel_(%(channel_id)s)_URL_(%(id)s).%(ext)s'\'' --ffmpeg-location /home/jjenkx/.local/bin.notpath/ --restrict-filenames --external-downloader aria2c --downloader-args "aria2c: -s 32 -x 32 -j 8 -c -k 8K --piece-length=28K --lowest-speed-limit=10K --retry-wait=2 --continue=true  --download-result=full " --write-description --write-info-json --write-thumbnail --prefer-free-formats --remux-video mkv --embed-chapters --sponsorblock-remove "sponsor,selfpromo,interaction,intro,outro,preview " --download-archive $HOME/Videos/yt-dlp/.yt-dlp-archived-done.txt '





# Package Management

#!/bin/bash
# function update packages
function upall {
printf '\n\n\n\nRunning:\n         sudo pacman -Syu\n\n'
sudo pacman -Syu
printf '\n\n\n\nRunning:\n         yay -Syu\n\n\n\n'
yay -Syu
printf '\n\n\n\nRunning:\n         rustup update stable\n\n\n\n'
rustup update stable
printf '\n\n\n\nRunning:\n         cargo install cargo-update\n\n\n\n'
cargo install cargo-update
printf '\n\n\n\nRunning:\n         cargo install-update -a\n\n\n\n'
cargo install-update -a
printf '\n\n\n\nRunning:\n         /usr/bin/python3 -m pip install --upgrade pip\n\n\n\n'
/usr/bin/python3 -m pip install --upgrade pip
printf '\n\n\n\nRunning:\n         pip3 list --outdated --format=freeze | grep -v "\^\\-e" | cut -d = -f 1 | xargs -n1 pip3 install -U\n\n\n\n'
pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U
}

alias paci='sudo pacman -S --needed'
alias pacsyu='sudo pacman -Syu'                  # update only standard pkgs
alias pacsyyu='sudo pacman -Syyu'                # Refresh pkglist & update standard pkgs
alias parsua='paru -Sua'                         # update only AUR pkgs (paru)
alias parsyu='paru -Syu'                         # update standard pkgs and AUR pkgs (paru)
alias yaysua='yay -Sua'                          # update only AUR pkgs (yay)
alias yaysyu='yay -Syu'                          # update standard pkgs and AUR pkgs (yay)
#alias unlock='sudo rm /var/lib/pacman/db.lck'    # remove pacman lock
#alias cleanup='sudo pacman -Rns $(pacman -Qtdq)' # remove orphaned packages





# misc
alias editbashrc='sudo nano /etc/bash.bashrc'
alias editzsh='nano ~/.zshrc'
alias hist='cat ~/.zhistory'
alias listening='watch -n 0.3 ss -plunt'
alias logoff='qdbus org.kde.ksmserver /KSMServer logout 0 0 0'
alias logout='qdbus org.kde.ksmserver /KSMServer logout 0 0 0'
alias makename='shuf -n250 /home/jjenkx/.local/urban.sorted.txt | tr "\012" "_" | head -c -1 | perl -pe '\''s/([^_]+_){4}[^_]+\K_/\n/gm'\'' | sed y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/ ; printf "\n"'
alias myfunctions='declare -f $(cat ~/.zshrc | rg -Po "^function \K[^ ]+" ) '
alias mygdmap='noglob sudo sh -c '\''nohup gdmap --folder=/ &>/dev/null & '\'' ' 
alias mylsblk='lsblk -o MOUNTPOINT,SIZE,FSAVAIL,PATH,UUID,FSTYPE'
alias pigz='pigz --keep'
alias rpulse='systemctl --user restart pulseaudio.service'
alias salias='alias | perl -pe "s/\n/\n\n\n\n/gm" | rg -iP -A 2 -B 2'
alias unpigz='unpigz --keep'
alias unrarall='unrar x "*.rar" ./extracted/'
alias vpn='nohup sudo sh -c "killall openvpn >/dev/null 2>&1 &" ; sleep 3 ; nohup sudo sh -c "openvpn /path.to/my.ovpn >/dev/null 2>&1 &"'
alias vps='ssh -i /path.to/keyfile username@domain.xy -p <portnum>'
alias wea='curl wttr.in'





# Download file with aria2c compiled with limits removed. https://github.com/JJenkx/aria2 .
alias dl='noglob aria2c -s 8 -x 8 -j 8 -c -k 28K --piece-length=256K --lowest-speed-limit=10K --retry-wait=2 --continue=true '
alias dl1='noglob aria2c -s 1 -x 1 -j 8 -c -k 28K --piece-length=256K --lowest-speed-limit=10K --retry-wait=2 --continue=true '
alias dl2='noglob aria2c -s 2 -x 2 -j 8 -c -k 28K --piece-length=256K --lowest-speed-limit=10K --retry-wait=2 --continue=true '
alias dl4='noglob aria2c -s 4 -x 4 -j 8 -c -k 28K --piece-length=256K --lowest-speed-limit=10K --retry-wait=2 --continue=true '
alias dl8='noglob aria2c -s 8 -x 8 -j 8 -c -k 28K --piece-length=256K --lowest-speed-limit=10K --retry-wait=2 --continue=true '
alias dl16='noglob aria2c -s 16 -x 16 -j 8 -c -k 28K --piece-length=256K --lowest-speed-limit=10K --retry-wait=2 --continue=true '
alias dl32='noglob aria2c -s 32 -x 32 -j 8 -c -k 28K --piece-length=256K --lowest-speed-limit=10K --retry-wait=2 --continue=true '





# exa
alias la='exa -lhaFHumh --group-directories-first --octal-permissions --icons -s accessed'
alias lc='exa -lhaFHumh --group-directories-first --octal-permissions --icons -s created'
alias le='exa -lhaFHumh --group-directories-first --octal-permissions --icons -s extension'
alias ll='exa -lhaFHumh --group-directories-first --octal-permissions --icons'
alias lm='exa -lhaFHumh --group-directories-first --octal-permissions --icons -s modified'
alias ls='exa -lhaFHumh --group-directories-first --octal-permissions --icons -s size'
alias lt='exa -lhaFHumh --group-directories-first --octal-permissions --icons -s type'

alias watchdir.5='watch --color -n "0.5" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons'
alias watchdir.5accessed='watch --color -n "0.5" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s accessed'
alias watchdir.5created='watch --color -n "0.5" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s created'
alias watchdir.5extension='watch --color -n "0.5" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s extension'
alias watchdir.5inode='watch --color -n "0.5" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s inode'
alias watchdir.5modified='watch --color -n "0.5" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s modified'
alias watchdir.5size='watch --color -n "0.5" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s size'
alias watchdir.5type='watch --color -n "0.5" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s type'

alias watchdir1='watch --color -n "1.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons'
alias watchdir1accessed='watch --color -n "1.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s accessed'
alias watchdir1created='watch --color -n "1.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s created'
alias watchdir1extension='watch --color -n "1.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s extension'
alias watchdir1inode='watch --color -n "1.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s inode'
alias watchdir1modified='watch --color -n "1.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s modified'
alias watchdir1size='watch --color -n "1.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s size'
alias watchdir1type='watch --color -n "1.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s type'

alias watchdir2='watch --color -n "2.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons'
alias watchdir2accessed='watch --color -n "2.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s accessed'
alias watchdir2created='watch --color -n "2.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s created'
alias watchdir2extension='watch --color -n "2.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s extension'
alias watchdir2inode='watch --color -n "2.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s inode'
alias watchdir2modified='watch --color -n "2.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s modified'
alias watchdir2size='watch --color -n "2.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s size'
alias watchdir2type='watch --color -n "2.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s type'

alias watchdir5='watch --color -n "5.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons'
alias watchdir5accessed='watch --color -n "5.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s accessed'
alias watchdir5created='watch --color -n "5.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s created'
alias watchdir5extension='watch --color -n "5.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s extension'
alias watchdir5inode='watch --color -n "5.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s inode'
alias watchdir5modified='watch --color -n "5.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s modified'
alias watchdir5size='watch --color -n "5.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s size'
alias watchdir5type='watch --color -n "5.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s type'

alias watchdir10='watch --color -n "10.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons'
alias watchdir10accessed='watch --color -n "10.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s accessed'
alias watchdir10created='watch --color -n "10.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s created'
alias watchdir10extension='watch --color -n "10.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s extension'
alias watchdir10inode='watch --color -n "10.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s inode'
alias watchdir10modified='watch --color -n "10.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s modified'
alias watchdir10size='watch --color -n "10.0" exa -lhaFHumh -r --color=always --octal-permissions --group-directories-first --icons -s size'
alias watchdir10type='watch --color -n "10.0" exa -lhaFHumh --color=always --octal-permissions --group-directories-first --icons -s type'





# Ripgrep find files
function rgf {
rg "$PWD" --files --hidden 2>/dev/null | rg -iP "$@"
}





# Ripgrep find files, return files within single quotes
function rgff {
rg "$PWD" --files --hidden 2>/dev/null | perl -pe 's/(?='\'')/'\''\\'\''/g' | perl -pe 's/(?=^|\n)/'\''/g' | rg -iP "$@"
}





# rsync source dest
alias cpdir='sudo rsync --devices --executability --group --human-readable --links --owner --perms --progress --recursive --specials --stats --times --update --verbose'
alias cpdirdry='sudo rsync --devices --dry-run --executability --group --human-readable --links --owner --perms --progress --recursive --specials --stats --times --update --verbose'
    #  --dry-run       ,  -n,     perform a trial run with no changes made
    #  --executability ,  -E,     preserve executability
    #  --human-readable,  -h,     output numbers in a human-readable format
    #  --update        ,  -u,     skip files that are newer on the receiver
    #  --verbose       ,  -v,     increase verbosity
    #  --recursive     ,  -r,     recurse into directories
    #  --links         ,  -l,     copy symlinks as symlinks
    #  --perms         ,  -p,     preserve permissions
    #  --times         ,  -t,     preserve modification times
    #  --group         ,  -g,     preserve group
    #  --owner         ,  -o,     preserve owner (super-user only)
    #  --specials                 preserve special files
    #  --devices                  preserve device files (super-user only)
    #  --progress                 show progress during transfer
    #  --stats                    give some file-transfer stats

alias cpf='sudo rsync --executability --group --human-readable --owner --perms --progress --stats --times --verbose'
    #  --executability ;  -E,         preserve executability
    #  --group         ;  -g,         preserve group
    #  --human-readable;  -h,         output numbers in a human-readable format
    #  --owner         ;  -o,         preserve owner (super-user only)
    #  --perms         ;  -p,         preserve permissions
    #  --progress      ;              show progress during transfer
    #  --stats         ;              give some file-transfer stats
    #  --times         ;  -t,         preserve modification times
    #  --verbose       ;  -v          increase verbosity





# Password/Alias Generation
alias pw='len=40; tr -dc A-Za-z0-9\!\?\*\^\_ < /dev/urandom | head -c ${len} | xargs'
alias pwgen='pwgen -sy 40 20'
alias pwmake='printf '\''\nAdd or remove any characters after '\''\'\'''\''tr -dc'\''\'\'''\''\nto make a random custom password.\nSet password length with len=\n\nprintf '\''\'\'''\''\\n\\n'\''\'\'''\'' ; len=40; tr -dc A-Za-z0-9\!\?\*\^\_ < /dev/urandom | head -c ${len} | xargs ; printf '\''\'\'''\''\\n\\n'\''\'\'''\''\n\n'\'''
alias wordpass="shuf -n200 ~/.local/db/urban.txt | tr '\012' '_' | head -c -1 | perl -pe 's/([^_]+_){3}[^_]+\K_/\n/gm' && echo"





# convert webp to jpg if static or gif/mp4 if animated
#!/bin/bash
# Deps Arch: sudo pacman -S imagemagick libwebp parallel
function webpconvert {
######### Set hard path. No links like "$HOME" Etc.
#                      '/#########################/'
export MY_DWEBP_OUTDIR='/home/jjenkx/Pictures/WebpToPNG/'
######### Set jpg quality
#                      0-100 percent
export     QUALITY_ONE=35
export     QUALITY_TWO=75
mkdir -p "$MY_DWEBP_OUTDIR"
find "$PWD" -maxdepth 1 -name "*" -type f -regextype posix-extended -iregex '.*\.(webp)$' -print0 | parallel -0 -j+0 --eta --bar '
JPG_OUT_QUALITY_ONE=$(echo "$MY_DWEBP_OUTDIR"{/.}_"$QUALITY_ONE"_percent.jpg)
JPG_OUT_QUALITY_TWO=$(echo "$MY_DWEBP_OUTDIR"{/.}_"$QUALITY_TWO"_percent.jpg)
PNG_OUT=$(echo "$MY_DWEBP_OUTDIR"{/.}.ffmpeg.png)
GIF_OUT=$(echo "$MY_DWEBP_OUTDIR"{/.}.gif)
MP4_OUT=$(echo "$MY_DWEBP_OUTDIR"{/.}.mp4)
ISANIMATED="$(webpmux -info {} | rg animation)"
if [[ "$ISANIMATED" == "Features present: animation transparency" ]] ;
  then
    convert '{}' "$GIF_OUT"
    # Begin mp4 conversion handler to pad geometry 1 pixel to x and y if either are odd to avoid "libx264 not divisible by 2 error"
    GEOMETRY_X=$(webpmux -info '{}' | head -n 1 | tr "[:space:]" "\n" | tail -3 | head -n 1)
    GEOMETRY_Y=$(webpmux -info '{}' | head -n 1 | tr "[:space:]" "\n" | tail -3 | tail -1)
    JUST_X=$GEOMETRY_X
    JUST_Y=$GEOMETRY_Y
    if [ $(( $JUST_X  % 2)) -ne 0 ] | [ $(( $JUST_Y  % 2)) -ne 0 ] ;
    then
      if [ $(( $JUST_X  % 2)) -ne 0 ] && [ $(( $JUST_Y  % 2)) -ne 0 ] ;
      then
        SPLICE_GEOMETRY="1x1"
        GRAVITY_DIRECTION="northeast"
        convert -splice $SPLICE_GEOMETRY -gravity $GRAVITY_DIRECTION '{}' "$MP4_OUT"
      else 
        if [ $(( $JUST_X  % 2)) -ne 0 ]
        then
          SPLICE_GEOMETRY="1x0"
          GRAVITY_DIRECTION="east"
          convert -splice $SPLICE_GEOMETRY -gravity $GRAVITY_DIRECTION '{}' "$MP4_OUT"
        else
          if [ $(( $JUST_Y  % 2)) -ne 0 ]
          SPLICE_GEOMETRY="0x1"
          GRAVITY_DIRECTION="north"
          convert -splice $SPLICE_GEOMETRY -gravity $GRAVITY_DIRECTION '{}' "$MP4_OUT"
        fi
      fi
    else
      convert '{}' "$MP4_OUT"
    fi
    # End mp4 conversion handler to pad geometry 1 pixel to x and y if either are odd to avoid "libx264 not divisible by 2 error"
  else
    dwebp '{}' -o - | convert - -quality $QUALITY_ONE% "$JPG_OUT_QUALITY_ONE"    # pipe to convert for filesize reduction
    dwebp '{}' -o - | convert - -quality $QUALITY_TWO% "$JPG_OUT_QUALITY_TWO"    # pipe to convert for filesize reduction
fi
'
# Notes: Undesireable attempts
#   ffmpeg -y -i '{}' -q:v 1 "$PNG_OUT"                                          # PNG files are too big with ffmpeg
#   dwebp -v '{}' -o "$PNG_OUT"                                                  # PNG files are too big with dwebp
#   dwebp -v '{}' -o "$MY_DWEBP_OUTDIR""{/.}.jpg"                                # jpg files same size as png if not run through "convert"
#   dwebp '{}' -o - | convert - -quality 15% "$MY_DWEBP_OUTDIR"{/.}.png          # dwebp png pipe to convert, barely smaller file
unset MY_DWEBP_OUTDIR
unset QUALITY_ONE
unset QUALITY_TWO
}





# extract common file formats
#!/bin/bash
SAVEIFS=$IFS
IFS="$(printf '\n\t')"
function extract {
 if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
 else
    for n in "$@"
    do
      if [ -f "$n" ] ; then
          case "${n%,}" in
            *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                         tar xvf "$n"       ;;
            *.lzma)      unlzma ./"$n"      ;;
#            *.bz2)       bunzip2 ./"$n"     ;;
            *.bz2|*.gz|*.zip|*.xz)
                         unpigz -k ./"$n"     ;;
            *.cbr|*.rar) unrar x -ad ./"$n" ;;
#            *.gz)        gunzip ./"$n"      ;;
#            *.cbz|*.epub|*.zip) unzip ./"$n"       ;;
            *.cbz|*.epub) unzip ./"$n"       ;;
            *.z)         uncompress ./"$n"  ;;
            *.7z|*.apk|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
                         7z x ./"$n"        ;;
#            *.xz)        unxz ./"$n"        ;;
            *.exe)       cabextract ./"$n"  ;;
            *.cpio)      cpio -id < ./"$n"  ;;
            *.cba|*.ace) unace x ./"$n"      ;;
            *.zpaq)      zpaq x ./"$n"      ;;
            *.arc)       arc e ./"$n"       ;;
            *.cso)       ciso 0 ./"$n" ./"$n.iso" && \
                              extract $n.iso ;;
            *)
                         echo "extract: '$n' - unknown archive method"
                         return 1
                         ;;
          esac
      else
          echo "'$n' - file does not exist"
          return 1
      fi
    done
fi
}
IFS=$SAVEIFS





# Extract multipart rar files.
#!/bin/bash
# Name - extractall.sh
# Purpose - Extract multiple zip and rar files to ./ectracted folder
# ------------------------------------
## user define function
function extractall {
find ./ -maxdepth 1 -iregex '.*[.]\(zip\|r\(ar\|[0-9][0-9][0-9]?\)\)$' | read
if [[ $? -eq 0 ]] && [[ ! -d ./extracted ]] && [[ ! -L ./extracted ]] ; 
then
  unrar x "*.rar" ./extracted/ 2>/dev/null
  for z in *.zip; do unzip -d ./extracted/ -DD -o "$z" 2>/dev/null ; done
  cp *.nfo *.diz ./extracted 2>/dev/null
  cd ./extracted/
  unrar x "*.rar" ./extracted/ 2>/dev/null
  for z in *.zip; do unzip -d ./extracted/ -DD -o "$z" 2>/dev/null ; done
  cp *.nfo *.diz ./extracted 2>/dev/null
  cd ..
else
  echo "If conditions failed"
fi
}





#alias makename='for ITEM in $(len=300; tr -dc A-Za-z013 < /dev/urandom | head -c ${len} | xargs | perl -nle'\''print for /.{9}/g'\'' | perl -0777 -p -e '\''s/(?<=^.)/aeiou/egm'\'' | perl -0777 -p -e '\''s/(?=.)/ /g'\'' | perl -MList::Util=shuffle -alne '\''print shuffle @F'\''); do { echo "$ITEM" ; shuf -n1 /usr/share/dict/words | tr '\''\012'\'' '\''_'\'' | tr -d '\''\'\'''\'''\''\'\'' | sed y/åäâáçêéèíñôóöüûABCDEFGHIJKLMNOPQRSTUVWXYZbxesohy/aaaaceeeinooouuabcd3fgh1jklmnopqrstuvwxyzBX3S04Y/ ; } done && echo'
