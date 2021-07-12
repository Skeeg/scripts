import sys
import json
import csv
import requests

user = str(sys.argv[1])
passwd = str(sys.argv[2])
filep = str(sys.argv[3])
apicAddress = str(sys.argv[4])

field = []
field.append("etherT")
field.append("prot")
field.append("sFromPort")
field.append("sToPort")
field.append("dFromPort")
field.append("dToPort")
field.append("name")
field.append("descr")
field.append("dn")

url = apicAddress+'/api/aaaLogin.json?gui-token-request=yes'
jsontext = '{"aaaUser" : {"attributes" : {"name" : "'+user+'","pwd" : "'+passwd+'"}}}'
r = requests.post(url, auth=(user, passwd), data=jsontext, verify=False)
data = json.loads(r.content)
apicCookie = data['imdata'][0]['aaaLogin']['attributes']['token']
urlChallenge = data['imdata'][0]['aaaLogin']['attributes']['urlToken']
url0 = apicAddress+'/api/node/class/vzBrCP.json?'
url0 = url0+'challenge='+urlChallenge
r0 = requests.get(url0, auth=(user, passwd), verify=False, headers={"Cookie" : "APIC-Cookie="+format(apicCookie)})
data0 = json.loads(r0.content)
textstr = json.dumps(data0['totalCount'])
a0 = textstr.replace('"', '')
index = int((a0))
x0 = []
searchl0 = 'vzBrCP'
attr0 = 'name'
for level0 in range(0, index):
    if json.dumps(data0['imdata'][level0].keys()) == '["'+searchl0+'"]':
        x0.append(json.dumps(data0['imdata'][level0][searchl0]['attributes'][attr0]))

for clist in range(2, len(x0)):
    contract = x0[clist]
    print contract
    url = apicAddress+'/api/aaaLogin.json?gui-token-request=yes'
    jsontext = '{"aaaUser" : {"attributes" : {"name" : "'+user+'","pwd" : "'+passwd+'"}}}'
    r = requests.post(url, auth=(user, passwd), data=jsontext, verify=False)
    data = json.loads(r.content)
    apicCookie = data['imdata'][0]['aaaLogin']['attributes']['token']
    urlChallenge = data['imdata'][0]['aaaLogin']['attributes']['urlToken']
    url = apicAddress+'/api/node/class/fvRsCons.json?query-target-filter=and(eq(fvRsCons.tnVzBrCPName,'+contract+'))'
    url = url+'&challenge='+urlChallenge
    r1 = requests.get(url, auth=(user, passwd), verify=False, headers={"Cookie" : "APIC-Cookie="+format(apicCookie)})
    data1 = json.loads(r1.content)
    textstr = json.dumps(data1['totalCount'])
    searchl1 = 'fvRsCons'
    if textstr == '"0"':
        provurl = apicAddress+'/api/node/class/fvRsProv.json?query-target-filter=and(eq(fvRsProv.tnVzBrCPName,'+contract+'))'
        provurl = provurl+'&challenge='+urlChallenge
        r1 = requests.get(provurl, auth=(user, passwd), verify=False, headers={"Cookie" : "APIC-Cookie="+format(apicCookie)})
        data1 = json.loads(r1.content)
        textstr = json.dumps(data1['totalCount'])
        searchl1 = 'fvRsProv'
    a = textstr.replace('"', '')
    index = int((a))
    x1 = []
    searchl1 = 'fvRsCons'
    attr1 = 'tDn'
    for level1 in range(0, index):
        if json.dumps(data1['imdata'][level1].keys()) == '["'+searchl1+'"]':
            x1.append(json.dumps(data1['imdata'][level1][searchl1]['attributes'][attr1]))
    #Dig Deeper
    b = x1[0].replace('"', '')
    url2 = apicAddress+'/api/node/mo/'+b+'.json?query-target=children'
    url2 = url2+'&challenge='+urlChallenge
    r2 = requests.get(url2, auth=(user, passwd), verify=False, headers={"Cookie" : "APIC-Cookie="+format(apicCookie)})
    data2 = json.loads(r2.content)
    textstr = json.dumps(data2['totalCount'])
    a2 = textstr.replace('"', '')
    index2 = int((a2))
    x2 = []
    searchl2 = 'vzSubj'
    attr2 = 'dn'
    for level2 in range(0, index2):
        if json.dumps(data2['imdata'][level2].keys()) == '["'+searchl2+'"]':
            x2.append(json.dumps(data2['imdata'][level2][searchl2]['attributes'][attr2]))
    #Dig Deeper, Deeper Down
    #/api/node/mo/uni/tn-VERSCEND/brc-AD-REPLICATION-INBOUND/subj-Subject.json?query-target=children
    x3 = []
    for y3 in range(0, len(x2)):
        b3 = x2[y3].replace('"', '')
        url3 = apicAddress+'/api/node/mo/'+b3+'.json?query-target=children'
        url3 = url3+'&challenge='+urlChallenge
        r3 = requests.get(url3, auth=(user, passwd), verify=False, headers={"Cookie" : "APIC-Cookie="+format(apicCookie)})
        data3 = json.loads(r3.content)
        textstr = json.dumps(data3['totalCount'])
        a3 = textstr.replace('"', '')
        index3 = int((a3))
        searchl3 = 'vzRsSubjFiltAtt'
        attr3 = 'tDn'
        for level3 in range(0, index3):
            if json.dumps(data3['imdata'][level3].keys()) == '["'+searchl3+'"]':
                x3.append(json.dumps(data3['imdata'][level3][searchl3]['attributes'][attr3]))
    #Way, way down
    #example /api/node/mo/uni/tn-common/flt-AD-CLIENT-to-SERVER.xml?query-target=children
    filen = filep+contract.replace('"', '')+'.csv'
    with open(filen, 'w+b') as csvfile:
        spamwriter = csv.writer(csvfile, quoting=csv.QUOTE_ALL)
        spamwriter.writerow([field[0]]+[field[1]]+[field[2]]+[field[3]]+[field[4]]+[field[5]]+[field[6]]+[field[7]]+[field[8]])
    x4 = []
    for y4 in range(0, len(x3)):
        b4 = x3[y4].replace('"', '')
        url4 = apicAddress+'/api/node/mo/'+b4+'.json?query-target=children'
        url4 = url4+'&challenge='+urlChallenge
        r4 = requests.get(url4, auth=(user, passwd), verify=False, headers={"Cookie" : "APIC-Cookie="+format(apicCookie)})
        data4 = json.loads(r4.content)
        textstr = json.dumps(data4['totalCount'])
        a4 = textstr.replace('"', '')
        index4 = int((a4))
        searchl4 = 'vzEntry'
        attr4 = 'dn'
        #When I snap my fingers, you will wake up
        for level4 in range(0, index4):
            if json.dumps(data4['imdata'][level4].keys()) == '["'+searchl4+'"]':
                x4.append(json.dumps(data4['imdata'][level4][searchl4]['attributes']))
                #meat = []
                #for level5 in range(0, int(len(field))):
                    #meat.append(json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[level5]]))
                with open(filen, 'a+b') as csvfile:
                    writer = csv.writer(csvfile, quoting=csv.QUOTE_ALL)
                    writer.writerow([json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[0]]).replace('"', '')]+
                                    [json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[1]]).replace('"', '')]+
                                    [json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[2]]).replace('"', '')]+
                                    [json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[3]]).replace('"', '')]+
                                    [json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[4]]).replace('"', '')]+
                                    [json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[5]]).replace('"', '')]+
                                    [json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[6]]).replace('"', '')]+
                                    [json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[7]]).replace('"', '')]+
                                    [json.dumps(data4['imdata'][level4][searchl4]['attributes'][field[8]]).replace('"', '')])
