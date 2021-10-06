#!/bin/bash
oktaData=$(curl --silent -X POST --compressed \
  https://system.vnerd.com/graphql \
  -H 'Content-Type: application/json' \
  --data-binary '{"query":"query Query {allOktaGroups {edges {node {oktaMembers {nodes {firstName lastName department email lastUpdatedAt location status}} name}}}}","variables":null,"operationName":"Query"}' | jq .)

#subsequent filter:
echo "$oktaData" | jq -c '.data.allOktaGroups.edges[]' | grep incognito | jq .