# Run Example Simulation Workload

## Overview

This tutorial provides instructions for running an example logic simulation workload in the EDA computing environment created in the [deployment tutorial](deploy-simple.md) included in this workshop. The example workload relies on creating sample verilog test cases and submission scripts using Amazon Q CLI.

### Step 1. Log into the DCV remote desktop session

1. Download and install the [NICE DCV remote desktop native client](https://download.nice-dcv.com) on your local laptop/desktop computer.
1. Launch the DCV client application. 
1. Paste the public IP address of the **Login Server** into the field. Click "Trust & Connect" when prompted. 
1. Enter the Username and Password.  You can find these credentials in AWS Secrets Manager in the AWS Console:
   1. Go to the Secrets Manager service and select the **DCVCredentialsSecret** secret.
   1. Click on the **Retrieve secret value** button.
   1. Copy the **username** and **password** and paste them into the appropriate DCV client fields.
1. If you have trouble connecting, ensure the security group on the login server includes the IP address of your client.

### Step 2. Submit a job to download, compile, and install icarus Verilog

* Create a directory under `/fsxn/scratch/` for your user id `simuser` then change the working directory to that path using the following commands:

```
mkdir -p /fsxn/scratch/simuser
cd /fsxn/scratch/simuser

```
* Use any editor to create a new file named `compiler_iverilog.sh` under `/fsxn/scratch/simuser`

```#!/bin/bash

set -x

cd /tmp
git clone https://github.com/steveicarus/iverilog.git
cd iverilog
/bin/sh autoconf.sh
mkdir -p /fsxn/scratch
./configure --prefix=/fsxn/scratch/iverilog
make
make install
```

Next, change the permissions on compile_iverilog.sh using: `chmod +x compile_iverilog.sh`. You can run this script directly within the DCV remote desktop session or you can submit this script to LSF so it would start a separate compute node to run this script. You can submit this script to LSF using `bsub ./compile_iverilog.sh`. Note that it would take a few minutes for LSF to provision a new host and execute the initializtion scripts to join the LSF cluster. You can monitor the status of the job using `bjobs` and the hosts in the cluster using `bhosts`

After the compilation completes successfully, verify that iverilog is now installed under `/fsxn/scratch/iverilog` as expected. After confirming this, then you'll need to add `/fsxn/scratch/iverilog/bin` to the PATH environment variable using this command

```
echo "export PATH=/fsxn/scratch/iverilog/bin:${PATH}" >> ~/.bashrc; source ~/.bashrc
```

### Step 3. Download and install Amazon Q CLI

Access the login server via SSH.

* Go back to AWS EC2 console
* Select the EC2 instance named `Login Server` and click **Connect**
* Select Session Manager tab then click **Connect**
* `sudo su` then `su -l simuser`

```
curl --proto '=https' --tlsv1.2 -sSf "https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux-musl.zip" -o "q.zip"
unzip q.zip

```

Now, we've download the Amazon Q CLI installer and unpacked it. Let's run `./q/install.sh` to start the installation. 

For the first question:
`Do you want q to modify your shell config (you will have to manually do this otherwise)?`
Select No

For the second question `Select login method ›`, select `❯ Use for Free with Builder ID` if you don't have Amazon Q Pro License or select `Use with Pro license` if you have one.

If you selected `❯ Use for Free with Builder ID`, this will give you a user code and a URL to open in your browser to complete the sign-in process if you have an existing Builder ID or you can sign-up for one. The URL should look similar to this: 
`https://view.awsapps.com/start/#/device?user_code=ABCD-EFDH`

Open this URL directly in your browser and follow the sign-in or sign-up process.

Once completed, you should see a message such as this in the SSH terminal where you started the installation process:
```
Device authorized
Logged in successfully
```

* After you're done with the steps in this section, close the Session Manager tab, and go back to the DCV remote desktop session

### Step 4. Prompt Amazon Q CLI to create verilog models, tests, and scripts to simulate the models using IBM LSF Scheduler

Create a new directory for this section called `amazon_q_verilog` under `/fsxn/scratch/simuser/` using the following commands:
```
mkdir -p /fsxn/scratch/simuser/amazon_q_verilog
cd /fsxn/scratch/simuser/amazon_q_verilog
```

Then start chatting with Amazon Q by typing `q chat`.

Amazon Q chat should start with a blank prompt. Use the following prompt as a starting point but feel free to make changes if you like

```
Create a python script to generate verilog models for 10 standard cells and the corresponding verilog tests. Make sure the python script doesn't use backslash in f-string expressions as this requires python3.12 but my environment uses an older python version. Also, ensure the verilog tests exhaustively exercise all possible input combinations for each cell.  Next, create another shell script to compile and simulate the verilog models using icarus verilog. Create the python and all shell scripts under a "scripts" folder. Next, create a makefile in the current directory with the following targets: 1) "clean" which would remove everything generated by the scripts and all simulation results and logs, 2) "generate" which would generate verilog models under "models" directory in the current directory and verilog tests under "tests/verilog" directory in the current directory, and 3) "iverilog" to compile and simulate the verilog models and verilog tests using icarus verilog. The simulation logs, VCD waveform files, and iverilog binary models should be created under "results". Make sure to use full path for the various directories instead of relative path to avoid creating files outside the current directory. Finally, create a submit_lsf_job.sh script under the "scripts" directory to submit a job to IBM LSF scheduler "verif" queue which would execute "make iverilog" on a remote compute node. The LSF job submission script should propagate the user's environment variables defined prior to running the simulations. The simulation script should include a summary to indicate the total number of cells, how many passed simulations and how many failed. Start creating these files one at a time instead of attempting to create all of them at once.
```

Accept the prompts to create the directory structure, and each of the scripts accordingly. Amazon Q will also update the file permissions for the script and will display a summary of the steps it did.

### Step 5. Test

Keep the terminal where you started Amazon Q chat running then open a new terminal so you can start testing the scripts.

First run `make clean generate` and verify that the models and tests are generated in the expected folders. If you observe errors, prompt Amazon Q CLI and inform it about the error and what you were expecting.

For example, you can use the following prompt to have Amazon Q CLI identify the error

```
make is not working as expected. Run it, read the output and log files, identify the root cause, and update the scripts accordingly. Don't make changes to the generated verilog models or tests but update the python script that generates these files.
```

Accept the changes that Amazon Q would make to the various scripts. Note: it could take Amazon Q CLI a few iterations till it identifies the root cause and fixes the scripts accordingly.

Finally, let's run the submit_lsf_job.sh script which should be executed as `./scripts/submit_lsf_job.sh`. Run the `bjobs` command and notice that the jobs is submitted to the "verif" queue as expected. You can wait for the job to complete the execution on the remote host or you can skip to the next section.

### Step 6. Test with parallel simulations

Go back to Amazon Q CLI, and prompt it as follows:

```
Modify the submit_lsf_job.sh script such that it would take a number parameter (defaults to 1) for parallel simulations then it submit a job array to lsf so that it would run a corresponding number of parallel simulations in a corresponding number of results directories. Modify other scripts as needed.
```

Accept the changes that Amazon Q CLI makes to the various scripts. After it is done, then start testing with 4 parallel simulations using `./scripts/submit_lsf_job.sh 4` then increase the number to 10 parallel simulations using `./scripts/submit_lsf_job.sh 10`.

Observe that the updated scripts would indeed submit a job array instead of single job. In the `bjobs` output, you can see that the JOB_NAME column has multiple jobs with the same name but with a different array index between square brackets. This is the LSF notation for job arrays.

   **Optional task: Specify an instance type**
   LSF will choose the best instance type based on the LSF Resource Connector configuration, but there may be situations where you may want to target a particular instance type for a workload. This workshop has been configured to allow you to overide the default behavior and specify the desired instance type. The following instance types are supported in this workshop: `z1d_2xlarge`, `m5_xlarge`, `m5_2xlarge`, `c5_2xlarge`, `z1d_2xlarge`, `r5_12xlarge`, and `r5_24xlarge`.  Use the `instance_type` resource in the `bsub` resource requirement string to request one of these instances. For example:

   Edit submit_lsf_job.sh or the script it creates to submit the simulation jobs to include the following header:

   `#BSUB -R "select[aws && instance_type==m5_2xlarge]"`

### Useful LSF commands

1. Run the `bhosts` command to see how many hosts in the cluster

1. Check job status

    `bjobs -A`

1. Check execution host status

    `bhosts -w`

1. Check cluster status

   `badmin showstatus`

1. Check LSF Resource Connector status

    `badmin rc view`
    `badmin rc error`

About 10 minutes after the jobs complete, LSF Resource Connector will begin terminating the idle EC2 instances.
