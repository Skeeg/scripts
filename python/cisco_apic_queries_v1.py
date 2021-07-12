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
for tenant in tenants:
    print('Tenant:'+tenant.name)
    print('')
    #print(str(tenant.get_json()))
    print('')
    apps = tenant.get_children(only_class=AppProfile)
    for app in apps:
        print('App: '+app.name)
        print('')
        #print(str(app.get_json()))
        epgs = app.get_children()
        for epg in epgs:
            print('EPG: '+epg.name)
            #print(str(epg.get_json()))
            print('')
            print('##Consumed Contracts for EPG##')
            print('')
            ccontracts = epg.get_all_consumed()
            if not ccontracts:
                print('No Contracts')
            else:
                for ccontract in ccontracts:
                    #print(str(ccontract.get_json()))
                    print('Consumed Contract: '+ccontract.name)
                    csubjects = ccontract.get_children(only_class=ContractSubject)
                    if not psubjects:
                        print('No Subjects')
                    else:
                        for csubject in csubjects:
                            print('Contract Subject: '+csubject.name)
                            cfilter_entries = csubject.get_filters()
                            if not cfilter_entries:
                                print('No Filters')
                            else:
                                for cfe in cfilter_entries:
                                    print('Filter: '+cfe.name)
                            print('')
                        #print('')
                    #print('')
            print('')
            print('##Provided Contracts for EPG##')
            print('')
            pcontracts = epg.get_all_provided()
            if not pcontracts:
                print('No Contracts')
            else:
                for pcontract in pcontracts:
                    #print(str(pcontract.get_json()))
                    print('Provided Contract: '+pcontract.name)
                    psubjects = pcontract.get_children(only_class=ContractSubject)
                    if not psubjects:
                        print('No Subjects')
                    else:
                        for psubject in psubjects:
                            print('Contract Subject: '+psubject.name)
                            pfilter_entries = psubject.get_filters()
                            if not pfilter_entries:
                                print('No Filters')
                            else:
                                for pfe in pfilter_entries:
                                    print('Filter: '+pfe.name)
                            print('')
                        #print('')
                    #print('')
            print('')

