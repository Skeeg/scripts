#!/bin/bash
NAME="ec2-instance-name"
INSTANCEID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query 'Reservations[*].Instances[*].InstanceId' | jq -r '.[][]')
EXECUTIONID=$(aws ssm start-automation-execution --document-name "$SSMDOCUMENT" --parameters "AutomationAssumeRole=arn:aws:iam::$AWS_ACCOUNT_ID:role/$SSM_ASSUME_ROLE,InstanceIds=$INSTANCEID" | jq -r .AutomationExecutionId)
# aws ssm describe-automation-step-executions --automation-execution-id "$EXECUTIONID" | jq .
COMMANDID=$(aws ssm describe-automation-step-executions --automation-execution-id "$EXECUTIONID" | jq -r '.StepExecutions[1].Outputs.CommandId[]')
# aws ssm get-command-invocation --command-id $COMMANDID --instance-id $INSTANCEID
# aws ssm list-command-invocations --command-id $COMMANDID --instance-id $INSTANCEID --details
aws ssm list-command-invocations --command-id $COMMANDID --instance-id $INSTANCEID --details | jq '.CommandInvocations[].CommandPlugins[] | {Name, Output}'
