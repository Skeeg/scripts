#!/bin/bash
# shellcheck disable=SC2154

git-default-branch() {
  git remote show $(git remote) | grep "HEAD branch" | sed 's/.*: //'
}

git-switch-default() {
  git switch $(git-default-branch)
}

unset SCRIPT_REPO_PATH SCRIPT_AUTO_SWITCH
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
    --auto-switch-on-missing)
    SCRIPT_AUTO_SWITCH="TRUE"
    shift # past argument
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
  SCRIPT_FAIL_PULL=$?
  [[ $SCRIPT_AUTO_SWITCH == "TRUE" ]] && { 
    [[ $SCRIPT_FAIL_PULL == 1 ]] && {
      [[ $(git pull 2> >(grep -c -e 'no such ref was fetched')) == 1 ]] && {
        git-switch-default
        git pull
      }
    }
  }
done; 

unset SCRIPT_REPO_PATH SCRIPT_AUTO_SWITCH SCRIPT_FAIL_PULL
