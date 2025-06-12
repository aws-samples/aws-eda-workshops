
# EDA Workshop with IBM Spectrum LSF

## Overview

The CloudFormation templates in this workshop deploy a fully functional IBM Spectrum LSF compute cluster with all resources and tools required to run an EDA verification workload on a sample design in the AWS Cloud. This workshop uses the IBM Spectrum LSF Resource Connector feature to dynamically provision AWS compute instances to satisfy workload demand in the LSF queues.

![workflow](docs/images/eda-lsf-workshop-workflow.png)

## Prerequisites

The following is required to run this workshop:

* An AWS account with administrative level access
* Licenses for IBM Spectrum LSF 10.1
* An IBM Passport Advantage account for downloading the installation and full Linux distribution packages for IBM Spectrum LSF 10.1 Standard or Advanced Edition and a corresponding entitlement file.
* An Amazon EC2 key pair
* A free subscription to the [Rocky Linux 8 (Official)](https://aws.amazon.com/marketplace/pp/prodview-2otariyxb3mqu).


## Tutorials

This workshop consists of two tutorials.  You must complete the tutorials in sequence.

1. [**Deploy the environment**](docs/deploy-environment.md) In this module, you'll review the architecture and follow step-by-step instructions to deploy the environment using AWS CloudFormation.

1. [**Run EDA workload**](docs/run-workload.md) Finally, you'll submit logic simulations into the queue and watch the cluster grow and shrink as workload flows through the system.

## Costs

You are responsible for the cost of the AWS services used while running workshop deployment.
The AWS CloudFormation templates for this workshop include configuration parameters that you can customize. Some of these settings, such as instance type, will affect the cost of deployment. For cost estimates, see the pricing pages for each AWS service you will be using. Prices are subject to change.

> **Tip**  
After you deploy the workshop, we recommend that you enable the AWS Cost and Usage Report to track costs associated with the workshop. This report delivers billing metrics to an S3 bucket in your account. It provides cost estimates based on usage throughout each month, and finalizes the data at the end of the month. For more information about the report, see the AWS documentation.

### Clean up

* Delete the parent stack
* Delete orphaned EBS volumes.
