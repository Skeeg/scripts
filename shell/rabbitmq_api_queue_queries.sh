#!/bin/bash

# Execution example:
# source rabbitmq_api_queue_queries.sh --file-prefix "$HOME/Downloads/staging" --username "$RMUSER" --password "$RMPASS" --fqdn rabbit.dns.address --show-delete-commands --queue-name-pattern "mitigations"

unset SHOW_COMMANDS
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --queue-name-pattern)
    QUEUE_NAME_PATTERN="$2"
    shift # past argument
    shift # past value
    ;;
    --file-prefix)
    FILE_PREFIX="$2"
    shift # past argument
    shift # past value
    ;;
    --show-delete-commands)
    SHOW_COMMANDS="true"
    shift # past argument
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

if [[ ! $QUEUE_NAME_PATTERN ]]; 
then 
    echo "Provide a string to search for in the queue names."
    return
fi

FULL_QUEUE_FILE="$FILE_PREFIX"allqueues.json
QBINDINGS_FILE="$FILE_PREFIX"qbindings.json
QDETAILS_FILE="$FILE_PREFIX"qdetails.json

rm -f "$QBINDINGS_FILE"
rm -f "$QDETAILS_FILE"

curl --location --request GET http://"$RMQ_SERVER_FQDN":15672/api/queues -u "$RMQ_USERNAME":"$RMQ_PASSWORD" -s > "$FULL_QUEUE_FILE"

while IFS= read -r line
do 
  QDETAIL=$(curl --location --request GET http://"$RMQ_SERVER_FQDN":15672/api/queues/%2F/"$line" -u "$RMQ_USERNAME":"$RMQ_PASSWORD" -s | jq -c '. | {name,consumers,messages}')
  if [[ ! $QDETAIL = "" ]]; then echo "$QDETAIL" | tee -a "$QDETAILS_FILE" | jq -c .; fi
  QBINDING=$(curl --location --request GET http://"$RMQ_SERVER_FQDN":15672/api/queues/%2F/"$line"/bindings -u "$RMQ_USERNAME":"$RMQ_PASSWORD" -s | jq -c '.[] | {source,destination}' | grep -v '"source":"",' | jq -c .)
  if [[ ! $QBINDING = "" ]]
  then 
    echo "$QBINDING" | tee -a "$QBINDINGS_FILE" | jq -c .
    # echo "Other Queues subscribed to the same Exchange"
    # EXCHANGE_BINDINGS=$(curl --location --request GET http://"$RMQ_SERVER_FQDN":15672/api/exchanges/%2F/"$(echo "$QBINDING" | jq -r .source)"/bindings/source -u "$RMQ_USERNAME":"$RMQ_PASSWORD" -s | jq -c '.[]')
    # echo "$EXCHANGE_BINDINGS"
    # echo "$EXCHANGE_BINDINGS" | wc -l
  fi
  
done < <(jq -r -c '.[]' < "$FULL_QUEUE_FILE" | grep "$QUEUE_NAME_PATTERN" | jq -r .name | sed 's/=/%3D/g; s/>/%3E/g;') 

# rawurlencode function courtesy of https://stackoverflow.com/a/10660730
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER)
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

if [[ $SHOW_COMMANDS = "true" ]]; 
then 
    echo "#Cleanup commands."
    while IFS= read -r line
    do
      urlencoded=$(rawurlencode "$line")
      echo "curl --location --request GET http://$RMQ_SERVER_FQDN:15672/api/queues/%2F/$urlencoded -u \"\$RMQ_USERNAME\":\"\$RMQ_PASSWORD\" -s | jq '. | {name,node}'"
      echo "curl --location --request DELETE http://$RMQ_SERVER_FQDN:15672/api/queues/%2F/$urlencoded?if-unused=true -u \"\$RMQ_USERNAME\":\"\$RMQ_PASSWORD\""
      # echo "curl --location --request GET http://"$RMQ_SERVER_FQDN":15672/api/queues/%2F/"$urlencoded" -u \"\$RMQ_USERNAME\":\"\$RMQ_PASSWORD\""
    done < <(jq -c -r .name < "$QDETAILS_FILE")
fi
