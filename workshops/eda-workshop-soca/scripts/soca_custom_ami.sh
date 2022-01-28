#!/bin/bash

set -x
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root"
   exit 1
fi

exec > >(tee /root/soca_preinstalled_packages.log ) 2>&1

OS_NAME=`awk -F= '/^NAME=/{print $2}' /etc/os-release`
OS_VERSION=`awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release`
if [ "$OS_NAME" == "\"Red Hat Enterprise Linux Server\"" ] && [ "$OS_VERSION" == \"7.6\" ]; then
    OS="rhel7"
elif [ "$OS_NAME" == "\"CentOS Linux\"" ] && [ "$OS_VERSION" == "\"7\"" ]; then
    OS="centos7"
elif [ "$OS_NAME" == "\"Amazon Linux\"" ] && [ "$OS_VERSION" == "\"2\"" ]; then
    OS="amazonlinux2"
else
    echo "Unsupported OS! OS_NAME: $OS_NAME, OS_VERSION: $OS_VERSION"
    exit
fi

echo "Installing System packages"
yum install -y wget
cd /root
wget https://raw.githubusercontent.com/awslabs/scale-out-computing-on-aws/master/source/scripts/config.cfg
source /root/config.cfg
if [ $OS == "centos7" ]; then
    yum install -y epel-release
    yum install -y $(echo ${SYSTEM_PKGS[*]} ${SCHEDULER_PKGS[*]} ${OPENLDAP_SERVER_PKGS[*]} ${SSSD_PKGS[*]})
    yum groupinstall -y "GNOME Desktop"
elif [ $OS == "amazonlinux2" ]; then
    yum install -y epel-release
    yum install -y $(echo ${SYSTEM_PKGS[*]} ${SCHEDULER_PKGS[*]} ${OPENLDAP_SERVER_PKGS[*]} ${SSSD_PKGS[*]} ${DCV_AMAZONLINUX_PKGS[*]})
    #amazon-linux-extras install mate-desktop1.x
    #bash -c 'echo PREFERRED=/usr/bin/mate-session > /etc/sysconfig/desktop'
elif [ $OS == "rhel7" ]; then
    # Tested only on RHEL7.6
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install -y $(echo ${SYSTEM_PKGS[*]} ${SCHEDULER_PKGS[*]}) --enablerepo rhui-REGION-rhel-server-optional
    yum install -y $(echo ${OPENLDAP_SERVER_PKGS[*]} ${SSSD_PKGS[*]})
    yum groupinstall -y "Server with GUI"
fi

echo "Installing Packages typically needed for EDA applications"
yum install -y vim vim-X11 xterm compat-db47 glibc glibc.i686 openssl098e compat-expat1.i686 dstat \
    motif libXp libXaw libICE.i686 libpng.i686 libXau.i686 libuuid.i686 libSM.i686 libxcb.i686 \
    plotutils libXext.i686 libXt.i686 libXmu.i686 libXp.i686 libXrender.i686 bzip2-libs.i686 \
    freetype.i686 fontconfig.i686 libXft.i686 libjpeg-turbo.i686 motif.i686 apr.i686 libdb \
    libdb.i686 libdb-utils apr-util.i686 libXp.i686 qt qt-x11 qtwebkit apr-util gnuplot \
    libXScrnSaver tbb compat-libtiff3 arts SDL

#Install OpenPBS
echo "Installing OpenPBS"
wget $OPENPBS_URL
tar zxvf $OPENPBS_TGZ
cd openpbs-$OPENPBS_VERSION
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
yum install -y python3-pip
PIP=$(which pip3)
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
*		soft 	nproc 	    3061780
*		hard 	nproc 	    3061780
*		soft	sigpending  3061780
*		hard	sigpending  3061780
*		soft	nofile		1048576
*		hard	nofile		1048576" >> /etc/security/limits.conf
echo -e "ulimit -l unlimited
ulimit -u 3061780
ulimit -i 3061780
ulimit -n 1048576" >> /opt/pbs/lib/init.d/limits.pbs_mom

# Install and configure Amazon CloudWatch Agent
echo "Install and configure Amazon CloudWatch Agent"
machine=$(uname -m)
if [[ $machine == "x86_64" ]]; then
    yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
elif [[ $machine == "aarch64" ]]; then
    yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/arm64/latest/amazon-cloudwatch-agent.rpm
fi
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
machine=$(uname -m)
if [[ $machine == "x86_64" ]]; then
    wget $DCV_X86_64_URL
    if [[ $(md5sum $DCV_X86_64_TGZ | awk '{print $1}') != $DCV_X86_64_HASH ]];  then
        echo -e "FATAL ERROR: Checksum for DCV failed. File may be compromised." > /etc/motd
        exit 1
    fi
    tar zxvf $DCV_X86_64_TGZ
    cd nice-dcv-$DCV_X86_64_VERSION
elif [[ $machine == "aarch64" ]]; then
    DCV_URL=$(echo $DCV_AARCH64_URL | sed 's/x86_64/aarch64/')
    wget $DCV_AARCH64_URL
    if [[ $(md5sum $DCV_AARCH64_TGZ | awk '{print $1}') != $DCV_AARCH64_HASH ]];  then
        echo -e "FATAL ERROR: Checksum for DCV failed. File may be compromised." > /etc/motd
        exit 1
    fi
    DCV_TGZ=$(echo $DCV_AARCH64_TGZ | sed 's/x86_64/aarch64/')
    tar zxvf $DCV_AARCH64_TGZ
    DCV_VERSION=$(echo $DCV_AARCH64_VERSION | sed 's/x86_64/aarch64/')
    cd nice-dcv-$DCV_AARCH64_VERSION
fi
rpm -ivh nice-xdcv-*.${machine}.rpm --nodeps
rpm -ivh nice-dcv-server*.${machine}.rpm --nodeps
rpm -ivh nice-dcv-web-viewer-*.${machine}.rpm --nodeps

# Enable DCV support for USB remotization
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y dkms
DCVUSBDRIVERINSTALLER=$(which dcvusbdriverinstaller)
$DCVUSBDRIVERINSTALLER --quiet

echo "Creating script to install FSx for Lustre client: /root/fsx_lustre.sh"
echo -e "#!/bin/bash

set -x
crontab -r
if [[ \$EUID -ne 0 ]]; then
   echo \"Error: This script must be run as root\"
   exit 1
fi
REQUIRE_REBOOT=0
echo \"Installing FSx lustre client\"
kernel=\$(uname -r)
machine=\$(uname -m)
echo \"Found kernel version: \${kernel} running on: \${machine}\"
if [ $OS == "centos7" ] || [ $OS == "rhel7" ]; then
    if [[ \$kernel == *\"3.10.0-957\"*\$machine ]]; then
       yum -y install https://downloads.whamcloud.com/public/lustre/lustre-2.10.8/el7/client/RPMS/x86_64/kmod-lustre-client-2.10.8-1.el7.x86_64.rpm
       yum -y install https://downloads.whamcloud.com/public/lustre/lustre-2.10.8/el7/client/RPMS/x86_64/lustre-client-2.10.8-1.el7.x86_64.rpm
       REQUIRE_REBOOT=1
    elif [[ \$kernel == *\"3.10.0-1062\"*\$machine ]]; then
       wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc
       rpm --import /tmp/fsx-rpm-public-key.asc
       wget https://fsx-lustre-client-repo.s3.amazonaws.com/el/7/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
       sed -i 's#7#7.7#' /etc/yum.repos.d/aws-fsx.repo
       yum clean all
       yum install -y kmod-lustre-client lustre-client
       REQUIRE_REBOOT=1
    elif [[ \$kernel == *\"3.10.0-1127\"*\$machine ]]; then
       wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc
       rpm --import /tmp/fsx-rpm-public-key.asc
       wget https://fsx-lustre-client-repo.s3.amazonaws.com/el/7/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
       sed -i 's#7#7.8#' /etc/yum.repos.d/aws-fsx.repo
       yum clean all
       yum install -y kmod-lustre-client lustre-client
       REQUIRE_REBOOT=1
    elif [[ \$kernel == *\"3.10.0-1160\"*\$machine ]]; then
       wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc
       rpm --import /tmp/fsx-rpm-public-key.asc
       wget https://fsx-lustre-client-repo.s3.amazonaws.com/el/7/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
       yum clean all
       yum install -y kmod-lustre-client lustre-client
       REQUIRE_REBOOT=1
    elif [[ \$kernel == *\"4.18.0-193\"*\$machine ]]; then
       # FSX for Lustre on aarch64 is supported only on 4.18.0-193
       wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc
       rpm --import /tmp/fsx-rpm-public-key.asc
       wget https://fsx-lustre-client-repo.s3.amazonaws.com/centos/7/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
       yum clean all
       yum install -y kmod-lustre-client lustre-client
       REQUIRE_REBOOT=1
    else
       echo \"ERROR: Can't install FSx for Lustre client as kernel version: ${kernel} isn't matching expected versions: (x86_64: 3.10.0-957, -1062, -1127, -1160, aarch64: 4.18.0-193)!\"
    fi
elif [ $OS == "amazonlinux2" ]; then
    amazon-linux-extras install -y lustre2.10
    REQUIRE_REBOOT=1
fi
if [[ \$REQUIRE_REBOOT -eq 1 ]]; then
    echo \"Rebooting to load FSx for Lustre drivers!\"
    /sbin/reboot
fi" > /root/fsx_lustre.sh
chmod +x /root/fsx_lustre.sh

echo "Will reboot instance now to load new kernel! After reboot, the script at /root/fsx_lustre.sh will install FSx for Lustre client corresponding to the new kernel version. See details in /root/fsx_lustre.sh.log"
echo "@reboot /bin/bash /root/fsx_lustre.sh >> /root/fsx_lustre.sh.log 2>&1" | crontab -
/sbin/reboot
