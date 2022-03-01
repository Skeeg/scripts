#!/bin/bash
awsaccountid="1234567890"
srcregion="us-west-2"
dstregion="eu-central-1"
queryidentifier="db_id"
targetkmskey=$(aws kms list-aliases --region "$dstregion" | jq --raw-output '.[][] | select( .AliasName == "alias/aws/rds" ) | .TargetKeyId')

rdssnap=$(aws rds describe-db-snapshots \
  --region "$srcregion" \
  --db-instance-identifier "$queryidentifier" \
  --query="reverse(sort_by(DBSnapshots, &SnapshotCreateTime))[0] | DBSnapshotIdentifier" \
  --output text | cut -d":" -f2)

aws rds copy-db-snapshot \
  --source-db-snapshot-identifier arn:aws:rds:"$srcregion":$awsaccountid:snapshot:rds:"$rdssnap" \
  --target-db-snapshot-identifier "$rdssnap" \
  --kms-key-id "$targetkmskey" \
  --source-region "$srcregion" \
  --region "$dstregion" \
  --copy-tags

queryidentifier="db_cluster_id"

clustersnap=$(aws rds describe-db-cluster-snapshots \
  --region "$srcregion" \
  --db-cluster-identifier "$queryidentifier" \
  --query 'reverse(sort_by(DBClusterSnapshots, &SnapshotCreateTime))[0] | DBClusterSnapshotIdentifier' \
  --output text | cut -d":" -f2)

aws rds copy-db-cluster-snapshot \
  --source-db-cluster-snapshot-identifier arn:aws:rds:"$srcregion":$awsaccountid:cluster-snapshot:rds:"$clustersnap" \
  --target-db-cluster-snapshot-identifier "$clustersnap" \
  --kms-key-id "$targetkmskey" \
  --source-region "$srcregion" \
  --region "$dstregion" \
  --copy-tags