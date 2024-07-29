#!/bin/bash
mkdir -p $LSF_INSTALL_DIR
mkdir -p /var/log/lsf && chmod 777 /var/log/lsf

# Add LSF admin account
id -u $LSF_ADMIN &>/dev/null || adduser -m -u 1500 $LSF_ADMIN
echo "source $LSF_INSTALL_DIR/conf/profile.lsf" >> /etc/bashrc

# Add to bashrc if not yet exists
grep -qxF "source $LSF_INSTALL_DIR/conf/profile.lsf" /etc/bashrc || \
echo "source $LSF_INSTALL_DIR/conf/profile.lsf" >> /etc/bashrc

# Download customer-provided LSF binaries and entitlement file
aws --quiet s3 cp $CFN_LSF_INSTALL_URI /tmp
aws --quiet s3 cp $CFN_LSF_BIN_URI /tmp
aws --quiet s3 cp $CFN_LSF_ENTITLEMENT_URI /tmp
aws --quiet s3 cp $CFN_LSF_FIXPACK_URI /tmp

cd /tmp
tar xf $LSF_INSTALL_PKG
cp $LSF_BIN_PKG lsf10.1_lsfinstall
cd lsf10.1_lsfinstall

# Create LSF installer config file
cat <<EOF > install.config
LSF_TOP="$LSF_INSTALL_DIR"
LSF_ADMINS="$LSF_ADMIN"
LSF_CLUSTER_NAME=$LSF_CLUSTER_NAME
LSF_MASTER_LIST="${HOSTNAME%%.*}"
SILENT_INSTALL="Y"
LSF_SILENT_INSTALL_TARLIST="ALL"
ACCEPT_LICENSE="Y"
LSF_ENTITLEMENT_FILE="/tmp/$LSF_ENTITLEMENT"
EOF

./lsfinstall -f install.config

# Setup LSF environment
source $LSF_INSTALL_DIR/conf/profile.lsf

# Install fix pack
cd $LSF_INSTALL_DIR/10.1/install
cp /tmp/$LSF_FP_PKG .
echo "schmod_demand.so" >> patchlib/daemonlists.tbl
./patchinstall --silent $LSF_FP_PKG

## Create Resource Connector config dir
mkdir -p $LSF_ENVDIR/resource_connector/aws/conf
chown -R lsfadmin:root $LSF_ENVDIR/resource_connector/aws