import boto3

ec2 = boto3.client('ec2')
# lookuplist = ["10.107.150.187", "10.107.145.11", "10.107.145.177", "10.107.2.23", "10.107.159.158", "10.107.156.155", "10.107.236.31", "10.107.158.119", "10.107.145.102", "10.107.154.97", "10.107.6.72", "10.107.153.105", "10.133.12.46", "10.107.171.13", "10.107.188.217", "10.107.150.120", "10.107.154.9", "10.107.159.14", "10.107.157.75", "10.107.183.103", "10.107.148.175", "10.107.149.164", "10.133.16.147", "10.107.6.208", "10.107.216.219", "10.133.35.43", "10.133.56.225", "10.107.163.169", "10.107.238.185", "10.107.149.202", "10.107.6.180", "10.107.238.16", "10.107.153.129", "10.133.50.59", "10.133.54.190", "10.107.166.225", "10.107.153.235", "10.107.159.195", "10.107.148.146", "10.107.187.247", "10.107.152.161", "10.133.53.143", "10.107.150.173", "10.107.159.42", "10.107.144.167", "10.107.155.33", "10.133.21.227", "10.107.223.249", "10.107.144.235", "10.133.23.226"]
lookuplist = ["10.133.24.191"]
SEP = "|"
# for addr in lookuplist:
  # response = ec2.describe_network_interfaces(Filters=[{'Name' : 'addresses.private-ip-address','Values' : [addr]}])
response = ec2.describe_network_interfaces(Filters=[{'Name' : 'addresses.private-ip-address','Values' : lookuplist}])
print(len(response['NetworkInterfaces']))
for i in response['NetworkInterfaces']:
  INSTANCEID = i['Attachment']['InstanceId']
  INSTANCEIP = i['PrivateIpAddress']
  ec2info = ec2.describe_instances(Filters=[{'Name' : 'instance-id','Values' : [INSTANCEID]}])
  ec2tags = ec2info['Reservations'][0]['Instances'][0]['Tags']
  tagmap = {}
  for tag in ec2tags:
    tagDict = {tag['Key'] : tag['Value']}
    tagmap.update(tagDict)
  BC = str(tagmap.get('bc'))
  TEAM = str(tagmap.get('team'))
  SOURCE = str(tagmap.get('source'))
  NAME = str(tagmap.get('Name'))
  CREATOR = str(tagmap.get('creator'))
  RESPORTSTRING = INSTANCEIP + SEP + INSTANCEID + SEP + BC + SEP + TEAM + SEP + SOURCE + SEP + NAME + SEP + CREATOR
  print(RESPORTSTRING)
