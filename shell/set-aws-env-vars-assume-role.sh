#!/bin/bash

unset SCRIPT_ENVIRON SCRIPT_ROLE_ARN SCRIPT_DURATION SCRIPT_ASSUME_SILENT
SCRIPT_DURATION=3600
SCRIPT_ASSUME_SILENT="FALSE"
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -e|--environment)
    SCRIPT_ENVIRON="$2"
    shift # past argument
    shift # past value
    ;;
    -ra|--role-arn)
    SCRIPT_ROLE_ARN="$2"
    shift # past argument
    shift # past value
    ;;
    --duration)
    SCRIPT_DURATION="$2"
    shift # past argument
    shift # past value
    ;;
    -ars|--assume-role-silently)
    SCRIPT_ASSUME_SILENT="TRUE"
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

if [[ -z $SCRIPT_ENVIRON ]] && [[ -z $SCRIPT_ROLE_ARN ]]; 
then 
  printf "You have to define one of either --role-arn, or --environment which will grep your %s/.aws/config profiles" "$HOME"
  return
fi
if [[ -n $SCRIPT_ENVIRON ]] && [[ -n $SCRIPT_ROLE_ARN ]];
then 
  printf "You have to define only one of either --role-arn, or --environment which will grep your %s/.aws/config profiles" "$HOME"
  return
fi

if [[ $SCRIPT_ASSUME_SILENT == "FALSE" ]];
then 
  echo "Clearing environment variables and assuming role"; 
fi

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN

if [[ -n $SCRIPT_ENVIRON ]];
then
  SCRIPT_ROLE_ARN=$(grep -i "profile $SCRIPT_ENVIRON" ~/.aws/config -A5 | grep role_arn | cut -d"=" -f2 | sed 's/[[:space:]]*//g')
fi

AWS_CREDS_JSON=$(aws sts assume-role --role-arn "$SCRIPT_ROLE_ARN" --role-session-name "$LOGNAME"-cli --duration-seconds "$SCRIPT_DURATION")

AWS_ACCESS_KEY_ID=$(echo "$AWS_CREDS_JSON" | jq --raw-output .Credentials.AccessKeyId)
AWS_SECRET_ACCESS_KEY=$(echo "$AWS_CREDS_JSON" | jq --raw-output .Credentials.SecretAccessKey)
AWS_SESSION_TOKEN=$(echo "$AWS_CREDS_JSON" | jq --raw-output .Credentials.SessionToken)
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

if [[ $SCRIPT_ASSUME_SILENT == "FALSE" ]]; 
then 
  aws sts get-caller-identity
fi

unset SCRIPT_ENVIRON SCRIPT_ASSUME_SILENT SCRIPT_ROLE_ARN SCRIPT_DURATION