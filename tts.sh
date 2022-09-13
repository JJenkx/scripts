#!/usr/bin/env zsh

# Coqui TTS bash script to generate TTS and playback long text in real time
# Works by splitting text file into segments and generating a playlist file containing entries for all split files.
# The opened playlist will continue playing as long as the encoding is faster than playback

# Dependencies
# TTS https://github.com/coqui-ai/TTS
# find |or| ripgrep
# bc cat echo espeak-ng ffmpeg ls mkdir mv perl printf rm sort split tail touch wc sudo



# Set values begin
##################
##################

# TTSFILE is the main text file. All text put here will be converted to speach
TTSFILE="$HOME/Documents/tts.txt"

# Split TTSFILE file at this number of text lines. TTS will be run for each split file
SplitTextAtLines=10

# WORKINGDIR is where text split files, proccessed wav files, temp files, and playlist files will be created
WORKINGDIR="$HOME/Documents/tts/"

# Use Ripgrep or Find? Set value "Ripgrep" or "Find"
RipgrepOrFind="Ripgrep"

# Set TTS model name to use. Run "tts --list_models" to find more

UseModel="tts_models/en/ljspeech/tacotron2-DDC_ph"


#UseModel="tts_models/en/blizzard2013/capacitron-t2-c150"
#UseModel="tts_models/en/blizzard2013/capacitron-t2-c50"
#UseModel="tts_models/en/ek1/tacotron2"                     # Froze for 20 minutes
#UseModel="tts_models/en/ljspeech/fast_pitch"
#UseModel="tts_models/en/ljspeech/glow-tts"                 # Don't like voice, Processed fine
#UseModel="tts_models/en/ljspeech/speedy-speech"
#UseModel="tts_models/en/ljspeech/tacotron2-DCA"
#UseModel="tts_models/en/ljspeech/tacotron2-DDC_ph"
#UseModel="tts_models/en/ljspeech/tacotron2-DDC"
#UseModel="tts_models/en/ljspeech/vits"
#UseModel="tts_models/en/sam/tacotron-DDC"
#UseModel="tts_models/en/vctk/fast_pitch"
#UseModel="tts_models/en/vctk/vits"

#UseModel="tts_models/de/thorsten/tacotron2-DCA"
#UseModel="tts_models/de/thorsten/tacotron2-DDC"
#UseModel="tts_models/de/thorsten/vits"
#UseModel="tts_models/es/mai/tacotron2-DDC"
#UseModel="tts_models/ewe/openbible/vits"
#UseModel="tts_models/fr/mai/tacotron2-DDC"
#UseModel="tts_models/hau/openbible/vits"
#UseModel="tts_models/it/mai_female/glow-tts"
#UseModel="tts_models/it/mai_female/vits"
#UseModel="tts_models/it/mai_male/glow-tts"
#UseModel="tts_models/it/mai_male/vits"
#UseModel="tts_models/ja/kokoro/tacotron2-DDC"
#UseModel="tts_models/lin/openbible/vits"
#UseModel="tts_models/multilingual/multi-dataset/your_tts"
#UseModel="tts_models/nl/mai/tacotron2-DDC"
#UseModel="tts_models/tr/common-voice/glow-tts"
#UseModel="tts_models/tw_akuapem/openbible/vits"
#UseModel="tts_models/tw_asante/openbible/vits"
#UseModel="tts_models/uk/mai/glow-tts"
#UseModel="tts_models/yor/openbible/vits"
#UseModel="tts_models/zh-CN/baker/tacotron2-DDC-GST"

vared -p 'Preformat text with perl? [Y/n]: ' -c FormatText
	  case "$FormatText" in
	      [yY][eE][sS]|[yY]|"") 
	          unset FormatText
	          FormatText="Yes"
	          ;;
	      *)
	          unset FormatText
	          FormatText="No"
	          ;;
	  esac


##################
##################
# Set values end





# Begin script
##################
##################



# Create dir and file if not exist
mkdir -p "$WORKINGDIR"
touch "$TTSFILE"



# Clean/Delete old files
rm -f "$WORKINGDIR"*temp.txt*
printf "" > "$WORKINGDIR"ffmpeg.combine.txt


if [[ "$FormatText" == "Yes" ]] ;
  then

  # Preformat "$TTSFILE" for better encoding results

  # Change char ' to char ’ when between letters a-z
  perl -C -Mutf8 -0777 -p -i -e 's/([a-z])('\'')([a-z])/$1’$3/igm' "$TTSFILE"

  # Remove all characters not matching 0-9!’a-z \?\n\.,- and replace with a space.
  perl -C -Mutf8 -0777 -p -i -e 's/[^0-9!’a-z \?\n\.,-]/ /igm' "$TTSFILE"

  # Insert newline after char "." and "?"
  perl -C -Mutf8 -0777 -p -i -e 's/(?:\.|\?)\K\n*/\n/igm' "$TTSFILE"

  # Remove leading and trailing spaces on each line
  perl -C -Mutf8 -0777 -p -i -e 's/^ *(.*) */$1/igm' "$TTSFILE"

fi



# Split TTSFILE based on number of lines set in var $SplitTextAtLines (--lines=<num>)
split --suffix-length=6 -d --additional-suffix=.temp.txt --lines="$SplitTextAtLines" "$TTSFILE" "$WORKINGDIR"


# Run rest of script utilizing either Ripgrep or Find
if [[ "$RipgrepOrFind" == "Find" ]] ;
  then

#################################
#################################
#### Section utilizing Find #####
#################################
#################################
    
    printf "\nUsing Find to cue files.\n"
    
    # Make working dir path into regex pattern for Find
    regexpath="$(echo "$WORKINGDIR" | perl -pe 's/\//\\\//gm')"
    
    # Find / Generate playlist ahead of file generation
    printf "#EXTM3U\n" >"$WORKINGDIR"temp.playlist.m3u; find "$WORKINGDIR" -name "*" -type f -regextype posix-egrep -iregex "^"$regexpath"[0-9]{6}\.temp\.txt$" -exec ls {} \; | sort -g | perl -C -Mutf8 -0777 -pe 's/^(.+\/)(.*)$/#EXTINF:0, - $2.wav\n$1$2.wav/igm' >>"$WORKINGDIR"temp.playlist.m3u
  
    # Get number of files represented in temp.playlist.m3u
    LinesInPlaylist="$(wc -l < "$WORKINGDIR"temp.playlist.m3u)"
    q=$(bc <<< "scale=2; ($LinesInPlaylist-1)/2")
    FilesInPlaylist=${q%%.00}

    printf "\nNumber of files in playlist is $FilesInPlaylist\n"

    # Run tts on first temp text files.
    tts --text "$(cat "$WORKINGDIR"000000.temp.txt)" --model_name "$UseModel" --out_path "$WORKINGDIR"000000.temp.txt.wav

    # Determine if there are more than one file and proccess each split file if needed
    if [[ "$FilesInPlaylist" -gt "1" ]] ;
      then

        # Open playlist file to begin playing the first encoded file as the others are being encoded
        nohup xdg-open "$WORKINGDIR"temp.playlist.m3u < /dev/null > /dev/null &

        # Run tts on all the other temp text files. Excluding the first file that is already processed
        find "$WORKINGDIR" -name "*" -type f -regextype posix-egrep -iregex "^"$regexpath"[0-9]{6}\.temp\.txt$" -exec ls {} \; | sort -g | tail --lines=+2 | while read line; do tts --text "$(cat "$line")" --model_name "$UseModel" --out_path "$line".wav; done

        # Make ffmpeg combine list needed by ffmpeg for merging all wav files into one
        find "$WORKINGDIR" -name "*" -type f -regextype posix-egrep -iregex "^"$regexpath"[0-9]{6}\.temp\.txt\.wav$" -exec ls {} \; | sort -g | perl -pe 's/^(.*)$/file '\''$1'\''/igm' > "$WORKINGDIR"ffmpeg.combine.txt

        # Combine all wav files from ffmpeg.combine.txt
        ffmpeg -f concat -safe 0 -i "$WORKINGDIR"ffmpeg.combine.txt -c copy -f segment -strftime 1 -segment_time 9999:00:00 "$WORKINGDIR"tts.combined-%Y-%m-%d_%H-%M-%S.wav
        printf "\nFFmpeg combined "$FilesInPlaylist" files into "$WORKINGDIR"tts.combined-$(date +%Y-%m-%d_%H-%M-%S).wav\n"

        printf "\n"

      else
        # Rename and open the one file that was encoded since there were no split files
        RenameFileTo="tts.combined-$(date +%Y-%m-%d_%H-%M-%S).wav"
        printf "\nFFmpeg combine not needed.\nRenaming file to $RenameFileTo\n"
        mv "$WORKINGDIR"000000.temp.txt.wav "$WORKINGDIR""$RenameFileTo"
        
        # Create and open playlist file with just the one encoded file
        printf "#EXTM3U\n#EXTINF:0, - "$RenameFileTo"\n"$WORKINGDIR""$RenameFileTo"" > "$WORKINGDIR"temp.playlist.m3u
        nohup xdg-open "$WORKINGDIR"temp.playlist.m3u < /dev/null > /dev/null && printf "\n"
    fi

  else
    if [[ "$RipgrepOrFind" == "Ripgrep" ]] ;
    then

#################################
#################################
### Section utilizing Ripgrep ###
#################################
#################################

      printf "\nUsing Ripgrep to cue files.\n"
      
      # Ripgrep / Generate playlist ahead of file generation
      printf "#EXTM3U\n" >"$WORKINGDIR"temp.playlist.m3u | rg "$WORKINGDIR" --files 2>/dev/null | rg "^"$WORKINGDIR"\d{6}\.temp\.txt$" | sort -g | perl -C -Mutf8 -0777 -pe 's/^(.+\/)(.*)$/#EXTINF:0, - $2.wav\n$1$2.wav/igm' >>"$WORKINGDIR"temp.playlist.m3u
  
      # Get number of files represented in temp.playlist.m3u
      LinesInPlaylist="$(wc -l < "$WORKINGDIR"temp.playlist.m3u)"
      q=$(bc <<< "scale=2; ($LinesInPlaylist-1)/2")
      FilesInPlaylist=${q%%.00}


      printf "\nNumber of files in playlist is $FilesInPlaylist\n"

      # Run tts on first temp text files.
      tts --text "$(cat "$WORKINGDIR"000000.temp.txt)" --model_name "$UseModel" --out_path "$WORKINGDIR"000000.temp.txt.wav


      # Determine if there are more than one file and proccess each split file if needed
      if [[ "$FilesInPlaylist" -gt "1" ]] ;
        then

          # Open playlist file to begin playing the first encoded file as the others are being encoded
          nohup xdg-open "$WORKINGDIR"temp.playlist.m3u < /dev/null > /dev/null &

          # Run tts on all the other temp text files. Excluding the first file that is already processed
          rg "$WORKINGDIR" --files 2>/dev/null | rg "^"$WORKINGDIR"\d{6}\.temp\.txt$" | sort -g | tail --lines=+2 | while read line; do tts --text "$(cat "$line")" --model_name "$UseModel" --out_path "$line".wav; done

          # Make ffmpeg combine list needed by ffmpeg for merging all wav files into one
          rg "$WORKINGDIR" --files 2>/dev/null | rg "^"$WORKINGDIR"\d{6}\.temp\.txt\.wav$" | sort -g | perl -pe 's/^(.*)$/file '\''$1'\''/igm' > "$WORKINGDIR"ffmpeg.combine.txt

          # Combine all wav files from ffmpeg.combine.txt
          ffmpeg -f concat -safe 0 -i "$WORKINGDIR"ffmpeg.combine.txt -c copy -f segment -strftime 1 -segment_time 9999:00:00 "$WORKINGDIR"tts.combined-%Y-%m-%d_%H-%M-%S.wav
          printf "\nFFmpeg combined "$FilesInPlaylist" files into "$WORKINGDIR"tts.combined-$(date +%Y-%m-%d_%H-%M-%S).wav\n"

          printf "\n"

        else
          # Rename and open the one file that was encoded since there were no split files
          RenameFileTo="tts.combined-$(date +%Y-%m-%d_%H-%M-%S).wav"
          printf "\nFFmpeg combine not needed.\nRenaming file to $RenameFileTo\n"
          mv "$WORKINGDIR"000000.temp.txt.wav "$WORKINGDIR""$RenameFileTo"

          # Create and open playlist file with just the one encoded file
          printf "#EXTM3U\n#EXTINF:0, - "$RenameFileTo"\n"$WORKINGDIR""$RenameFileTo"" > "$WORKINGDIR"temp.playlist.m3u
          nohup xdg-open "$WORKINGDIR"temp.playlist.m3u < /dev/null > /dev/null && printf "\n"
      fi

    else
      # Return error message if neither Ripgrep of Find are defined
      printf "\nError:\nThe variable \"RipgrepOrFind\" should be set as \"Ripgrep\" or \"Find\" in the script\n"
      exit 0
    fi
fi

unset FilesInPlaylist
unset FormatText
unset line
unset LinesInPlaylist
unset q
unset regexpath
unset RenameFileTo
unset RipgrepOrFind
unset SplitTextAtLines
unset TTSFILE
unset UseModel
unset WORKINGDIR
