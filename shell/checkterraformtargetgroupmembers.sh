#!/bin/bash
# shellcheck source=/dev/null

unset DEBUG_STR ENVIRON OUTPUT_NAME SCRIPTPATH

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --assume-role)
        ENVIRON="$2"
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
        shift # past argument
        shift # past value
        ;;
        -ars|--assume-role-silently)
        ASSUME_SILENT="$2"
        shift # past argument
        shift # past value
        ;;
        --script-path)
        SCRIPTPATH="$2"
        shift # past argument
        shift # past value
        ;;
        --debug)
        DEBUG_STR="--debug"
        shift # past argument
        ;;
        --output-name)
        OUTPUT_NAME="true"
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

TERRAFORM_DATA=$(terraform output -json | \
    jq --raw-output '.automation_target_groups.value.target_group_arns[]')

if [[ -n $ENVIRON ]]; 
    then 
        source "$SCRIPTPATH"/set-aws-env-vars-assume-role.sh --environment "$ENVIRON" --assume-role-silently "$ASSUME_SILENT"
    else 
        echo "Running with active credentials"; 
fi

for TARGET_GROUP in $(echo "$TERRAFORM_DATA" | tr '\n' ' ')
do
    echo "$TARGET_GROUP"
    for INSTANCE_ID in $( \
        aws elbv2 describe-target-health --target-group-arn "$TARGET_GROUP" $DEBUG_STR| \
            jq --raw-output '.TargetHealthDescriptions[].Target.Id')
    do
        # echo $INSTANCE_ID
        # aws ec2 describe-instances --instance-ids $INSTANCE_ID
        if [[ $OUTPUT_NAME == "true" ]]
            then INSTANCE_NAME=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" $DEBUG_STR| 
                jq --raw-output \
                '
                    .Reservations[].Instances[] 
                    | ( .Tags[] ? | select(.Key=="Name") |.Value ) as $Name 
                    | $Name
                ')
                echo "$INSTANCE_NAME : $INSTANCE_ID"
            else 
                echo "$INSTANCE_ID"
        fi
    done
done

if [[ -n $ENVIRON ]]; 
    then 
        echo "Cleaned up assumed role"; 
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN
fi
