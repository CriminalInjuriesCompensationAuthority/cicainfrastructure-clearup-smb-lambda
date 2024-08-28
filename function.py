import json
import boto3
import glob
import os
import base64
from botocore.exceptions import ClientError
from shutil import rmtree
import smbclient
from smbclient.path import (isdir, exists)
from smbclient.shutil import rmtree
from pathlib import Path

def lambda_handler(event,context):
    # Get SMB Fileshare secret from AWS Secrets Manager
    secret = get_secret("lambda-smb-secrets")

    # Parse JSON key value pairs.
    jsonString = json.loads(secret)
    username = jsonString["username"]
    password = jsonString["password"]
    host = jsonString["host"]
    destShare = jsonString["share"]

    try:
        #destDir = event["directory"] Remove DesDir to point to root of Share. Add for specific directory
        pattern = event["pattern"]    
    except:
        #destDir = "Test"
        pattern = "DELETE"

    destDirectoryPath = os.path.join(host, destShare ) #destDir removed from end of path

    try:
        smbclient.register_session(server=host, username=username, password=password)
    except:
        print("Error establishing session")

    try: # Check for file matching pattern and delete parent directory containing it.
        for root, dirs, files in smbclient.walk(destDirectoryPath):
            for name in files:
                if name == (pattern):
                    print(f"Deleting \n {root}")
                    smbclient.shutil.rmtree(root)

    except Exception as e: 
        print(f"Error deleting directory {e}")
    smbclient.reset_connection_cache()
    return "Successfully cleared directories on {}".format(destDirectoryPath)

def get_secret(secret_name):

    region_name = os.environ['AWS_REGION']

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )

    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
    else:
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            return secret
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
            return decoded_binary_secret
