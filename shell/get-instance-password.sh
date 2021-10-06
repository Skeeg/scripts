#!/bin/bash
#Usage
# source $scripts/shell/get-instance-password.sh -sp $scripts/shell --instance-name "instance-name" -ra $ROLE_ARN_STAGING

unset SCRIPT_ASSUME_SILENT SCRIPT_INSTANCE_NAME ASSUME_ENVIRON SCRIPT_PATH SCRIPT_ROLE_ARN
SCRIPT_ASSUME_SILENT="FALSE"
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -sp|--script-path)
        SCRIPT_PATH="$2"
        shift # past argument
        shift # past value
        ;;
        -in|--instance-name)
        SCRIPT_INSTANCE_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        -ars|--assume-role-silently)
        SCRIPT_ASSUME_SILENT="TRUE"
        shift # past argument
        ;;
        -ra|--role-arn)
        SCRIPT_ROLE_ARN="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

if [[ -z $SCRIPT_PATH ]] && [[ -n $SCRIPT_ROLE_ARN ]]
then
  printf "--script-path required for assume role scripts."
  return 
fi

if [[ -z $SCRIPT_INSTANCE_NAME ]]
then
  printf "--instance-name required"
  return
fi

BANNER_STRING="########################################"

if [[ $SCRIPT_ASSUME_SILENT == "FALSE" ]];
then
  printf "\n%s\nAssuming Role for AWS Accounts\n%s\n" "$BANNER_STRING" "$BANNER_STRING";
fi

if [[ -n $SCRIPT_ROLE_ARN ]];
then
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
  if [[ $SCRIPT_ASSUME_SILENT == "FALSE" ]];
  then
    source "$SCRIPT_PATH"/set-aws-env-vars-assume-role.sh --role-arn "$SCRIPT_ROLE_ARN"
    SCRIPT_ASSUME_SILENT="FALSE"
  else
    source "$SCRIPT_PATH"/set-aws-env-vars-assume-role.sh --assume-role-silently --role-arn "$SCRIPT_ROLE_ARN"; 
  fi
fi

printf "\n%s\nInstance Information\n%s\n" "$BANNER_STRING" "$BANNER_STRING"

data=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$SCRIPT_INSTANCE_NAME" \
  "Name=instance-state-name,Values=running" | \
  jq --raw-output '.Reservations[].Instances[] | (.Tags[] ? | select(.Key=="Name")|.Value) as $Name | {Name: $Name, InstanceId: .InstanceId, PrivateIPAddress: .PrivateIpAddress, Launchtime: .LaunchTime, State: .State.Name, Key: .KeyName}')
#output data
echo "$data" | jq .
aws ec2 get-password-data --instance-id "$(echo "$data" | jq --raw-output .InstanceId)" \
  --priv-launch-key ~/.ssh/"$(echo "$data" | jq --raw-output .Key)".pem | \
  jq --raw-output .PasswordData;

if [[ $SCRIPT_ASSUME_SILENT == "FALSE" ]];
then
  printf "\n%s\nReleasing Role for AWS Accounts\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
fi

if [[ -n $SCRIPT_ROLE_ARN ]];
then
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
fi

unset SCRIPT_ASSUME_SILENT SCRIPT_INSTANCE_NAME ASSUME_ENVIRON SCRIPT_PATH
