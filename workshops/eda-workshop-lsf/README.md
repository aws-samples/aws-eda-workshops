
# EDA Workshop with IBM Spectrum LSF

## Overview
The CloudFormation templates in this demo deploy a fully functional IBM Spectrum LSF compute cluster with all resources required to run a license-free EDA verification workload on a sample design. This workshop uses the IBM Spectrum LSF Resource Connector feature to dynamically provision AWS compute instances to satisfy workload demand in the LSF queues. 


## Prerequisites
The following is required to run this workshop:

* An AWS account with administrative level access
* Access to LSF installation and binary packages.  Bring your own license or obtain a trial from IBM.
* An Amazon EC2 key pair
* A free subscription to the [AWS FPGA Developer AMI](https://aws.amazon.com/marketplace/pp/B06VVYBLZZ).
* A free subscription to the [Official CentOS 7 x86_64 HVM AMI](https://aws.amazon.com/marketplace/pp/B00O7WM7QW).

## Tutorials
This workshop is broken into two tutorials.  You must complete each tutorial before proceeding to the next.
1. [**Deploy the environment**](docs/deploy-environment.md) In this module, you'll review the architecture and follow step-by-step instructions to deploy the environment using AWS CloudFormation.
1. [**Run EDA workload**](docs/run-workload.md) Finally, you'll submit logic simulations into the queue and watch the cluster grow and shrink as workload flows through the system. 

## Cleanup
In order to avoid unnecessary AWS charges, be sure to delete your resources when you are done.

* Delete the stack
* Delete orphaned EBS volumes.  The FPGA AMI doesn't delete them on instance termination.  See `clean-fpga-ebs-vols.py` or deploy Lambda function in CFn template.









