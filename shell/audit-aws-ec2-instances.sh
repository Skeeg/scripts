#!/bin/bash

#Potential Usage:
#audit-aws-ec2-instances.sh --bounded-context identity -lt --date 2020-04-01 

#Set Default Values
BOUNDED_CONTEXT="identity"
DATE_VALUE="2099-12-31"
DATE_FILTER="<"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -bc|--bounded-context)
    BOUNDED_CONTEXT="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--date)
    DATE_VALUE="$2"
    shift # past argument
    shift # past value
    ;;
    -gt|--greater-than)
    DATE_FILTER=">"
    shift # past argument
    ;;
    -lt|--less-than)
    DATE_FILTER="<"
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# echo "Working on $BOUNDED_CONTEXT BC now"
# Can add extra output in the jq {} block with extra content such as this:
# , InstanceType: .InstanceType, PrivateIPAddress: .PrivateIpAddress, IamInstanceProfile: .IamInstanceProfile.Arn
aws ec2 describe-instances --filters "Name=tag:bc,Values=$BOUNDED_CONTEXT" | 
jq --arg date "$DATE_VALUE" --compact-output '
{
    Instances: [
        .Reservations[].Instances[] 
        | (.Tags[] ? | select(.Key=="Name")|.Value) as $Name 
        | {Name: $Name, InstanceId: .InstanceId, PrivateIPAddress: .PrivateIpAddress, Launchtime: .LaunchTime, State: .State.Name}
    ]
}
| .Instances 
|= sort_by(.Name) 
| .Instances[] 
| select(.Launchtime '$DATE_FILTER' $date)'