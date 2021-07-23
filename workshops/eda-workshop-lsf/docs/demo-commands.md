cd /ec2-nfs/proj
git clone https://github.com/morrmt/aws-fpga-sa-demo.git

cd /ec2-nfs/proj/aws-fpga-sa-demo/eda-workshop

bsub -R aws -J "setup" ./run-sim.sh --scratch-dir /ec2-nfs/scratch

bsub -R aws -J "regress[1-100]" -w "done(setup)" ./run-sim.sh --scratch-dir /ec2-nfs/scratch

bsub -R aws -J "regress[1-100]" ./run-sim.sh --scratch-dir /ec2-nfs/scratch

bsub -R "select[aws && mem>30000]" ./run-sim.sh --scratch-dir /ec2-nfs/scratch

bsub -R "select[aws && instance_type==z1d_2xlarge]" ./run-sim.sh --scratch-dir /ec2-nfs/scratch

1. Submit single spot job
bsub -R spot sleep 15m

2. Manually terminate spot instance
3. Observe requeue

bhist -l <job_id>

bsub -R spot -J "spot[1-100]" ./run-sim.sh --scratch-dir /ec2-nfs/scratch

bjobs
bhosts -w
bhosts -rc
bhosts -rconly
lshosts
lshosts -s
badmin showstatus
badmin rc view
badmin rc error
badmin rc view -c templates


curl http://169.254.169.254/latest/meta-data/spot



