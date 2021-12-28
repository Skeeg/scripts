#!/bin/bash
for ip in $(jq -c '.tasmotas[]' < $HOME/Downloads/2021-09-22-tasmota-information.json | grep "(sensors)" | jq -rc '."Status 0".StatusNET.IPAddress');
do
  statusinfo=$(curl --connect-timeout 1 "http://$ip/cm?cmnd=status%200" -s | jq -c);
  hostname=$(echo $statusinfo | jq .StatusNET.Hostname)
  ipaddr=$(echo $statusinfo | jq '.StatusNET.IPAddress[-3:]')
  powerstate=$(echo $statusinfo | jq .Status.Power)
  echo "{\"PowerState\": $powerstate, \"IPAddress\": $ipaddr, \"Hostname\": $hostname}" | jq -c .
  # unset currentset;
  # currentset=$(curl --connect-timeout 1 "http://$ip/cm?cmnd=currentset" -s | jq .CurrentSetCal);
  # if [[ $currentset -ne "" ]]; then
  #   powerset=$(curl --connect-timeout 1 "http://$ip/cm?cmnd=powerset" -s | jq .PowerSetCal);
  #   voltageset=$(curl --connect-timeout 1 "http://$ip/cm?cmnd=voltageset" -s | jq .VoltageSetCal);
  # fi
done | sort