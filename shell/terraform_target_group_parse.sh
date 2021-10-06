#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --exec-mode)
        EXEC_MODE="true"
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

tfoutputdata=$(terraform output -json)
for tgname in $(echo "$tfoutputdata" | jq --raw-output '.tg_attachments.value | keys[]')
do
  echo \#$tgname
  tgdata=$(echo "$tfoutputdata" | jq --raw-output ".tg_attachments.value.$tgname")
  tgarn=$(echo "$tgdata" | jq --raw-output '.target_group')
  for tginstance in $(echo "$tgdata" | jq --raw-output '.target_id[]')
  do
    # echo $tginstance
    instancename=$(echo "$tfoutputdata" | jq --raw-output ".ec2_id_mapping.value.instances.\"$tginstance\"")
    if [[ $EXEC_MODE = "true" ]]; 
      then 
          echo "aws elbv2 deregister-targets --target-group-arn $tgarn --targets Id=$tginstance; "
      else 
          echo "aws elbv2 deregister-targets --target-group-arn $tgarn --targets Id=$tginstance; #$instancename"
    fi
    
  done
done

# Properly formatted deregistration command below for reference.
# aws elbv2 deregister-targets --target-group-arn arn:aws:elasticloadbalancing:us-west-2:644138682826:targetgroup/ep-identity-api-http/1369311a2f6655c6 --targets Id=i-0cce77262622cce84 #ipw-identity-7aws elbv2 deregister-targets --target-group-arn arn:aws:elasticloadbalancing:us-west-2:644138682826:targetgroup/ep-identity-api-http/1369311a2f6655c6 --targets Id=i-0cce77262622cce84 #ipw-identity-7