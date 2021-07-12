#!/bin/bash
# shellcheck disable=SC2154

unset SCRIPT_GIT_SOURCE
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --git-repo)
    SCRIPT_GIT_SOURCE="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

gclone() {
    #do things with parameters like $1 such as
    project_name=$(echo "$1" | rev | cut -d"/" -f1 | rev | sed 's/.git$//g' | tr '[:upper:]' '[:lower:]')
    if [[ ! $repopath ]]; then echo "Configure a repopath variable please before running. K THX BYE!"; return; fi
    git clone "$1" "$repopath"/"$project_name"
}

if [[ ! $SCRIPT_GIT_SOURCE ]]; 
then 
    echo "Loaded gclone function.  Please provide a git remote address when running.  eg: gclone --git-repo git@github.com:Skeeg/scripts.git"
    return
fi

gclone "$SCRIPT_GIT_SOURCE"
