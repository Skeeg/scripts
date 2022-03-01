#!/bin/bash
FROMDATE=$(date -u -v -6H '+%Y-%m-%dT%H:%M:%SZ')
TODATE=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

#Use what you just built:
$REPOPATH/loki/cmd/logcli/logcli query \
  --from="$FROMDATE" \
  --to="$TODATE" \
  --timezone=UTC \
  --output=jsonl \
  --limit=500 \
  '{namespace="namespace"} |="ERROR"' | \
  jq -cr '.line | fromjson' > $REPOPATH/virus-scanning-service/scripts/errorlog.txt