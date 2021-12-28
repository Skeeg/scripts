#!/bin/bash

HOMEASSISTANTPATH="$HOME/docker/homeassistant/.storage"
unset ENTRY_TO_DELETE
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        --entry-to-delete)
        ENTRY_TO_DELETE="$2"
        shift # past argument
        shift # past value
        ;;
        --homeassistant-path)
        HOMEASSISTANTPATH="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

# shellcheck disable=SC2089
grepentityfilter="ue_id\":\"$ENTRY_TO_DELETE"
entity_version=$(jq -r .version < "$HOMEASSISTANTPATH"/core.entity_registry)
entity_key=$(jq .key < "$HOMEASSISTANTPATH"/core.entity_registry)
entity_entries=$(
while IFS= read -r line
do
  echo "$line,"
done < <(jq .data.entities[] -c < "$HOMEASSISTANTPATH"/core.entity_registry | grep -v "$grepentityfilter" | jq . -c)
)
entitystrval=$(echo "$entity_entries" | tr '\n' ' ' | sed 's/, $//g')
cat <<EOF | jq . > "$HOMEASSISTANTPATH"/core.entity_registry
{
    "version": $entity_version,
    "key": $entity_key,
    "data": {
        "entities": [$entitystrval]
    }
}
EOF

# shellcheck disable=SC2089
grepdevicefilter="\"$ENTRY_TO_DELETE\"]]"
device_version=$(jq -r .version < "$HOMEASSISTANTPATH"/core.device_registry)
device_key=$(jq .key < "$HOMEASSISTANTPATH"/core.device_registry)

device_entries=$(
while IFS= read -r line
do
  echo "$line,"
done < <(jq .data.devices[] -c < "$HOMEASSISTANTPATH"/core.device_registry | grep -v "$grepdevicefilter" | jq . -c)
)
strval=$(echo "$device_entries" | tr '\n' ' ' | sed 's/, $//g')
cat <<EOF | jq . > "$HOMEASSISTANTPATH"/core.device_registry
{
    "version": $device_version,
    "key": $device_key,
    "data": {
        "devices": [$strval]
    }
}
EOF
