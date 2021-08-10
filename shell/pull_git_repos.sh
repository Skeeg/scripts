#!/bin/bash
# shellcheck disable=SC2154

if [[ ! $repopath ]]; then echo "Configure a repopath variable please before running. K THX BYE!"; return; fi

for folder in "$repopath"/*/; 
do
  printf "Syncing %s : " "$folder"
  git -C "$folder" pull
done; 
