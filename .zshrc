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




# Download youtube. aria2c compiled with limits removed https://github.com/JJenkx/aria2 . ffmpeg fixed builds https://github.com/yt-dlp/FFmpeg-Builds#ffmpeg-static-auto-builds https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz

alias yt='noglob yt-dlp --output '\''$HOME/Videos/yt-dlp/%(channel)s/%(upload_date>%Y-%m-%d)s_%(title)s/%(title)s_%(duration>%H-%M-%S)s_%(upload_date>%Y-%m-%d)s_%(resolution)s_Channel_(%(channel_id)s)_URL_(%(id)s).%(ext)s'\'' --ffmpeg-location /home/jjenkx/.local/bin.notpath/ --restrict-filenames --external-downloader aria2c --downloader-args "aria2c: -s 32 -x 32 -j 8 -c -k 8K --piece-length=128K --lowest-speed-limit=10K --retry-wait=2 --continue=true " --write-description --write-info-json --write-thumbnail --prefer-free-formats --remux-video mkv --embed-chapters --sponsorblock-remove "sponsor,selfpromo,interaction,intro,outro,preview " --download-archive $HOME/Videos/yt-dlp/.yt-dlp-archived-done.txt '




# Download youtube and play with mpv. aria2c compiled with limits removed https://github.com/JJenkx/aria2 . ffmpeg fixed builds https://github.com/yt-dlp/FFmpeg-Builds#ffmpeg-static-auto-builds https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz

alias yp='noglob yt-dlp --exec '\''nohup mpv '\''%(filepath)q'\'' &>/dev/null & '\'' --output '\''$HOME/Videos/yt-dlp/%(channel)s/%(upload_date>%Y-%m-%d)s_%(title)s/%(title)s_%(duration>%H-%M-%S)s_%(upload_date>%Y-%m-%d)s_%(resolution)s_Channel_(%(channel_id)s)_URL_(%(id)s).%(ext)s'\'' --ffmpeg-location /home/jjenkx/.local/bin.notpath/ --restrict-filenames --external-downloader aria2c --downloader-args "aria2c: -s 32 -x 32 -j 8 -c -k 8K --piece-length=28K --lowest-speed-limit=10K --retry-wait=2 --continue=true " --write-description --write-info-json --write-thumbnail --prefer-free-formats --remux-video mkv --embed-chapters --sponsorblock-remove "sponsor,selfpromo,interaction,intro,outro,preview " --download-archive $HOME/Videos/yt-dlp/.yt-dlp-archived-done.txt '




# Download file with aria2c compiled with limits removed. https://github.com/JJenkx/aria2 .

alias dl='noglob aria2c -s 32 -x 32 -j 8 -c -k 8K --piece-length=28K --lowest-speed-limit=10K --retry-wait=2 --continue=true '




# Graphic disk map of drive run as root

alias my.gdmap='noglob sudo sh -c '\''nohup gdmap --folder=/ &>/dev/null & '\'' ' 



