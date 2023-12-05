#!/bin/usr/env bash
MEDIAPATH="/run/media/mmcblk0p1/Emulation/tools/downloaded_media"
ROMSPATH="/run/media/mmcblk0p1/Emulation/roms"
SYSTEMS=$(ls $MEDIAPATH)

for SYSTEM in $SYSTEMS; do 
  echo "$SYSTEM";
  EXISTINGROMSLIST="$MEDIAPATH/$SYSTEM/existingromslist.txt"
  find "$ROMSPATH/$SYSTEM/" -maxdepth 1 -mindepth 1 -name '*' | rev | cut -d"/" -f1 | rev | cut -d"." -f1 | sort > "$EXISTINGROMSLIST"
  while IFS= read -r FOLDER; do
    MEDIALIST="$FOLDER-mediafilelist.txt"
    find "$FOLDER/" -maxdepth 1 -mindepth 1 -name '*' | rev | cut -d"/" -f1 | rev | cut -d"." -f1 | sort > "$MEDIALIST"
    while IFS= read -r FILE; do
      # find "$FOLDER/" -name "$FILE*" -exec ls -l {} +
      find "$FOLDER/" -name "$FILE*" -exec rm -v {} +
    done < <(diff "$EXISTINGROMSLIST" "$MEDIALIST" | grep "^> " | cut -c 3-)
  done < <(find "$MEDIAPATH/$SYSTEM/" -maxdepth 1 -mindepth 1 -type d)
done
