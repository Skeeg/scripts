#!/bin/bash
SCRIPTBUCKET="EXAMPLE"
aws s3api list-object-versions --bucket $SCRIPTBUCKET --query 'DeleteMarkers[?IsLatest==`true`]' > "/tmp/$SCRIPTBUCKET-delete-markers.json"

while IFS= read -r line
do
  SCRIPTKEY=$(echo "$line" | jq -r .Key)
  SCRIPTVERSIONID=$(echo $line | jq -r .VersionId)
  printf "Deleting %s Version : " "$SCRIPTKEY"
  aws s3api delete-object --bucket $SCRIPTBUCKET --key "$SCRIPTKEY" --version-id "$SCRIPTVERSIONID" | jq -rc .VersionId
done < <(jq -c '.[]' < "/tmp/$SCRIPTBUCKET-delete-markers.json")
