# Deploy an LSF-based EDA Computing Environment

## Overview

This workshop shows you how to deploy a fully functional compute cluster based on IBM Spectrum LSF. The environment includes all resources required to run a license-free EDA verification workload on a sample design. Using standard LSF commands, you will be able to submit front-end verification workload into the queue and observe as LSF dynamically adds and removes compute resources as the jobs flow through the system.

This tutorial is for IT, CAD, and design engineers who are interested in running EDA workloads in the cloud using IBM's LSF Spectrum workload and resource management software.

### IBM Spectrum LSF on AWS

The Resource Connector feature for IBM Spectrum LSF enables LSF clusters to dynamically provision and deprovision right-sized AWS compute resources to satisfy pending demand in the queues. These dynamic hosts join the cluster, accept jobs, and are terminated when all demand has been satisfied.  This process happens automatically based on the Resource Connector configuration.

For more information about IBM Spectrum LSF Resource Connector, please see the [official documentation](https://www.ibm.com/support/knowledgecenter/en/SSWRJV_10.1.0/lsf_welcome/lsf_kc_resource_connector.html) on the IBM website.

### Cost and Licenses

You are responsible for the cost of the AWS services used while running this reference deployment. There is no additional cost for using this tutorial.

The AWS CloudFormation template for this tutorial includes configuration parameters that you can customize. Some of these settings, such as instance type, will affect the cost of deployment. For cost estimates, see the pricing pages for each AWS service you will be using. Prices are subject to change.

This tutorial requires a license for IBM Spectrum LSF. If you have available LSF licenses for your on-prem clusters, check with your IBM sale representative to be sure you are entitled to use these licenses for cloud-based LSF clusters.

If you don’t have available LSF licenses, you can use a [trial version of LSF](https://www.ibm.com/account/reg/us-en/signup?formid=urx-31573), which allows up to 90 days of free usage in a non-production environment.

## Planning the Deployment

### Specialised Knowledge

This tutorial assumes familiarity with networking, the Linux command line, and EDA workflows. Additionally, intermediate-level experience with NFS storage and LSF operations will be helpful.

This deployment guide also requires a moderate level of familiarity with AWS services. If you’re new to AWS, visit the Getting Started Resource Center and the AWS Training and Certification website for materials and programs that can help you develop the skills to design, deploy, and operate your infrastructure and applications on the AWS Cloud.

### AWS Account

If you don’t already have an AWS account, create one at https://aws.amazon.com by following the on-screen instructions. Part of the sign-up process involves receiving a phone call and entering a PIN using the phone keypad.
Your AWS account is automatically signed up for all AWS services. You are charged only for the services you use.

### Technical Requirements

Before you launch this tutorial, your account must be configured as specified in the following table. Otherwise, deployment might fail.


## Workshop Architecture

Deploying this cluster in a new virtual private cloud (VPC) with default parameters builds the following EDA computing environment in the AWS Cloud.

![diagram](images/eda-lsf-workshop-diagram-3.png "diagram")

The tutorial sets up the following:

- A VPC configured with public and private subnets to provide you with your own virtual network on AWS.*
- In the public subnet,a managed NAT gateway to allow outbound internet access for resources in the private subnets.
- In the public subnet, a Linux login/submission host to allow inbound Secure Shell (SSH) access to the environment.
- In the private subnet, an LSF master running IBM Spectrum LSF with the Resource Connector feature enabled, Amazon EC2 compute instances that are dynamically provisioned by LSF, and a Linux-based NFS server for runtime scratch data.
- An Amazon Elastic File System (EFS) file system for the LSF distribution and configuration files.

\* The template that deploys the tutorial into an existing VPC skips the components marked by asterisks and prompts you for your existing VPC configuration.

## Deployment Options

This tutorial provides two deployment options:

- **Deploy the cluster into a new VPC**. This option builds a new AWS environment consisting of the VPC, subnets, NAT gateways, security groups, NFS server, LSF master, and other infrastructure components, and then deploys LSF into this new VPC.

- **Deploy the cluster into an existing VPC**. This option provisions the cluster in an existing VPC.

This tutorial provides separate CloudFormation templates for these options. It also lets you configure CIDR blocks, instance types, and other settings, as discussed later in this guide.

## Deployment Steps

### Step 1. Sign in to your AWS account

1. Sign in to your AWS account at <https://aws.amazon.com> with an IAM user role that includes full administrative permissions. For details, see [Planning the deployment] (#planning-the-deployment) earlier in this guide.

2. Make sure that your AWS account is configured correctly, as discussed in the [Technical requirements](#technical-requirements) section.

### Step 2. Subscribe to the Required AMIs

This workshop requires a subscription to the following AMIs in AWS Marketplace. AMIs are images that are used to boot the virtual servers (instances) in AWS. They also contain software required to run the workshop.  There is no additional cost to use these AMIs.

- AWS FPGA Developer AMI
- Official CentOS 7 x86_64 HVM AMI

Sign in to your AWS account, and follow these instructions to subscribe:

1. Open the page for the [AWS FPGA Developer AMI](https://aws.amazon.com/marketplace/pp/B06VVYBLZZ) AMI in AWS Marketplace, and then choose **Continue to Subscribe**.

1. Review the terms and conditions for software usage, and then choose **Accept Terms**. You will get a confirmation page, and an email confirmation will be sent to the account owner. For detailed subscription instructions, see the [AWS Marketplace documentation](https://aws.amazon.com/marketplace/help/200799470).

1. When the subscription process is complete, exit out of AWS Marketplace without further action. **Do not** click **Continue to Launch**; the workshop CloudFormation templates will deploy the AMI for you.

1. Repeat the steps 1 through 3 to subscribe to the [Official CentOS 7 x86_64 HVM AMI](https://aws.amazon.com/marketplace/pp/B00O7WM7QW) AMI.

### Step 3. Launch the Cluster

1. Sign in to your AWS account, and choose one of the following options to launch the AWS CloudFormation template. For help choosing an option, see [deployment options](#_Automated_Deployment) earlier in this guide.

    **Important:** If you're deploying the cluster into an existing VPC, make sure that your VPC has two private subnets, and that the subnets aren't shared. This tutorial doesn't support [shared subnets](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-sharing.html). The Cloudformation template will create a NAT Gateway [NAT gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) in their route tables, to allow the instances to download packages and software without exposing them to the internet. You will also need the domain name option configured in the DHCP options as explained in the [Amazon VPC documentation](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_DHCP_Options.html). You will be prompted for your VPC settings when you launch the workshop's CloudFormation template.

1. Check the region that's displayed in the upper-right corner of the navigation bar, and change it if necessary. This is where the cluster infrastructure will be built. The template is launched in the US East (Ohio) Region by default.

    | Deploy into New VPC  | Deploy into Existing VPC |
    | :---: | :---: |
    | [![Launch Stack](../../../shared/images/deploy_to_aws.png)](../templates/cfn.yaml)|[![Launch Stack](../../../shared/images/deploy_to_aws.png)](../templates/cfn.yaml)|

    Each deployment takes about 30 minutes to complete.

    **Note:**  This deployment includes Amazon EFS and Amazon FSx for Lustre, which are not currently supported in all AWS Regions. For a current list of supported regions, see the [AWS Regions and Endpoints webpage](https://docs.aws.amazon.com/general/latest/gr/rande.html).

1. On the **Select Template** page, keep the default setting for the template URL, and then choose **Next**.

1. On the **Specify Details** page, change the stack name if needed. Review the parameters for the template. Provide values for the parameters that require input. For all other parameters, review the default settings and customize them as necessary. When you finish reviewing and customizing the parameters, choose **Next**.

1. On the **Options** page, you can specify [tags](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-resource-tags.html) (key-value pairs) for resources in your stack and [set advanced options](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-add-tags.html). When you're done, choose **Next**.

1. On the **Review** page, review and confirm the template settings. Under **Capabilities**, select the two check boxes to acknowledge that the template will create IAM resources and that it might require the capability to auto-expand macros.

1. Choose **Create** to deploy the stack.

1. Monitor the status of the stack. When the status is **CREATE\_COMPLETE**, the cluster is ready.

1. Use the URLs displayed in the **Outputs** tab for the stack to view the resources that were created.

Figure 2: \<software\> outputs after successful deployment

### Step 4. Test the Deployment

