import requests
import urllib.parse 

curlString = 'Backlog Hostname BasementFridge; DeviceName BasementFridge; FriendlyName1 Basement Fridge; Topic BasementFridge; SwitchMode 3; PowerRetain ON; SensorRetain ON; SetOption19 ON; SerialLog 0; Template {"NAME": "W-US002S", "GPIO": [0, 192, 0, 288, 2688, 2656, 0, 0, 2592, 289, 224, 0, 0, 0], "FLAG": 0, "BASE": 45}; Module 0; GroupTopic1 tasmotas; GroupTopic2 ; GroupTopic3 ; GroupTopic4 ; Timer1 {"Enable": 0, "Mode": 0, "Time": "00:00", "Window": 0, "Days": "0000000", "Repeat": 0, "Output": 1, "Action": 0}; Timer2 {"Enable": 0, "Mode": 0, "Time": "00:00", "Window": 0, "Days": "0000000", "Repeat": 0, "Output": 1, "Action": 0}; Timer3 {"Enable": 0, "Mode": 0, "Time": "00:00", "Window": 0, "Days": "0000000", "Repeat": 0, "Output": 1, "Action": 0}; Timer4 {"Enable": 0, "Mode": 0, "Time": "00:00", "Window": 0, "Days": "0000000", "Repeat": 0, "Output": 1, "Action": 0}; Timers OFF; Rule1 on Switch1#state do Publish homeassistant/cmnd/%topic%/POWER 1 endon; Rule ON;'
sanityUri = 'http://10.2.4.40/cm?cmnd=' + urllib.parse.quote_plus(curlString)
print(sanityUri)
r = requests.get(sanityUri)
print(r.raise_for_status())
