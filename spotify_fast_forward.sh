#!/usr/bin/env bash
#set -x

# Get the current song metadata from Spotify. Remove newlines and multiple spaces with one space
metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
    /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get \
    string:"org.mpris.MediaPlayer2.Player" string:"Metadata" \
    | tr '\n' ' ' | sed 's/  */ /g')

# Extract song length in microseconds by retreiving the numerical value after "mpris:length" variant uint64 "
song_length_microseconds=$(echo "$metadata" | grep -oP '(?<=mpris:length" variant uint64 )\d+')

# Check if the song length was retrieved successfully
if [[ -z "$song_length_microseconds" ]]; then
    echo "Failed to retrieve song length."
    exit 1
fi

# Calculate 10% of the song length
seek_offset_microseconds=$((song_length_microseconds / 10))

# Use dbus-send to send a Seek command to Spotify
dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify \
    /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Seek int64:"$seek_offset_microseconds"
