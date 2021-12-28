#!/bin/python3
import boto3

audittingBucket = 'bucket'
conn = boto3.client('s3')  # again assumes boto.cfg setup, assume AWS S3
s3 = boto3.resource('s3')

# s3Obj = s3.Object(audittingBucket,"file.json")
# print(s3Obj.server_side_encryption)

allObjects = conn.list_objects(Bucket=audittingBucket)
bucketEncryption = conn.get_bucket_encryption(Bucket=audittingBucket)
for key in allObjects['Contents']:
    # print(key['Key'])
    s3Obj = s3.Object(audittingBucket,key)
# print(allObjects)
# print(bucketEncryption['ServerSideEncryptionConfiguration']['Rules'][0]['ApplyServerSideEncryptionByDefault']['SSEAlgorithm'])
# for item in allObjects['Contents']:
#   print(item)
