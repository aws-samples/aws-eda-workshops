# Run Example Simulation Workload

## Overview

This tutorial provides instructions for running an example logic simulation workload in the EDA computing envronment created in the [deployment tutorial](deploy-environment.md) included in this workshop.  The example workload uses the designs and IP contained in the public **AWS F1 FPGA Development Kit** and the **Xilinx Vivado** EDA software suite provided by the **AWS FPGA Developer AMI** that you subscribed to in the first tutorial. Although you'll be using data and tools from AWS FPGA developer resources, you will not be running on the F1 FPGA instance or executing any type of FPGA workload; we're simply running software simulations on EC2 compute instances using the design data, IP, and software that these kits provide for no additional charge.

**Note** there are no additional charges to use the AWS F1 FPGA Development Kit or the  **Xilinx Vivado** tools in the AWS FPGA Developer AMI.  You are only charged for the underlying AWS resources consumed by running the AMI and included software.

### Step 1. Clone the AWS F1 FPGA Development Kit repo

1. Using the DCV client application, log into the DCV remote desktop session that you established in the previous module.

1. Clone the example workload from the `aws-fpga-sa-demo` Github repo into the `proj` directory on the NFS file system. The default location is `/ec2-nfs/proj`.

   ```bash
   cd /ec2-nfs/proj
   git clone https://github.com/morrmt/aws-fpga-sa-demo.git
   ```

1. Change into the repo's workshop directory

   `cd /ec2-nfs/proj/aws-fpga-sa-demo/eda-workshop`

### Step 2. Run setup job

This first job will set up the runtime environment for the simulations that you will submit to LSF in Step 3 below.

1. **Submit the setup job into LSF**. The `--scratch-dir` should be the path to the scratch directory you defined when launching the CloudFormation stack in the previous tutorial.  The default is `/ec2-nfs/scratch`.

   `bsub -R aws -J "setup" ./run-sim.sh --scratch-dir /ec2-nfs/scratch`

1. **Watch job status**. This job will generate demand to LSF Resource Connector for an EC2 instance.  Shortly after you submit the job, you should see a new "LSF Exec Host" instance in the EC2 Dashboard in the AWS console. It should take 2-5 minutes for this new instance to join the cluster and accept the job.  Use the `bjobs` command to watch the status of the job.  Once it enters the `RUN` state, move on to the next step.

### Step 3. Run verification tests at scale

Now we are ready to scale out the simulations.  Like with the setup job above, when these jobs hit the queue LSF will generate demand for EC2 instances, and Resource Connector will start up the appropriate number and type of instances to satisfy the pending jobs in the queue.

1. **Submit a large job array**. This job array will spawn 100 verification jobs.  These jobs will be dispatched only after the setup job above completes successfully. Again, The `--scratch-dir` should be the path to the scratch directory you used above.

   `bsub -R aws -J "regress[1-100]" -w "done(setup)" ./run-sim.sh --scratch-dir /ec2-nfs/scratch`

   **Option: Specify an instance type**
   LSF will choose the best instance type based on the LSF Resource Connector configuration, but there may be situations where you may want to target a particular instance type for a workload. This workshop has been configured to allow you to overide the default behavior and specify the desired instance type. The following instance types are supported in this workshop: `z1d_2xlarge`, `m5_xlarge`, `m5_2xlarge`, `c5_2xlarge`, `z1d_2xlarge`, `r5_12xlarge`, and `r5_24xlarge`.  Use the `instance_type` resource in the `bsub` resource requirement string to request one of these instances. For example:

   `bsub -R "select[aws && instance_type==z1d_2xlarge]" -J "regress[1-100]" -w "done(setup)" ./run-sim.sh --scratch-dir /ec2-nfs/scratch`

1. Check job status

    `bjobs -A`

1. Check execution host status

    `bhosts -w`

1. Check cluster status

   `badmin showstatus`

1. Check LSF Resource Connector status


    `badmin rc view`

    `badmin rc error`

1. View LSF Resource Connector template configuration

    `badmin rc view -c templates`

About 10 minutes after the jobs complete, LSF Resource Connector will begin terminating the idle EC2 instances.

### Step 4: Clean up

To help prevent unwanted charges to your AWS account, you can delete the AWS resources that you used for this tutorial.

1. Delete the parent stack

1. Delete orphaned EBS volumes.  The FPGA AMI doesn't delete them on instance termination.
