#!/bin/bash

# Execution example:
# source rabbitmq_api_exchanges.sh --file-prefix "$HOME/Downloads/staging" --username "$RMUSER" --password "$RMPASS" --fqdn rabbit.dns.address

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --file-prefix)
    FILE_PREFIX="$2"
    shift # past argument
    shift # past value
    ;;
    --username)
    RMQ_USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
    --password)
    RMQ_PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    --fqdn)
    RMQ_SERVER_FQDN="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

FULL_EXCHANGE_FILE="$FILE_PREFIX"allexchanges.json
EMPTY_EXCHANGE_FILE="$FILE_PREFIX"emptyexchanges.json
DUP_BINDINGS_FILE="$FILE_PREFIX"duplicatebindings.json

rm -f "$EMPTY_EXCHANGE_FILE"
rm -f "$DUP_BINDINGS_FILE"

curl --location --request GET http://"$RMQ_SERVER_FQDN":15672/api/exchanges -u "$RMQ_USERNAME":"$RMQ_PASSWORD" -s > "$FULL_EXCHANGE_FILE"

while IFS= read -r line
do
  EXCHANGE_BINDINGS=$(curl --location --request GET http://"$RMQ_SERVER_FQDN":15672/api/exchanges/%2F/"$line"/bindings/source -u "$RMQ_USERNAME":"$RMQ_PASSWORD" -s | jq -c '.[]')
  if [[ $EXCHANGE_BINDINGS = "" ]]
  then
    # then echo "no bindings for $line"
    echo "$line" >> "$EMPTY_EXCHANGE_FILE"
  else 
    numbindings=$(echo "$EXCHANGE_BINDINGS" | wc -l)
    echo "$numbindings queues subscribed to $line"
    for duplicate in $(echo "$EXCHANGE_BINDINGS" | jq -c '. | {source, destination}' | sort | uniq -d | jq -r '.destination')
    do
      echo "$EXCHANGE_BINDINGS" | grep "$duplicate" >> "$DUP_BINDINGS_FILE"
    done
    echo "$EXCHANGE_BINDINGS" | jq -c '. | {source, destination, routing_key, properties_key}' | sort | jq -c '.'
  fi
done < <(jq -c '.[]' < "$FULL_EXCHANGE_FILE" | grep '"type":"fanout"' | jq -c -r '.name' )
