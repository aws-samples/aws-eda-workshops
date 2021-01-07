# Requires python 3.6.
#
# This is example Lambda code for deleting orphaned EBS volumes that are created by
# the AWS FPGA AMI.
# WARNING:
# THIS SCRIPT WILL DELETE EBS VOLUMES. PLEASE TEST BEFORE USE.

import boto3
import os
import sys

ec2 = boto3.resource('ec2',region_name='$REGION')

def lambda_handler(event, context):
    for vol in ec2.volumes.all():
        print (vol)
        if  vol.state=='available':
            if vol.tags is None:
                print ("No tag. Skipping " +vol.id)
                continue
            for tag in vol.tags:
                if tag['Key'] == '$mykey':
                    value=tag['Value']
                    if value == '$myvalue' and vol.state=='available':
                        vid=vol.id
                        v=ec2.Volume(vol.id)
                        print ("Deleting", vid, "based on tag", value, ".")
                        #v.delete()
