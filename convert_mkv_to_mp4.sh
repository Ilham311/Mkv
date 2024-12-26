#!/bin/sh

# Initial code by thewinchester
# Modified by CanuckSkier
# Modified by xav0989
# SEE http://superuser.com/questions/275193/mkv-to-mp4-transcoding-script-issues/36649

# Close stdin - avoid accidental keypresses causing problems
exec 0>&-

# Find MKV files
for file in "$@";
do
  find "$file" -type f -not -name ".*" | grep .mkv$ | while read file
  do
    fileProper=$(readlink -f "$file") # full path of file
    pathNoExt=${fileProper%.*} # full path minus extension

    # Check if MP4 already exists
    if [ -f "$pathNoExt".mp4 ]; then
      echo "MP4 already exists, stopping"
    else
      # Get number of tracks
      numberOfTracks=`mkvmerge -i "$fileProper" | grep "Track ID" | wc -l`
      echo "Found $numberOfTracks Tracks"

      # Set base extraction command
      extractCmd=(mkvextract tracks "$fileProper")

      # Determine type of tracks
      for (( i=1; i<=$numberOfTracks; i++ ))
      do
         trackType=`mkvmerge -i "$fileProper" | grep "Track ID $i" | sed -e 's/^.*: //'`
         if [[ "$trackType" == *video* ]]; then
            echo "Track $i is Video"
            extractCmd+=( $i:"$pathNoExt".264)
            fps=`mkvinfo "$fileProper" | grep duration | sed -e 's/.*(//' -e 's/f.*//' | sed -n ${i}p`
         elif [[ "$trackType" == "audio (A_AAC)" ]]; then
            echo "Track $i is AAC"
            extractCmd+=( $i:"$pathNoExt".aac)
         elif [[ "$trackType" == "audio (A_AC3)" ]]; then
            echo "Track $i is AC3"
            extractCmd+=( $i:"$pathNoExt".ac3)
         elif [[ "$trackType" == "audio (A_DTS)" ]]; then
            echo "Track $i is DTS"
            extractCmd+=( $i:"$pathNoExt".dts)
         fi
         # Insert cases for handling other audio and non-AV tracks here
       done

        "${extractCmd[@]}" # Extract Tracks

        # Check files and encode audio if necessary
        if [ -f "$pathNoExt".264 ]; then
            # Video file exists
            mp4BoxCmd=(MP4Box -new "$pathNoExt".mp4 -add "$pathNoExt".264 -fps $fps)
            if [ -f "$pathNoExt".aac ]; then
                # AAC exists
                mp4BoxCmd+=( -add "$pathNoExt".aac)
                if [ -f "$pathNoExt".ac3 ]; then
                    mp4BoxCmd+=( -add "$pathNoExt".ac3:disable)
                elif [ -f "$pathNoExt".dts ]; then
                    # Encode DTS to AC3
                    dcadec -o wavall "$pathNoExt".dts | aften -v 0 - "$pathNoExt".ac3
                    mp4BoxCmd+=( -add "$pathNoExt".ac3:disable)
                fi
            else # Encode AAC from AC3 or DTS
                if [ -f "$pathNoExt".ac3 ]; then
                    ffmpeg -i "$pathNoExt".ac3 -acodec pcm_s16le -ac 2 -f wav - | neroAacEnc -lc -br 192000 -ignorelength -if - -of "$pathNoExt".aac
                    mp4BoxCmd+=( -add "$pathNoExt".aac -add "$pathNoExt".ac3:disable)
                elif [ -f "$pathNoExt".dts ]; then
                    ffmpeg -i "$pathNoExt".dts -acodec pcm_s16le -ac 2 -f wav - | neroAacEnc -lc -br 192000 -ignorelength -if - -of "$pathNoExt".aac
                    # Encode DTS to AC3
                    dcadec -o wavall "$pathNoExt".dts | aften -v 0 - "$pathNoExt".ac3
                    mp4BoxCmd+=( -add "$pathNoExt".aac -add "$pathNoExt".ac3:disable)
                else
                    echo "Warning: no audio file found"
                fi
            fi
            # Create mp4
            "${mp4BoxCmd[@]}"
        else
            echo "Error: no video file found"
        fi
  # Remove temporary track files
  rm -f "$pathNoExt".aac "$pathNoExt".dts "$pathNoExt".ac3 "$pathNoExt".264
  fi
 done
done
