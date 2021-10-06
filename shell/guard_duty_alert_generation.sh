#!/bin/bash
echo "Starting Network Scan to create finding type: Recon:EC2/Portscan"
subnet=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')
nmap -Pn "$subnet"
echo "Calling bitcoin wallets to download mining toolkits to create finding type CryptoCurrency:EC2/BitcoinTool.B!DNS"
curl -s 'http://pool.minergate.com/dkjdjkjdlsajdkljalsskajdksakjdksajkllalkdjsalkjdsalkjdlkasj'  > /dev/null &
curl -s 'http://xmr.pool.minergate.com/dhdhjkhdjkhdjkhajkhdjskahhjkhjkahdsjkakjasdhkjahdjk'  > /dev/null &
echo "Calling a well known fake domain that is used to generate a known finding type Backdoor:EC2/C&CActivity.B!DNS"
dig GuardDutyC2ActivityB.com any