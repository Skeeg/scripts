from acitoolkit import *
import json

description = ('Simple application that logs on to the APIC'
               ' and queries data.')
creds = Credentials('apic', description)
args = creds.get()
session = Session(args.url, args.login, args.password)
resp = session.login()

if not resp.ok:
    print('%% Could not login to APIC')

tenants = Tenant.get_deep(session)
#for tenant in tenants:
    #print('#################Tenant: '+tenant.name)
    #print json.dumps(tenant.get_json(), sort_keys=True, indent=2, separators=(',',':'))
print json.dumps(tenants[3].get_json())
    #print tenant.get_json()
    #print('#End Tenant: '+tenant.name+'################')
    #print('#################Tenant : '+tenant.name+' Filters')
    #filterEntries = tenant.get_children(Filter)
    #for fe in filterEntries:
        #print json.dumps(fe.get_json(), sort_keys=True, indent=2, separators=(',',':'))
        #print fe.get_json()
    #print('#End Tenant : '+tenant.name+' Filters################')
