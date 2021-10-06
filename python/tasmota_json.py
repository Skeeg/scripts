import json
import requests
import pyping
import typer
import ipaddress
import os.path
import urllib.parse
import random
import paho.mqtt.client as mqtt_client

broker = '10.2.2.4'
port = 1883
client_id = f'python-mqtt-{random.randint(0, 1000)}'

def connect_mqtt():
  def on_connect(client, userdata, flags, rc):
    if rc == 0:
      print("Connected to MQTT Broker!")
    else:
      print("Failed to connect, return code %d\n", rc)
  # Set Connecting Client ID
  client = mqtt_client.Client(client_id)
  client.username_pw_set("Admin", "Admin")
  client.on_connect = on_connect
  client.connect(broker, port)
  return client

def publish(client, topic, msg, qos, retain):
  result = client.publish(topic, msg, qos, retain)
  status = result[0]
  if status == 0:
    print(f"Topic: `{topic}`, QOS: `{qos}`, Retained: `{retain}`")
    print(f"Published `{msg}`")
  else:
    print(f"Failed to send message to topic {topic}")

def compileTasmotaDict(tasIpAddr: str, tasCommand: str, baseDict: dict):
  cmdBasePath = 'http://' + tasIpAddr + '/cm?cmnd=' + tasCommand
  response = requests.get(cmdBasePath)
  response.raise_for_status()
  jsonResponse = response.json()
  commandDict = { tasCommand : {}}
  baseDict[tasIpAddr].update(commandDict)
  baseDict[tasIpAddr][tasCommand].update(jsonResponse)
  return baseDict

def imperativeGeneration(
  commandDict: dict, 
  configDict: dict,
  imperativeFile: str):
  if os.path.isfile(imperativeFile):
    with open(imperativeFile, "r") as imperativeFileObj:
      imperativeData = json.loads(imperativeFileObj.read())
  else:
    imperativeData = { "tasmotas" : {}}
  
  for device in configDict["tasmotas"]:
    baseDict = { str(device) : {} }
    for customCommand in commandDict["CustomBacklog"]:
      indexedData = configDict["tasmotas"][device]
      for item in commandDict["CustomBacklog"][customCommand]:
        indexedData = indexedData[item]
      # print('"' + customCommand + '" : ' + json.dumps(indexedData))
      customCommandDict = {customCommand : indexedData}
      # customCommandDict = { str(customCommand) : {}}
      baseDict[device].update(customCommandDict)
    
    # #Update final output dictionary
    imperativeData["tasmotas"].update(baseDict)
    
    # #Update results to file as JSON
    with open(imperativeFile, "w") as outputfile:
      json.dump(imperativeData, outputfile, indent=2)

def backLogGeneration(
  declaredConfigFile: str,
  pushConfigs: bool):
  client = connect_mqtt()
  client.loop_start()
  if os.path.isfile(declaredConfigFile):
    with open(declaredConfigFile, "r") as declaredConfigFileObj:
      declaredConfigData = json.loads(declaredConfigFileObj.read())
  else:
    declaredConfigData = { "tasmotas" : {}}
  
  for device in declaredConfigData["tasmotas"]:
    backlogStr = str("")

    for backlogCommand in declaredConfigData["tasmotas"][device]:
      backlogStr = backlogStr + " " + str(backlogCommand) + " " + json.dumps(declaredConfigData["tasmotas"][device][backlogCommand]).strip('"') + ";" # + " " + str(imperativeData["tasmotas"][device][backlogCommand] + ";"))

    if pushConfigs == True:
      topic = str("cmnd/" + declaredConfigData["tasmotas"][device]["Topic"] + "/backlog")
      publish(client, topic, backlogStr, 0, False)
        
    else:
      print(device + ": " + backlogStr)


def main(
#input parameters
configFile: str = "",
subnetvar: str = "10.2.4.0/24",
netTimeout: int = 1000,
netRetries: int = 1,
tasmotacommandfile: typer.FileText = typer.Option(..., mode="r"),
imperativeFile: str = "",
declaredFile: str = "",
pollDevices: bool = False,
pushConfigs: bool = False
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
  
  if pollDevices == True:
    if configFile == "":
      print("--configfile option required")
      exit()
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

  if imperativeFile != "":
    if configFile == "":
      print("--configfile option required")
      exit()
    imperativeGeneration(tasmotaCommands, outputData, imperativeFile)
    
  if declaredFile != "":
    backLogGeneration(declaredFile, pushConfigs)

  
if __name__ == "__main__":
  typer.run(main)
