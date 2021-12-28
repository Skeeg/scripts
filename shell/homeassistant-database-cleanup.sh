#/!bin/bash
# cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq 'del (.data.entities[] | select (.unique_id | contains ("233BE2"))

# cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq '. | del(.data.entities[].unique_id | select (. | contains ("233BE2")))'

# cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq 'walk(if .unique_id). | del( | select (.data.entities[].unique_id | contains ("233BE2")))'

# values=$(cat << EOF
# this
# is
# each
# entry
# EOF
# )
# while IFS= read -r line
# do
#   echo "Stuff is $line"
# done < <(echo "$values")

# while IFS= read -r line
# do
#   echo "Stuff is $line"
# done < <(cat << EOF
# Test
# Er
# Osa
# EOF
# )

unset ENTRY_TO_DELETE
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        --target-index)
        ENTRY_TO_DELETE="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

for device_id in $(echo "5C6ADB_RL_1 233DAE_RL_1 233661_RL_1 89AA43_RL_1 158D0A_RL_1 E8396C_RL_1"); 
do
  mac_address=$(echo "$device_id" | sed 's/_RL_1//g')
  # entityfilter="\"$mac_address\" as \$filter | .version as \$version | .key as \$key | {\"version\":\$version, \"key\": \$key, \"data\": {\"entities\": (.data.entities | map(select(.unique_id | contains (\$filter)|not)))}}"
  # cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq "$entityfilter" > ~/docker/homeassistant/.storage/core.entity_registry.clone

  # devicefilter=".data.devices[] | select (.identifiers[][] | contains(\"$mac_address\"))"
  #following gives full device line
  #cat ~/docker/homeassistant/.storage/core.device_registry.clone | jq "$devicefilter" -c
  grepentityfilter="ue_id\":\"$mac_address"
  entity_version=$(cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq -r .version)
  entity_key=$(cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq .key)
  # all_entity_entries=$(cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq .data.entities[] -c | grep -v $grepentityfilter | jq . -c)
  entity_entries=$(
  while IFS= read -r line
  do
    echo "$line,"
  done < <(cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq .data.entities[] -c | grep -v $grepentityfilter | jq . -c)
  )
  entitystrval=$(echo "$entity_entries" | tr '\n' ' ' | sed 's/, $//g')
  cat <<EOF | jq . > ~/docker/homeassistant/.storage/core.entity_registry.clone
{
    "version": $entity_version,
    "key": $entity_key,
    "data": {
        "entities": [$entitystrval]
    }
}
EOF

  grepdevicefilter="\"$mac_address\"]]"
  device_version=$(cat ~/docker/homeassistant/.storage/core.device_registry.clone | jq -r .version)
  device_key=$(cat ~/docker/homeassistant/.storage/core.device_registry.clone | jq .key)
  # all_device_entries=$(cat ~/docker/homeassistant/.storage/core.device_registry.clone | jq .data.devices[] -c | grep -v $grepdevicefilter | jq . -c)

  device_entries=$(
  while IFS= read -r line
  do
    echo "$line,"
  done < <(cat ~/docker/homeassistant/.storage/core.device_registry.clone | jq .data.devices[] -c | grep -v $grepdevicefilter | jq . -c)
  )
  # echo "$device_entries" | tr '\n' ' ' | sed 's/, $//g'
  strval=$(echo "$device_entries" | tr '\n' ' ' | sed 's/, $//g')
  #> ~/docker/homeassistant/.storage/core.device_registry.clone
  cat <<EOF | jq . > ~/docker/homeassistant/.storage/core.device_registry.clone
{
    "version": $device_version,
    "key": $device_key,
    "data": {
        "devices": [$strval]
    }
}
EOF
done

cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq '.data.entities[]' -c | wc -l
cat ~/docker/homeassistant/.storage/core.device_registry.clone | jq '.data.devices[]' -c | wc -l



229553
87958B
2334C2

for device_id in $(echo "2334C2"); 
do
  mac_address=$(echo "$device_id" | sed 's/_RL_1//g')
  grepentityfilter="ue_id\":\"$mac_address"
  entity_version=$(cat ~/docker/homeassistant/.storage/core.entity_registry | jq -r .version)
  entity_key=$(cat ~/docker/homeassistant/.storage/core.entity_registry | jq .key)
  entity_entries=$(
  while IFS= read -r line
  do
    echo "$line,"
  done < <(cat ~/docker/homeassistant/.storage/core.entity_registry | jq .data.entities[] -c | grep -v $grepentityfilter | jq . -c)
  )
  entitystrval=$(echo "$entity_entries" | tr '\n' ' ' | sed 's/, $//g')
  cat <<EOF | jq . > ~/docker/homeassistant/.storage/core.entity_registry
{
    "version": $entity_version,
    "key": $entity_key,
    "data": {
        "entities": [$entitystrval]
    }
}
EOF

  grepdevicefilter="\"$mac_address\"]]"
  device_version=$(cat ~/docker/homeassistant/.storage/core.device_registry | jq -r .version)
  device_key=$(cat ~/docker/homeassistant/.storage/core.device_registry | jq .key)

  device_entries=$(
  while IFS= read -r line
  do
    echo "$line,"
  done < <(cat ~/docker/homeassistant/.storage/core.device_registry | jq .data.devices[] -c | grep -v $grepdevicefilter | jq . -c)
  )
  strval=$(echo "$device_entries" | tr '\n' ' ' | sed 's/, $//g')
  cat <<EOF | jq . > ~/docker/homeassistant/.storage/core.device_registry
{
    "version": $device_version,
    "key": $device_key,
    "data": {
        "devices": [$strval]
    }
}
EOF
done




# cat ~/docker/homeassistant/.storage/core.device_registry.clone | jq '"E8396C" as $filter | .version as $version | .key as $key | {"version":$version, "key": $key, "data": {"entities": (.data.entities | map(select(.unique_id | contains ($filter)|not)))}}'

# cat ~/docker/homeassistant/.storage/core.entity_registry.clone | jq -c '"233BE2" as $filter | .version as $version | .key as $key | {"version":$version, "key": $key, "data": {"entities": (.data.entities | map(select(.unique_id | contains ($filter)|not)))}}



# {
#   "entity_id": "switch.basement_fan",
#   "original_name": "Gazebo Lights",
#   "unique_id": "5C6ADB_RL_1"
# }
# {
#   "entity_id": "switch.top_christmas",
#   "original_name": "Unused01",
#   "unique_id": "233DAE_RL_1"
# }
# {
#   "entity_id": "switch.bottom_christmas",
#   "original_name": "Unused02",
#   "unique_id": "233661_RL_1"
# }
# {
#   "entity_id": "switch.laptop_charger",
#   "original_name": "Unused03",
#   "unique_id": "89AA43_RL_1"
# }
# {
#   "entity_id": "switch.electric_fence",
#   "original_name": "Animal Shed",
#   "unique_id": "158D0A_RL_1"
# }
# {
#   "entity_id": "switch.island_decorations",
#   "original_name": "Pi Hole",
#   "unique_id": "E8396C_RL_1"
# }