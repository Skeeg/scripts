#!/bin/bash
# shellcheck disable=SC2154

if [[ ! $repopath ]]; then echo "Configure a repopath variable please before running. K THX BYE!"; return; fi

for folder in "$repopath"/*/; 
do 
  (
  cd "$folder" || exit
  printf "syncing %s" "$folder"
  git pull
  )
done; 
