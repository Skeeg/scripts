#!/bin/bash

# #Store Password in OSX Keychain:
# read -s SECRET
# security add-generic-password -s lpass-login -w "$SECRET" -a "$LOGNAME"

# #Shell alias for simple logins.  SCRIPTS path and EMAIL_ADDRESS assumed to be set in shell init profiles.
# alias init-sessions='ssh-add -K ~/.ssh/id_rsa; source $SCRIPTS/shell/terraform_env_vars.sh --email-address $EMAIL_ADDRESS;'

unset SCRIPT_EMAIL_ADDRESS
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -e|--email-address)
    SCRIPT_EMAIL_ADDRESS="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

if [[ ! $SCRIPT_EMAIL_ADDRESS ]]; 
then 
    echo "Provide an email address when running via --email-address example@domain.com"
    return
fi

security find-generic-password -w -a "$LOGNAME" -s lpass-login | lpass login "$SCRIPT_EMAIL_ADDRESS"

OKTA_ENTRY="okta_account"
TF_VAR_okta_username=$(lpass show --username $OKTA_ENTRY)
TF_VAR_okta_password=$(lpass show --password $OKTA_ENTRY)

SIMPLE_AD_ENTRY="personal_simple_ad_account"
TF_VAR_simple_ad_username=$(lpass show --username $SIMPLE_AD_ENTRY)
TF_VAR_simple_ad_password=$(lpass show --password $SIMPLE_AD_ENTRY)

GITLAB_ENTRY="personal_gitlab_account"
TF_VAR_gitlab_username=$(lpass show --username $GITLAB_ENTRY)
TF_VAR_gitlab_password=$(lpass show --password $GITLAB_ENTRY)
TF_VAR_gitlab_personal_access_token=$(lpass show --note $GITLAB_ENTRY | jq --raw-output .PersonalAccessToken)

export TF_VAR_okta_username TF_VAR_okta_password TF_VAR_simple_ad_username TF_VAR_simple_ad_password TF_VAR_gitlab_username TF_VAR_gitlab_password TF_VAR_gitlab_personal_access_token

lpass logout --force
