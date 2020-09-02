#!/bin/bash -e

set +x
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root"
   exit 1
fi
exec > >(tee /root/custom_ami.log ) 2>&1

OS_NAME=$(cat /etc/redhat-release | awk '{print $1}')
OS_VER=$(cat /etc/redhat-release | tr -dc '0-9.' | cut -d \. -f1)
if [ "$OS_NAME" == "Red" ]; then
    OS="rhel"
elif [ "$OS_NAME" == "CentOS" ]; then
    OS="centos"
fi

echo "Installing System packages"
yum install -y wget
cd /root
wget https://raw.githubusercontent.com/awslabs/scale-out-computing-on-aws/master/source/scripts/config.cfg
source /root/config.cfg
if [ $OS == "centos" ]; then
    yum install -y epel-release
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    if [ $OS_VER == "7" ]; then
        yum groupinstall -y "GNOME Desktop"
        systemctl enable amazon-ssm-agent
        systemctl restart amazon-ssm-agent
    elif [ $OS_VER == "6" ]; then
        yum groupinstall -y "X Window System" Desktop Fonts
    fi
elif [ $OS == "rhel" ]; then
    if [ $OS_VER == "7" ]; then
        wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
        yum localinstall -y epel-release-latest-7.noarch.rpm
        yum groupinstall -y "Server with GUI"
        yum localinstall -y https://rpmfind.net/linux/centos/7.8.2003/os/x86_64/Packages/libedit-devel-3.0-12.20121213cvs.el7.x86_64.rpm
        yum localinstall -y https://rpmfind.net/linux/centos/7.8.2003/os/x86_64/Packages/hwloc-devel-1.11.8-4.el7.x86_64.rpm
    elif [ $OS_VER == "6" ]; then
        wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
        yum localinstall -y epel-release-latest-6.noarch.rpm
        yum groupinstall -y "X Window System" Desktop Fonts
        yum localinstall -y https://rpmfind.net/linux/centos/6.10/os/x86_64/Packages/libedit-devel-2.11-4.20080712cvs.1.el6.x86_64.rpm
        yum localinstall -y https://rpmfind.net/linux/centos/6.10/os/x86_64/Packages/pciutils-devel-3.1.10-4.el6.x86_64.rpm
        yum localinstall -y https://rpmfind.net/linux/centos/6.10/os/x86_64/Packages/hwloc-devel-1.5-3.el6_5.x86_64.rpm
    fi
fi
yum install -y $(echo ${SYSTEM_PKGS[*]}) $(echo ${SCHEDULER_PKGS[*]}) $(echo ${OPENLDAP_SERVER_PKGS[*]}) $(echo ${SSSD_PKGS[*]})

#Install PBSPro
echo "Installing PBSPro"
wget $PBSPRO_URL
tar zxvf $PBSPRO_TGZ
cd *pbs*-$PBSPRO_VERSION
./autogen.sh
./configure --prefix=/opt/pbs
make -j6
make install -j6
/opt/pbs/libexec/pbs_postinstall
chmod 4755 /opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp
if [ $OS_VER == "7" ]; then
    systemctl disable pbs
    systemctl disable libvirtd
    systemctl disable firewalld
elif [ $OS_VER == "6" ]; then
    chkconfig pbs off
    chkconfig iptables off
fi

# Disable SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Install pip and awscli
echo "Installing pip and awscli"
if [ $OS_VER == "7" ]; then
    EASY_INSTALL=$(which easy_install-2.7)
    $EASY_INSTALL pip
    PIP=$(which pip2.7)
    $PIP install awscli
elif [ $OS_VER == "6" ]; then
    wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
    tar xzf Python-2.7.18.tgz
    cd Python-2.7.18
    ./configure --enable-optimizations
    make altinstall
    export PATH=$PATH:/usr/local/bin
    wget https://bootstrap.pypa.io/get-pip.py
    python2.7 get-pip.py
    PIP=$(which pip2.7)
    $PIP install awscli
fi

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
echo -e "*              hard    memlock         unlimited
*               soft    memlock         unlimited
*               soft    nproc       3061780
*               hard    nproc       3061780
*               soft    sigpending  3061780
*               hard    sigpending  3061780
*               soft    nofile          1048576
*               hard    nofile          1048576" >> /etc/security/limits.conf
echo -e "ulimit -l unlimited
ulimit -u 3061780
ulimit -i 3061780
ulimit -n 1048576" >> /opt/pbs/lib/init.d/limits.pbs_mom

# Install and configure Amazon CloudWatch Agent
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

# Install DCV
echo "Install DCV"
cd ~
if [ $OS_VER == "7" ]; then
    wget $DCV_URL
    if [[ $(md5sum $DCV_TGZ | awk '{print $1}') != $DCV_HASH ]];  then
        echo -e "FATAL ERROR: Checksum for DCV failed. File may be compromised." > /etc/motd
            exit 1
    fi
elif [ $OS_VER == "6" ]; then
    DCV_URL=$(sed 's/el7/el6/' <<< $DCV_URL)
    DCV_TGZ=$(sed 's/el7/el6/' <<< $DCV_TGZ)
    DCV_VERSION=$(sed 's/el7/el6/' <<< $DCV_VERSION)
    wget $DCV_URL
fi
tar zxvf $DCV_TGZ
cd nice-dcv-$DCV_VERSION
rpm -ivh *.x86_64.rpm --nodeps

echo "Creating script to install FSx for Lustre client: fsx_lustre.sh"
echo -e "#!/bin/bash

set -x
if [[ \$EUID -ne 0 ]]; then
   echo \"Error: This script must be run as root\"
   exit 1
fi
exec > >(tee /root/fsx_lustre.log ) 2>&1
echo \"Installing FSx lustre client\"
OS_VER=\$(cat /etc/redhat-release | tr -dc '0-9.' | cut -d \. -f1)
kernel=\$(uname -r)
echo \$(uname -r)
if [ \$OS_VER == "7" ]; then
        if [[ \$kernel == *\"3.10.0-1127\"* ]]; then
                echo \"Newer kernel\"
                wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc
                rpm --import /tmp/fsx-rpm-public-key.asc
                wget https://fsx-lustre-client-repo.s3.amazonaws.com/el/7/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
                yum clean all
                yum install -y kmod-lustre-client lustre-client
        else
                echo \"Older kernel\"
                wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc
                rpm --import /tmp/fsx-rpm-public-key.asc
                wget https://fsx-lustre-client-repo.s3.amazonaws.com/el/7/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
                sed -i 's#7#7.7#' /etc/yum.repos.d/aws-fsx.repo
                yum clean all
                yum install -y kmod-lustre-client lustre-client
   fi
elif [ \$OS_VER == "6" ]; then
    wget https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el6.10/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el6.x86_64.rpm
    wget https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el6.10/client/RPMS/x86_64/lustre-client-2.10.5-1.el6.x86_64.rpm
    yum clean all
    yum localinstall -y kmod-lustre-client-2.10.5-1.el6.x86_64.rpm lustre-client-2.10.5-1.el6.x86_64.rpm
fi" > /root/fsx_lustre.sh
chmod +x /root/fsx_lustre.sh

echo "Will reboot instance now to load new kernel! After reboot, login back, become root and run fsx_lustre.sh"
reboot
