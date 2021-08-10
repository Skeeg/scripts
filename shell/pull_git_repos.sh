#!/bin/bash
# shellcheck disable=SC2154

unset SCRIPT_REPO_PATH
#load environment repopath var to SCRIPT_REPO_PATH if present, overwritten by specifiying --repo-path option.
if [[ $repopath ]]; then SCRIPT_REPO_PATH="$repopath"; fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --repo-path)
    SCRIPT_REPO_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

if [[ ! $SCRIPT_REPO_PATH ]]; then echo "Configure a repopath variable please before running. K THX BYE!"; return; fi

for folder in "$SCRIPT_REPO_PATH"/*/; 
do
  printf "Syncing %s : " "$folder"
  git -C "$folder" pull
done; 
