import requests
import json
import sys

#these 3 lines inject host entry!
#jsontext = '{"ipv4addrs":[{"ipv4addr":"10.128.0.7"}], "name": "rqi-vw-dc02.mediconnect.net", "configure_for_dns": false}'
user = 'username'
password = 'password'
jsontext = '{"ipv4addrs":[{"configure_for_dhcp": false, "ipv4addr":"10.128.30.40"}], "name": "vw-prd-virtlb-internal-selfip.mediconnect.net", "configure_for_dns": false}'
url = 'https://10.143.144.21/wapi/v1.2/record:host'
r = requests.post(url, auth=(user, password), data=jsontext, verify=False)
print r.status_code
print r.content
sys.exit(1)
