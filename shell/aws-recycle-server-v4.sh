#!/bin/bash
# shellcheck source=/dev/null

# Relies on using AWS_PROFILE to set the environment.
# https://github.com/common-fate/granted is a great tool to facilitate this.

#Execution Example:
# scripts="$REPOPATH/scripts"; 
# source $scripts/shell/aws-recycle-server-v4.sh \
#   --aws-profile $(tfenvironment) \
#   --deregister true \
#   --execute-taint true \
#   --salt-master-user rpeay \
#   --terraform-cloud true \
#   --target-resource ec2_app \
#   --target-index 0

terraform_target_group_parse() {
  EXEC_MODE="$1"
  tfoutputdata=$(terraform show --json | jq -r '.values.outputs')
  for tgname in $(echo "$tfoutputdata" | jq --raw-output '.tg_attachments.value | keys[]')
  do
    echo \#$tgname
    tgdata=$(echo "$tfoutputdata" | jq --raw-output ".tg_attachments.value.$tgname")
    tgarn=$(echo "$tgdata" | jq --raw-output '.target_group')
    for tginstance in $(echo "$tgdata" | jq --raw-output '.target_id[]')
    do
      instancename=$(echo "$tfoutputdata" | jq --raw-output ".ec2_id_mapping.value.instances.\"$tginstance\"")
      if [[ $EXEC_MODE = "verbose" ]]; 
        then 
            echo "aws elbv2 deregister-targets --target-group-arn $tgarn --targets Id=$tginstance; #$instancename "
        else 
            echo "aws elbv2 deregister-targets --target-group-arn $tgarn --targets Id=$tginstance;"
      fi
      
    done
  done
}

checkterraformtargetgroupmembers() {
  ENVIRON="$1"

  TERRAFORM_DATA=$(terraform show --json | \
      jq -r '.values.outputs.automation_target_groups.value.target_group_arns[]')
  for TARGET_GROUP in $(echo "$TERRAFORM_DATA" | tr '\n' ' ')
  do
    echo "$TARGET_GROUP"
    TARGET_HEALTH=$(AWS_PROFILE="$ENVIRON" aws elbv2 describe-target-health --target-group-arn "$TARGET_GROUP")
    echo "$TARGET_HEALTH" | jq -c '.TargetHealthDescriptions[]'
  done
}

EXECUTE_APPLY="false"
EXECUTE_DEREGISTRATION="false"
EXECUTE_TAINT="false"

unset INSTANCE_TO_CYCLE INSTANCE_RESOURCE_NAME AWS_ENVIRON SALTUSER TFC_AGENT
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --target-index)
        INSTANCE_TO_CYCLE="$2"
        shift # past argument
        shift # past value
        ;;
        --salt-master-user)
        SALTUSER="$2"
        shift # past argument
        shift # past value
        ;;
        --target-resource)
        INSTANCE_RESOURCE_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        -d|--deregister)
        EXECUTE_DEREGISTRATION="$2"
        shift # past argument
        shift # past value
        ;;
        -et|--execute-taint)
        EXECUTE_TAINT="$2"
        shift # past argument
        shift # past value
        ;;
        -ea|--execute-apply)
        EXECUTE_APPLY="$2"
        shift # past argument
        shift # past value
        ;;
        -ap|--aws-profile)
        AWS_ENVIRON="$2"
        shift # past argument
        shift # past value
        ;;
        -tfc|--terraform-cloud)
        TFC_AGENT="true"
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

BANNER_STRING="########################################"
unset TERRAFORM_OUTPUT RECYCLE_INSTANCE_NAME RECYCLE_INSTANCE_ID CURRENT_BINDINGS

RECYCLE_INSTANCE_NAME=$(terraform state show "module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]" | grep -A2 "tags" | head -n2 | tail -n1 | cut -d"\"" -f4)
RECYCLE_INSTANCE_ID=$(terraform state show "module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]" | grep -e "^.*id.*i-.*" | head -n1 | cut -d"\"" -f2)

#TERRAFORM_OUTPUT=$(terraform output -json | jq .)
#RECYCLE_INSTANCE_NAME=$(echo "$TERRAFORM_OUTPUT" | jq --raw-output ".ec2_resource_index.value.$INSTANCE_RESOURCE_NAME.\"$INSTANCE_TO_CYCLE\"")
#RECYCLE_INSTANCE_ID=$(echo "$TERRAFORM_OUTPUT" | jq --raw-output ".ec2_id_reverse_mapping.value.instances.\"$RECYCLE_INSTANCE_NAME\"")


if [[ $RECYCLE_INSTANCE_NAME != null ]]; 
  then 
    #Found an instance, rock on.
      printf "\n%s\n" "$BANNER_STRING"
    echo "module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]"
    echo "Friendly Name: $RECYCLE_INSTANCE_NAME: "
    echo "Instance ID: $RECYCLE_INSTANCE_ID"
      printf "%s\n" "$BANNER_STRING"

    if [[ $EXECUTE_DEREGISTRATION == "true" ]]
      then 
        printf  "\n%s\nDefining Potential Deregistration Commands\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        DEREGISTRATION_COMMANDS=$(terraform_target_group_parse verbose)

        printf "\n%s\nStopping PS Services\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        ssh "$SALTUSER"@saltmaster-"$AWS_ENVIRON".vnerd.com "sudo salt $RECYCLE_INSTANCE_NAME cmd.run shell=powershell 'get-service PS* | stop-service -verbose'"

        printf  "\n%s\nConfirming Current Target Group Binding for $RECYCLE_INSTANCE_ID\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        CURRENT_BINDINGS=$(checkterraformtargetgroupmembers "$AWS_ENVIRON" | \
          grep -E "arn|$RECYCLE_INSTANCE_ID")
        echo "$CURRENT_BINDINGS"

        printf "\n%s\nStarting Deregistration\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        while IFS= read -r line
        do 
          echo "AWS_PROFILE=$AWS_ENVIRON $line"
          eval "AWS_PROFILE=$AWS_ENVIRON $line"
        done < <(echo "$DEREGISTRATION_COMMANDS" | grep "$RECYCLE_INSTANCE_ID")

        printf "\n%s\nConfirming Deregistration\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        CURRENT_BINDINGS=$(checkterraformtargetgroupmembers "$AWS_ENVIRON" | \
          grep -E "$RECYCLE_INSTANCE_ID")
        echo "Current Registrations: $CURRENT_BINDINGS"
        while [[ "$CURRENT_BINDINGS" != "" ]]
        do
          echo "Still have bindings, looping"
          sleep 5
          CURRENT_BINDINGS=$(checkterraformtargetgroupmembers "$AWS_ENVIRON" | \
            grep -E "$RECYCLE_INSTANCE_ID")
          echo "Current Registrations: $CURRENT_BINDINGS"
        done

        if [[ $EXECUTE_TAINT == "true" ]]
          then 
            printf "\n%s\nTainting Resource\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
            terraform taint "module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]"
        fi

        if [[ $EXECUTE_APPLY == "true" ]]
          then 
            printf "\n%s\nApply Changes\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
            # terraform apply -auto-approve
            if [[ $TFC_AGENT == "true" ]]
              then
                printf "Resource is tainted, proceed in Terraform Cloud"
              else
                terraform apply -target="module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]" #-auto-approve
            fi
        fi
      else
        echo "Checking Current Target Group Bindings"
        checkterraformtargetgroupmembers "$AWS_ENVIRON" | \
        grep -E "arn|$RECYCLE_INSTANCE_ID"
    fi
  else
    echo "no entry found for module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]"
fi
