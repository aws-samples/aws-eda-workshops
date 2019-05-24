# Deploy cluster

## Workshop Architecture

![diagram](images/eda-lsf-workshop-diagram-3.png "diagram")

## Deployment Options

This tutorial provides two deployment options:

- **Deploy the cluster into a new VPC (end-to-end deployment)**. This option builds a new AWS environment consisting of the VPC, subnets, NAT gateways, security groups, NFS server, LSF master, and other infrastructure components, and then deploys \<software\> into this new VPC.

- **Deploy the cluster into an existing VPC**. This option provisions the cluster in an existing VPC.

This tutorial provides separate templates for these options. It also lets you configure CIDR blocks, instance types, and other settings, as discussed later in this guide.

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

### Step 3. Launch the Quick Start


**Notes** The instructions in this section reflect the older version of
the AWS CloudFormation console. If you're using the redesigned console,
some of the user interface elements might be different.

You are responsible for the cost of the AWS services used while running
this Quick Start reference deployment. There is no additional cost for
using this Quick Start. For full details, see the pricing pages for each
AWS service you will be using in this Quick Start. Prices are subject to
change.

1.  Sign in to your AWS account, and choose one of the following options
    to launch the AWS CloudFormation template. For help choosing an
    option, see [deployment options](#_Automated_Deployment) earlier in
    this guide.

  ---------------------------------------------------------------------------- ---------------------------------------------------------------------------------
  [Deploy \<software\> into a\                                                 [Deploy \<software\> into an\
  new VPC on AWS](file:///C:\Users\handans\Desktop\new%20doc%20template\tbd)   existing VPC on AWS](file:///C:\Users\handans\Desktop\new%20doc%20template\tbd)

  ---------------------------------------------------------------------------- ---------------------------------------------------------------------------------

**Important** If you're deploying \<software\> into an existing VPC,
make sure that your VPC has two private subnets in different
Availability Zones for the workload instances, and that the subnets
aren't shared. This Quick Start doesn't support [shared
subnets](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-sharing.html).
These subnets require [NAT
gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
in their route tables, to allow the instances to download packages and
software without exposing them to the internet. You will also need the
domain name option configured in the DHCP options as explained in the
[Amazon VPC
documentation](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_DHCP_Options.html).
You will be prompted for your VPC settings when you launch the Quick
Start.

Each deployment takes about \<x\> hours to complete.

3.  Check the region that's displayed in the upper-right corner of the
    navigation bar, and change it if necessary. This is where the
    network infrastructure for \<software\> will be built. The template
    is launched in the US East (Ohio) Region by default.

**Note** This deployment includes Amazon EFS, which isn't currently
supported in all AWS Regions. For a current list of supported regions,
see the [AWS Regions and Endpoints
webpage](https://docs.aws.amazon.com/general/latest/gr/rande.html#elasticfilesystem-region).

4.  On the **Select Template** page, keep the default setting for the
    template URL, and then choose **Next**.

5.  On the **Specify Details** page, change the stack name if needed.
    Review the parameters for the template. Provide values for the
    parameters that require input. For all other parameters, review the
    default settings and customize them as necessary.

    In the following tables, parameters are listed by category and
    described separately for the two deployment options:

-   [Parameters for deploying \<software\> into a new
    VPC](#option-1-parameters-for-deploying-software-into-a-new-vpc)

-   [Parameters for deploying \<software\> into an existing
    VPC](#option-2-parameters-for-deploying-software-into-an-existing-vpc)

    When you finish reviewing and customizing the parameters, choose
    **Next**.

### Option 1: Parameters for deploying \<software\> into a new VPC

[View template](https://s3.amazonaws.com/quickstart-reference/)

> *VPC network configuration:*

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Parameter label (name)   Default            Description
  ------------------------ ------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Availability Zones\      *Requires input*   The list of Availability Zones to use for the subnets in the VPC. The Quick Start uses two Availability Zones from your list and preserves the logical order you specify.
  (AvailabilityZones)                         

  VPC CIDR\                10.0.0.0/16        The CIDR block for the VPC.
  (VPCCIDR)                                   

  Private subnet 1 CIDR\   10.0.0.0/19        The CIDR block for the private subnet located in Availability Zone 1.
  (PrivateSubnet1CIDR)                        

  Private subnet 2 CIDR\   10.0.32.0/19       The CIDR block for the private subnet located in Availability Zone 2.
  (PrivateSubnet2CIDR)                        

  Public subnet 1 CIDR\    10.0.128.0/20      The CIDR block for the public subnet located in Availability Zone 1.
  (PublicSubnet1CIDR)                         

  Public subnet 2 CIDR\    10.0.144.0/20      The CIDR block for the public subnet located in Availability Zone 2.
  (PublicSubnet2CIDR)                         

  Permitted IP range\      *Requires input*   The CIDR IP range that is permitted to access \<software\>. We recommend that you set this value to a trusted IP range. For example, you might want to grant only your corporate network access to the software.
  (AccessCIDR)                                
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

> *Amazon EC2 configuration:*

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Parameter label (name)   Default            Description
  ------------------------ ------------------ -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Key pair name\           *Requires input*   A public/private key pair, which allows you to connect securely to your instance after it launches. This is the key pair you created in your preferred region; see the [Technical requirements](#technical-requirements) section.
  (KeyPairName)                               

  Parameter label\         *Optional*         Example of optional parameter.
  (ParameterName)                             
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

> *AWS Quick Start configuration:*

**Note** We recommend that you keep the default settings for the
following two parameters, unless you are customizing the Quick Start
templates for your own deployment projects. Changing the settings of
these parameters will automatically update code references to point to a
new Quick Start location. For additional details, see the [AWS Quick
Start Contributor's
Guide](https://aws-quickstart.github.io/option1.html).

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Parameter label (name)        Default                               Description
  ----------------------------- ------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Quick Start S3 bucket name\   aws-quickstart                        The S3 bucket you created for your copy of Quick Start assets, if you decide to customize or extend the Quick Start for your own use. The bucket name can include numbers, lowercase letters, uppercase letters, and hyphens, but should not start or end with a hyphen.
  (QSS3BucketName)                                                    

  Quick Start S3 key prefix\    quickstart-\<company\>-\<product\>/   The [S3 key name prefix](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html) used to simulate a folder for your copy of Quick Start assets, if you decide to customize or extend the Quick Start for your own use. This prefix can include numbers, lowercase letters, uppercase letters, hyphens, and forward slashes.
  (QSS3KeyPrefix)                                                     
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### Option 2: Parameters for deploying \<software\> into an existing VPC

[View template](https://s3.amazonaws.com/quickstart-reference/)

*Network configuration:*

  -----------------------------------------------------------------------------------------------------------------------------------------------
  Parameter label (name)   Default            Description
  ------------------------ ------------------ ---------------------------------------------------------------------------------------------------
  VPC ID\                  *Requires input*   The ID of your existing VPC (e.g., vpc-0343606e).
  (VPCID)                                     

  Private subnet 1 ID\     *Requires input*   The ID of the private subnet in Availability Zone 1 in your existing VPC (e.g., subnet-a0246dcd).
  (PrivateSubnet1ID)                          

  Private subnet 2 ID\     *Requires input*   The ID of the private subnet in Availability Zone 2 in your existing VPC (e.g., subnet-b58c3d67).
  (PrivateSubnet2ID)                          

  Bastion security\        *Requires input*   The ID of the bastion security group in your existing VPC (e.g., sg-7f16e910).
  group ID\                                   
  (BastionSecurityGroup\                      
  ID)                                         
  -----------------------------------------------------------------------------------------------------------------------------------------------

*Amazon EC2 configuration:*

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Parameter label (name)   Default            Description
  ------------------------ ------------------ -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Key pair name\           *Requires input*   A public/private key pair, which allows you to connect securely to your instance after it launches. This is the key pair you created in your preferred region; see the [Technical requirements](#technical-requirements) section.
  (KeyPairName)                               

  Parameter label\         *Optional*         Example of optional parameter.
  (ParameterName)                             
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

> *AWS Quick Start configuration:*

**Note** We recommend that you keep the default settings for the
following two parameters, unless you are customizing the Quick Start
templates for your own deployment projects. Changing the settings of
these parameters will automatically update code references to point to a
new Quick Start location. For additional details, see the [AWS Quick
Start Contributor's
Guide](https://aws-quickstart.github.io/option1.html).

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Parameter label (name)        Default                               Description
  ----------------------------- ------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Quick Start S3 bucket name\   aws-quickstart                        The S3 bucket you have created for your copy of Quick Start assets, if you decide to customize or extend the Quick Start for your own use. The bucket name can include numbers, lowercase letters, uppercase letters, and hyphens, but should not start or end with a hyphen.
  (QSS3BucketName)                                                    

  Quick Start S3 key prefix\    quickstart-\<company\>-\<product\>/   The [S3 key name prefix](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html) used to simulate a folder for your copy of Quick Start assets, if you decide to customize or extend the Quick Start for your own use. This prefix can include numbers, lowercase letters, uppercase letters, hyphens, and forward slashes.
  (QSS3KeyPrefix)                                                     
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

6.  On the **Options** page, you can [specify
    tags](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-resource-tags.html)
    (key-value pairs) for resources in your stack and [set advanced
    options](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-add-tags.html).
    When you're done, choose **Next**.

7.  On the **Review** page, review and confirm the template settings.
    Under **Capabilities**, select the two check boxes to acknowledge
    that the template will create IAM resources and that it might
    require the capability to auto-expand macros.

8.  Choose **Create** to deploy the stack.

9.  Monitor the status of the stack. When the status is
    **CREATE\_COMPLETE**, the \<software\> cluster is ready.

10. Use the URLs displayed in the **Outputs** tab for the stack to view
    the resources that were created.

![C:\\Users\\handans\\AppData\\Local\\Temp\\SNAGHTML55d15e82.PNG](media/image2.png){width="6.75in"
height="3.4554352580927383in"}

Figure 2: \<software\> outputs after successful deployment

Step 4. Test the Deployment
---------------------------

\<Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua.\>
