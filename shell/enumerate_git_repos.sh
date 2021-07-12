#!/bin/bash
# shellcheck disable=SC2154

if [[ ! $repopath ]]; then echo "Configure a repopath variable please before running. K THX BYE!"; return; fi

for folder in "$repopath"/*/; 
do 
  (
  cd "$folder" || exit
  git remote -v | \
    grep fetch | \
    cut -f2 | \
    cut -d' ' -f1
  )
done; 
