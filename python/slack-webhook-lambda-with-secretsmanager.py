#!/usr/bin/python3.8
import urllib3
import json
import boto3
# import base64
import logging
import os
from botocore.exceptions import ClientError

http = urllib3.PoolManager()

SECRET_NAME = os.environ.get('SECRET_NAME')
SECRET_KEY = os.environ.get('SECRET_KEY')
REGION_NAME = os.environ.get('REGION_NAME')
ICON_EMOJI = os.environ.get('ICON_EMOJI')
SLACK_CHANNEL = os.environ.get('SLACK_CHANNEL')
SLACK_USERNAME = os.environ.get('SLACK_USERNAME')
ENVIRONMENT = os.environ['ENVIRONMENT']

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_secret(SECRET_NAME, SECRET_KEY, REGION_NAME):

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=REGION_NAME
    )

    # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=SECRET_NAME
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            logger.error("Secrets Manager can't decrypt the protected secret text using the provided KMS key.")
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            logger.error("An error occurred on the server side.")
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            logger.error("You provided an invalid value for a parameter.")
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            logger.error("You provided a parameter value that is not valid for the current state of the resource.")
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            logger.error("We can't find the resource that you asked for.")
            raise e
    else:
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
        # else:
        #     decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
    fullsecret = json.loads(secret)
    secretvalue = fullsecret[SECRET_KEY]
    return secretvalue

def lambda_handler(event, context):
    logger.info("Event: " + str(event))
    cloudwatch_message = json.loads(str(event['Records'][0]['Sns']['Message']))
    logger.info("Message: " + str(cloudwatch_message))

    cloudwatch_alert_region = event['Records'][0]['EventSubscriptionArn'].split(":")[3]
    region = cloudwatch_message['Region']
    alarm_name = cloudwatch_message['AlarmName']
    old_state = cloudwatch_message['OldStateValue']
    new_state = cloudwatch_message['NewStateValue']
    reason = cloudwatch_message['NewStateReason']
    
    if new_state == "ALARM":
        color = "danger"
    elif new_state == "OK":
        color = "good"
    elif new_state == "INSUFFICIENT_DATA":
        color = "warning"
    else:
        color = "0080FF"

    slack_cloudwatch_message = {
        'channel': SLACK_CHANNEL,
        'username': SLACK_USERNAME,
        "icon_emoji": ICON_EMOJI,
        'title': alarm_name,
        'text': "%s: %s in %s" % (new_state, alarm_name, region),
        "attachments": [
            {
                'color': color,
                "title": alarm_name,
                "title_link": "https://console.aws.amazon.com/cloudwatch/home?region=" + cloudwatch_alert_region + "#alarm:alarmFilter=ANY;name=" + alarm_name,
                "text": "%s" % (reason),
                "fields": [
                    {
                        "title": "Current State",
                        "value": new_state,
                        "short": True
                    },
                    {
                        "title": "Previous State",
                        "value": old_state,
                        "short": True
                    },
                    {
                        "title": "Region",
                        "value": region,
                        "short": True
                    },
                    {
                        "title": "Environment",
                        "value": ENVIRONMENT.upper(),
                        "short": True
                    }
                ],
            }
        ]
    }

    hook_url = get_secret(SECRET_NAME, SECRET_KEY, REGION_NAME)
    encoded_msg = json.dumps(slack_cloudwatch_message).encode('utf-8')
    
    try:
        http.request('POST', hook_url, body=encoded_msg)
        logger.info("Message posted to %s", slack_cloudwatch_message['channel'])
    except urllib3.exceptions.HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)

# Test Data:
# {
#   "Records": [
#     {
#       "EventSource": "aws:sns",
#       "EventVersion": "1.0",
#       "EventSubscriptionArn": "arn:aws:sns:eu-west-1:000000000000:cloudwatch-alarms:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#       "Sns": {
#         "Type": "Notification",
#         "MessageId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#         "TopicArn": "arn:aws:sns:eu-west-1:000000000000:cloudwatch-alarms",
#         "Subject": "ALARM: \"Example alarm name\" in EU - Ireland",
#         "Message": "{\"AlarmName\":\"Example alarm name\",\"AlarmDescription\":\"Example alarm description.\",\"AWSAccountId\":\"000000000000\",\"NewStateValue\":\"ALARM\",\"NewStateReason\":\"Threshold Crossed: 1 datapoint (10.0) was greater than or equal to the threshold (1.0).\",\"StateChangeTime\":\"2017-01-12T16:30:42.236+0000\",\"Region\":\"EU - Ireland\",\"OldStateValue\":\"OK\",\"Trigger\":{\"MetricName\":\"DeliveryErrors\",\"Namespace\":\"ExampleNamespace\",\"Statistic\":\"SUM\",\"Unit\":null,\"Dimensions\":[],\"Period\":300,\"EvaluationPeriods\":1,\"ComparisonOperator\":\"GreaterThanOrEqualToThreshold\",\"Threshold\":1.0}}",
#         "Timestamp": "2017-01-12T16:30:42.318Z",
#         "SignatureVersion": "1",
#         "Signature": "Cg==",
#         "SigningCertUrl": "https://sns.eu-west-1.amazonaws.com/SimpleNotificationService-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.pem",
#         "UnsubscribeUrl": "https://sns.eu-west-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-1:000000000000:cloudwatch-alarms:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#         "MessageAttributes": {}
#       }
#     }
#   ]
# }
