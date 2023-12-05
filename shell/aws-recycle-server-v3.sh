#!/bin/bash
# shellcheck source=/dev/null

#Execution Example:
# scripts="$repopath/scripts"; 
# source $scripts/shell/aws-recycle-server-v2.sh --assume-role $(cat .terraform/environment) \
#   --deregister false \
#   --execute-apply false \
#   --target-resource identity_instance_stig \
#   --target-index 5 \
#   --assume-role-silently "true" \
#   --salt-master-user "rpeay" \
#   --script-path $scripts/shell
#
# needed scripts:
# checkterraformtargetgroupmembers.sh
# set-aws-env-vars-assume-role.sh
# terraform_target_group_parse.sh

EXECUTE_DEREGISTRATION="false"
EXECUTE_TERMINATION="false"
ASSUME_SILENT="false"

unset INSTANCE_TO_CYCLE INSTANCE_RESOURCE_NAME ASSUME_ENVIRON SCRIPTPATH SALTUSER TFC_AGENT
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --target-index)
        INSTANCE_TO_CYCLE="$2"
        shift # past argument
        shift # past value
        ;;
        --script-path)
        SCRIPTPATH="$2"
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
        -ea|--execute-apply)
        EXECUTE_TERMINATION="$2"
        shift # past argument
        shift # past value
        ;;
        -ars|--assume-role-silently)
        ASSUME_SILENT="$2"
        shift # past argument
        shift # past value
        ;;
        -ar|--assume-role)
        ASSUME_ENVIRON="$2"
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
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

if [[ ! -e $SCRIPTPATH ]]
then
  echo "$SCRIPTPATH does not exist"
  return
fi

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
        DEREGISTRATION_COMMANDS=$(source "$SCRIPTPATH"/terraform_target_group_parse.sh)

        printf "\n%s\nStopping PS Services\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        ssh "$SALTUSER"@saltmaster-"$ASSUME_ENVIRON".vnerd.com "sudo salt $RECYCLE_INSTANCE_NAME cmd.run shell=powershell 'get-service PS* | stop-service -verbose'"

        printf  "\n%s\nConfirming Current Target Group Binding for $RECYCLE_INSTANCE_ID\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        CURRENT_BINDINGS=$(source "$SCRIPTPATH"/checkterraformtargetgroupmembers.sh --assume-role "$ASSUME_ENVIRON" --assume-role-silently "true" --script-path "$SCRIPTPATH" | \
          grep -E "arn|$RECYCLE_INSTANCE_ID")
        echo "$CURRENT_BINDINGS"

        printf "\n%s\nAssuming Role for AWS Accounts\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        # source "$SCRIPTPATH"/set-aws-env-vars-assume-role.sh --environment "$ASSUME_ENVIRON" --assume-role-silently "$ASSUME_SILENT"
        export 

        printf "\n%s\nStarting Deregistration\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        while IFS= read -r line
        do 
          echo "$line"
          eval "$line"
        done < <(echo "$DEREGISTRATION_COMMANDS" | grep "$RECYCLE_INSTANCE_ID")

        printf "\n%s\nReleasing Role to work in Terraform State\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN

        printf "\n%s\nConfirming Deregistration\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        CURRENT_BINDINGS=$(source "$SCRIPTPATH"/checkterraformtargetgroupmembers.sh --assume-role "$ASSUME_ENVIRON" --assume-role-silently "$ASSUME_SILENT" --script-path "$SCRIPTPATH" | \
          grep -E "$RECYCLE_INSTANCE_ID")
        echo "Current Registrations: $CURRENT_BINDINGS"
        while [[ "$CURRENT_BINDINGS" != "" ]]
        do
          echo "Still have bindings, looping" #and skipped sleeping 10"
          #sleep 10
          CURRENT_BINDINGS=$(source "$SCRIPTPATH"/checkterraformtargetgroupmembers.sh --assume-role "$ASSUME_ENVIRON" --assume-role-silently "$ASSUME_SILENT" --script-path "$SCRIPTPATH" | \
            grep -E "$RECYCLE_INSTANCE_ID")
          echo "Current Registrations: $CURRENT_BINDINGS"
        done

        if [[ $EXECUTE_TERMINATION == "true" ]]
          then 
            printf "\n%s\nTainting Resource\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
            terraform taint "module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]"

            printf "\n%s\nApply Changes\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
            # terraform apply -auto-approve
            if [[ $TFC_AGENT == "true" ]]
              then
                printf "Resource is tainted, proceed in Terraform Cloud"
              else
                terraform apply -target="module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]" #-auto-approve
            fi
          else
            printf "\n%s\nSkipping terraform apply, server quiesced\n%s\n" "$BANNER_STRING" "$BANNER_STRING"
        fi
      else
        echo "Checking Current Target Group Bindings"
        source "$SCRIPTPATH"/checkterraformtargetgroupmembers.sh --assume-role "$ASSUME_ENVIRON" --assume-role-silently "$ASSUME_SILENT" --script-path "$SCRIPTPATH" | \
        grep -E "arn|$RECYCLE_INSTANCE_ID"
    fi
  else
    echo "no entry found for module.$INSTANCE_RESOURCE_NAME.aws_instance.instance[$INSTANCE_TO_CYCLE]"
fi
