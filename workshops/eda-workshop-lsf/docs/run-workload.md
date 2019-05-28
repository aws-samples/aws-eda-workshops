# Run Example Simulation Workload

1. Log into login server as `centos` user using the private key from the key pair you provided in the Cloudformation stack.

1. Clone the example workload from the `aws-fpga-sa-demo` Github repo into your `proj` directory on the NFS file system.

   `git clone https://github.com/morrmt/aws-fpga-sa-demo.git`

1. Change into the repo directory

   `cd /path/to/aws-fpga-sa-demo/eda-workshop`

1. Run setup job

   This job will generate demand to LSF Resource Connector for an EC2 instance.  Shortly after you submit the job, you should see a new "LSF Exec Host" instance in the EC2 Dashboard in the AWS console.

   `bsub -R aws -J "setup" ./run-sim.sh --scratch-dir /path/to/scratch-dir`

1. Watch job status
   It should take 2-5 minutes for a new "LSF Exec Host" instance to join the cluster and take the job.  Use the `bjobs` command to watch the status of the job.

1. Run scale-out test with a large job array.

   This job array will spawn 100 verification jobs.  These jobs will be dispatched after the setup job above completes successfully.

   `bsub -R aws -J "regress[1-100]" -w "done(setup)" ./run-sim.sh --scratch-dir /path/to/scratch-dir`

1. Check job status

    `bjobs -A`

1. Check execution host status

    `bhosts -w`

1. Check cluster status

   `badmin showstatus`
