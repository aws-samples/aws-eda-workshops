#!/bin/bash    

set -x
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root" 
   exit 1
fi
exec > >(tee /root/custom_ami.log ) 2>&1

OS_NAME=`awk -F= '/^NAME/{print $2}' /etc/os-release`
if [ "$OS_NAME" == "\"Red Hat Enterprise Linux Server\"" ]; then
    OS="rhel"
elif [ "$OS_NAME" == "\"CentOS Linux\"" ]; then
    OS="centos"
fi

echo "Installing System packages"
yum install -y wget
cd /root
wget https://raw.githubusercontent.com/awslabs/scale-out-computing-on-aws/master/source/scripts/config.cfg
source /root/config.cfg 
if [ $OS == "centos" ]; then
    yum install -y epel-release
    yum install -y $(echo ${SYSTEM_PKGS[*]}) $(echo ${SCHEDULER_PKGS[*]}) $(echo ${OPENLDAP_SERVER_PKGS[*]}) $(echo ${SSSD_PKGS[*]})
    yum groupinstall -y "GNOME Desktop"
elif [ $OS == "rhel" ]; then
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install epel-release-latest-7.noarch.rpm 
    yum install -y $(echo ${SYSTEM_PKGS[*]}) $(echo ${SCHEDULER_PKGS[*]}) --enablerepo rhui-REGION-rhel-server-optional
    yum install -y $(echo ${OPENLDAP_SERVER_PKGS[*]}) $(echo ${SSSD_PKGS[*]})
    yum groupinstall -y "Server with GUI"
fi

#Install PBSPro
echo "Installing PBSPro"
export PBSPRO_URL
export PBSPRO_TGZ
export PBSPRO_VERSION
wget $PBSPRO_URL
tar zxvf $PBSPRO_TGZ
cd pbspro-$PBSPRO_VERSION
./autogen.sh
./configure --prefix=/opt/pbs
make -j6
make install -j6
/opt/pbs/libexec/pbs_postinstall
chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
systemctl disable pbs
systemctl disable libvirtd
systemctl disable firewalld

# Disable SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Install pip and awscli
echo "Installing pip and awscli"
EASY_INSTALL=$(which easy_install-2.7)
$EASY_INSTALL pip
PIP=$(which pip2.7)
$PIP install awscli

# Configure system limits
echo "Configuring system limits"
echo -e "net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=163840
net.core.rmem_default=31457280
net.core.rmem_max=67108864
net.core.wmem_default = 31457280
net.core.wmem_max = 67108864
fs.file-max=1048576
fs.nr_open=1048576" >> /etc/sysctl.conf 
echo -e "*		hard 	memlock 	unlimited
*		soft 	memlock 	unlimited
*		soft 	maxproc 	3061780
*		hard 	maxproc 	3061780
*		soft	maxsignal	3061780
*		hard	maxsignal	3061780
*		soft	nofile		1048576
*		hard	nofile		1048576" >> /etc/security/limits.conf 
echo -e "ulimit -l unlimited
ulimit -u 3061780
ulimit -i 3061780
ulimit -n 1048576" >> /opt/pbs/lib/init.d/limits.pbs_mom

echo "Install and configure Amazon CloudWatch Agent"
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
echo -e "{
        \"agent\": {
                \"metrics_collection_interval\": 60,
                \"run_as_user\": \"root\"
        },
        \"metrics\": {
                \"append_dimensions\": {
                        \"InstanceId\": \"$\{aws:InstanceId\}\",
                        \"InstanceType\": \"$\{aws:InstanceType\}\"
                },
                \"metrics_collected\": {
                        \"cpu\": {
                                \"measurement\": [
                                        \"cpu_usage_idle\",
                                        \"cpu_usage_iowait\",
                                        \"cpu_usage_user\",
                                        \"cpu_usage_system\"
                                ],
                                \"metrics_collection_interval\": 60,
                                \"totalcpu\": true
                        },
                        \"mem\": {
                                \"measurement\": [
                                        \"mem_used_percent\"
                                ],
                                \"metrics_collection_interval\": 60
                        },
                        \"netstat\": {
                                \"measurement\": [
                                        \"tcp_established\",
                                        \"tcp_time_wait\"
                                ],
                                \"metrics_collection_interval\": 60
                        },
                        \"swap\": {
                                \"measurement\": [
                                        \"swap_used_percent\"
                                ],
                                \"metrics_collection_interval\": 60
                        }
                }
        }
}" > /opt/aws/amazon-cloudwatch-agent/bin/config.json
sed -i 's/\(Instance.*\)\\{\(.*\)\\}/\1{\2}/g' /opt/aws/amazon-cloudwatch-agent/bin/config.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

echo "Creating script to install FSx for Lustre client: fsx_lusre.sh"
echo -e "#!/bin/bash    

set -x
if [[ \$EUID -ne 0 ]]; then
   echo \"Error: This script must be run as root\" 
   exit 1
fi
exec > >(tee /root/fsx_lustre.log ) 2>&1
echo \"Installing FSx lustre client\"
kernel=\$(uname -r)
echo \$(uname -r)   
if [[ \$kernel == *\"3.10.0-1127\"* ]]; then
    echo \"Newer kernel\"
    sudo wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc
    sudo rpm --import /tmp/fsx-rpm-public-key.asc
    sudo wget https://fsx-lustre-client-repo.s3.amazonaws.com/el/7/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
    sudo yum clean all
    sudo yum install -y kmod-lustre-client lustre-client
else
    echo \"Older kernel\"
    sudo wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc
    sudo rpm --import /tmp/fsx-rpm-public-key.asc
    sudo wget https://fsx-lustre-client-repo.s3.amazonaws.com/el/7/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
    sudo sed -i 's#7#7.7#' /etc/yum.repos.d/aws-fsx.repo
    sudo yum clean all
    sudo yum install -y kmod-lustre-client lustre-client
fi" > /root/fsx_lustre.sh
chmod +x /root/fsx_lustre.sh

echo "Will reboot instance now to load new kernel! After reboot, login back, become root and run fsx_lustre.sh"
reboot
