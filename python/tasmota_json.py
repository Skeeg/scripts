import json
import requests
import time
import pyping
import typer
import ipaddress

# import sys

# print('Number of arguments:', len(sys.argv), 'arguments.')
# print('Argument List:', str(sys.argv))
def main(
#input parameters
subnetvar: str = "10.2.4.0/24", 
tasmotacommandfile: typer.FileText = typer.Option(..., mode="r"),
outputfile: typer.FileText = typer.Option(..., mode="w")):

  validatedSubnet = ipaddress.ip_network(subnetvar, strict=True)
  timeout = 1
  
  # for ipAddr in validatedSubnet.hosts():
  #   print(format(ipaddress.IPv4Address(ipAddr)))
  
  tasmotaCommands = json.load(tasmotacommandfile)

  outputData = { "tasmotas" : {}}
  for ipAddr in validatedSubnet.hosts():
    # if checkHost(ipAddress,port) == True:
    ipAddressString = format(ipaddress.IPv4Address(ipAddr))
    r = pyping.ping(ipAddressString, timeout=1000, count=1, udp = True)
    if r.ret_code == 0:
      sanityUri = 'http://' + ipAddressString + '/cm?cmnd=status%202'
      try:
        tasCheck = requests.get(sanityUri)
        tasCheck.raise_for_status()
        if tasCheck.status_code == 200:
          print(ipAddressString + " collecting Tasmota device configurations")
          baseDict = { str(ipAddressString) :{}}
          for command in tasmotaCommands["Commands"]:
            cmdBasePath = 'http://' + ipAddressString + '/cm?cmnd=' + command
            response = requests.get(cmdBasePath)
            response.raise_for_status()
            jsonResponse = response.json()
            commandDict = { str(command) : {}}
            baseDict[ipAddressString].update(commandDict)
            baseDict[ipAddressString][command].update(jsonResponse)
            outputData["tasmotas"].update(baseDict)
          # print(json.dumps(baseDict))
        else:
          print(ipAddressString + " appears not to be a Tasmota device")
      except Exception as err:
        print(f'An error occurred on {ipAddressString}: {err}')
        pass
    if r.ret_code == 1:
      print(ipAddressString + " is closed")

  json.dump(outputData, outputfile, indent=2)

if __name__ == "__main__":
  typer.run(main)
