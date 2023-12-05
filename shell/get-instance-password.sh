#!/bin/bash
#Usage
# source $scripts/shell/get-instance-password.sh -sp $scripts/shell --instance-name "instance-name" -ra $ROLE_ARN_STAGING
get-instance-password() {
SCRIPT_INSTANCE_NAME="$1"
BANNER_STRING="########################################"

printf "\n%s\nInstance Information\n%s\n" "$BANNER_STRING" "$BANNER_STRING"

data=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$SCRIPT_INSTANCE_NAME" \
  "Name=instance-state-name,Values=running" | \
  jq --raw-output '.Reservations[].Instances[] | (.Tags[] ? | select(.Key=="Name")|.Value) as $Name | {Name: $Name, InstanceId: .InstanceId, PrivateIPAddress: .PrivateIpAddress, Launchtime: .LaunchTime, State: .State.Name, Key: .KeyName}')
#output data
echo "$data" | jq .
aws ec2 get-password-data --instance-id "$(echo "$data" | jq --raw-output .InstanceId)" \
  --priv-launch-key "$HOME/.ssh/$(echo "$data" | jq --raw-output .Key)".pem | \
  jq --raw-output .PasswordData;
}
