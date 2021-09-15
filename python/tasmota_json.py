import json
import requests
import pyping
import typer
import ipaddress
import os.path

def compileTasmotaDict(tasIpAddr: str, tasCommand: str, baseDict: dict):
  cmdBasePath = 'http://' + tasIpAddr + '/cm?cmnd=' + tasCommand
  response = requests.get(cmdBasePath)
  response.raise_for_status()
  jsonResponse = response.json()
  commandDict = { tasCommand : {}}
  baseDict[tasIpAddr].update(commandDict)
  baseDict[tasIpAddr][tasCommand].update(jsonResponse)
  return baseDict

def main(
#input parameters
configFile: str = "",
subnetvar: str = "10.2.4.0/24",
netTimeout: int = 1000,
netRetries: int = 1,
tasmotacommandfile: typer.FileText = typer.Option(..., mode="r")
):

  #Convert subnet string to ip_network
  validatedSubnet = ipaddress.ip_network(subnetvar, strict=False)
  
  #Bring in JSON formatted command set.
  tasmotaCommands = json.load(tasmotacommandfile)

  #Build initial dictionary for all devices.
  if os.path.isfile(configFile):
    with open(configFile, "r") as inputFile:
      outputData = json.loads(inputFile.read())
  else:
    outputData = { "tasmotas" : {}}
  
  #Loop hosts in subnet range
  for ipAddr in validatedSubnet.hosts():
    
    ipAddressString = str(format(ipaddress.IPv4Address(ipAddr)))

    #Check for network presence before checking HTTP
    netPresence = pyping.ping(ipAddressString, timeout=netTimeout, count=netRetries, udp = True)

    if netPresence.ret_code == 0:
      #This is a good endpoint to confirm we are actually talking to Tasmota firmware
      sanityUri = 'http://' + ipAddressString + '/cm?cmnd=status%202'
      try:
        #Execute Tasmota device sanity check
        tasCheck = requests.get(sanityUri)
        tasCheck.raise_for_status()

        #We look to have a Tasmota
        if tasCheck.status_code == 200:
          print(ipAddressString + " collecting Tasmota device configurations")
          
          #Setup device specific dictionary
          dictUpdate = { str(ipAddressString) : {} }

          #Iterate over commands to query data and update device specific dictionary
          for command in tasmotaCommands["Commands"]:
            dictUpdate = compileTasmotaDict(ipAddressString, command, dictUpdate)

          #Update final output dictionary
          outputData["tasmotas"].update(dictUpdate)
          
          #Update results to file as JSON

          with open(configFile, "w") as outputfile:
            json.dump(outputData, outputfile, indent=2)

        #Device didn't give back Tasmota data, report to CLI
        else:
          print(ipAddressString + " appears not to be a Tasmota device")
      
      #Device threw an error, print details
      except Exception as err:
        print(f'An error occurred on {ipAddressString}: {err}')
        pass
    
    #Nothing at this IP
    if netPresence.ret_code == 1:
      print(ipAddressString + " is closed")

if __name__ == "__main__":
  typer.run(main)
