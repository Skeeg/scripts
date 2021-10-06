import xmltodict
import requests
import sys
key = 'apikey'
device = '192.168.100.85'
#All Interfaces Counters
#uri = 'https://'+device+'/api/?type=op&cmd=%3Cshow%3E%3Ccounter%3E%3Cinterface%3Eall%3C/interface%3E%3C/counter%3E%3C/show%3E&key='+key
#rest_request = requests.get(uri, verify=False)
#doc = xmltodict.parse(rest_request.text)
#for i in range(len(doc['response']['result']['ifnet']['ifnet']['entry'])):
    #j = 'OK | '
    #j += 'iface'+(doc['response']['result']['ifnet']['ifnet']['entry'][i].get('name'))
    #j += '_ibytes='+(doc['response']['result']['ifnet']['ifnet']['entry'][i].get('ibytes'))
    #j += 'iface'+(doc['response']['result']['ifnet']['ifnet']['entry'][i].get('name'))
    #j += '_obytes='+(doc['response']['result']['ifnet']['ifnet']['entry'][i].get('obytes'))
    #print(j)

#All Interfaces
uri = 'https://'+device+'/api/?type=op&cmd=%3Cshow%3E%3Cinterface%3Eall%3C%2Finterface%3E%3C%2Fshow%3E&key='+key
rest_request = requests.get(uri, verify=False)
doc = xmltodict.parse(rest_request.text)
for i in range(len(doc['response']['result']['ifnet']['entry'])):
    interface = doc['response']['result']['ifnet']['entry'][i].get('name')
    zone = doc['response']['result']['ifnet']['entry'][i].get('zone')
    if zone is None:
        zone = 'nullzone'
    uri2 = 'https://'+device+'/api/?type=op&cmd=%3Cshow%3E%3Ccounter%3E%3Cinterface%3E'+interface+'%3C/interface%3E%3C/counter%3E%3C/show%3E&key='+key
    rest_request2 = requests.get(uri2, verify=False)
    doc2 = xmltodict.parse(rest_request2.text)
    if 'ifnet' in doc2['response']['result']['ifnet'].keys():
        l = 'OK | '
        l += 'zone_-'+zone+'-_iface_-'+interface+'-_ibytes='+(doc2['response']['result']['ifnet']['ifnet']['entry'].get('ibytes'))+'Bc'
        l += ' zone_-'+zone+'-_iface_-'+interface+'-_obytes='+(doc2['response']['result']['ifnet']['ifnet']['entry'].get('obytes'))+'Bc'
        print(l)
    else:
        l = 'OK | '
        l += 'zone_-'+zone+'-_iface_-'+interface+'-_rx-bytes='+(doc2['response']['result']['ifnet'].get('rx-bytes'))+'Bc'
        l += ' zone_-'+zone+'-_iface_-'+interface+'-_tx-bytes='+(doc2['response']['result']['ifnet'].get('tx-bytes'))+'Bc'
        print(l)
sys.exit(0)
