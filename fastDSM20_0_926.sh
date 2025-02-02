#!/bin/bash
dbpw=`cat /opt/DSMDBPW`
ActivationCode=`cat /opt/DSActivationCode`
dsmuser=SuperUser
dsmpw=`cat /opt/DSMPassword`
dsmMajorVersion="20.0"
dsmMinorVersion="926"
dsmVersion="$dsmMajorVersion.$dsmMinorVersion"
downloadUrl="https://files.trendmicro.com"

download(){  
  until curl -f $@ ; 
  do
    sleep 1
  done
}
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

# setup dir
mkdir -p /opt/fastdsm/
cd /opt/fastdsm/

echo "$(date) -- Installing Docker Dependencies"

#Docker dependencies
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

#Detect OS version for Extra repo enablement
echo "$(date) -- Detecting OS and installing Docker"

OS=`cat /etc/system-release`
echo "${OS}"
if [[ "${OS}" == *"7.6"* ]] ; then
    echo "setting up repos and installing docker for RHEL 7.6"
    yum-config-manager --enable rhui-REGION-rhel-server-extras
    yum install -y container-selinux
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum -y install docker-ce
elif [[ "${OS}" == *"7.7"* ]] ; then
    echo "setting up repos and installing docker for RHEL 7.7"
    yum-config-manager --enable rhui-rhel-7-server-rhui-extras-rpms
    yum install -y container-selinux
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum -y install docker-ce
elif [[ "${OS}" == *"7.8"* ]] ; then
    echo "setting up repos and installing docker for RHEL 7.8"
    yum-config-manager --enable rhui-rhel-7-server-rhui-extras-rpms
    yum install -y container-selinux
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sed -i 's/$releasever/7/g' /etc/yum.repos.d/docker-ce.repo
    yum -y install docker-ce
elif [[ "${OS}" == *"8."* ]] ; then
    echo "setting up repos and installing docker for Rhel 8.X"
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum -y install containerd.io
    yum -y install docker-ce --nobest
elif [[ "${OS}" == *"Amazon"* ]] ; then
    echo "Installing docker for Amazon Linux 1, repos already available"
    yum -y install docker
else echo "Platform not supported for install"
fi

#Download proper installer per OS
if [[ "${OS}" == *"7.6"* || "${OS}" == *"7.7"* || "${OS}" == *"7.8"* || "${OS}" == *"8."* ]] ; then
    managerInstaller="$downloadUrl/products/deepsecurity/en/$dsmMajorVersion/Manager-Linux-$dsmVersion.x64.sh"
    download ${managerInstaller} -o Manager-Linux.sh
elif [[ "${OS}" == *"Amazon"* ]] ; then
    ActivationCode=""
    managerInstaller="$downloadUrl/products/deepsecurity/en/$dsmMajorVersion/Manager-AWS_Marketplace_Upgrade-$dsmVersion.x64.zip"
    download ${managerInstaller} -o Manager-Amazon-Linux.zip
    mkdir /opt/fastdsm/amazonlinux
    unzip ./Manager-Amazon-Linux.zip -d /opt/fastdsm/amazonlinux
    mv /opt/fastdsm/amazonlinux/Manager-AWS-$dsmVersion.x64.sh /opt/fastdsm/Manager-Linux.sh
    rm -rf /opt/fastdsm/amazonlinux
else echo "Platform not supported"
fi

service docker start

echo "$(date) -- creating pgsql container for dsmdb"
docker pull postgres:11
docker run --name dsmpgsqldb -p 5432:5432 -e "POSTGRES_PASSWORD=${dbpw}"  -e POSTGRES_DB=dsm -d postgres:11
echo "$(date) -- creating database in sql instance"

# persist db across restart
echo "$(date) -- creating service config to persiste db instance"
download https://s3.amazonaws.com/424d57/fastDsm/docker-dsmdb -o /etc/init.d/docker-dsmdb
chmod 755 /etc/init.d/docker-dsmdb
chkconfig --add docker-dsmdb
chkconfig docker-dsmdb on
chkconfig --add docker 
chkconfig docker on

# get ds files
echo "$(date) -- downloading agent installers"
#download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-amzn1-20.0.0-3288.x86_64.zip"
#download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-amzn1-20.0.0-3248.x86_64.zip"
#download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-amzn2-20.0.0-3288.aarch64.zip"
#download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-amzn2-20.0.0-3263.aarch64.zip"
#download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-amzn2-20.0.0-3288.x86_64.zip"
#download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-amzn2-20.0.0-3248.x86_64.zip"
download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-RedHat_EL7-20.0.1-9400.x86_64.zip"
download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-RedHat_EL7-20.0.1-13090.x86_64.zip"
#download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-RedHat_EL7-20.0.0-3288.x86_64.zip"
#download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-RedHat_EL7-20.0.0-3312.x86_64.zip"
download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-RedHat_EL6-20.0.1-9400.x86_64.zip"
download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-RedHat_EL6-20.0.1-8070.x86_64.zip"
#download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-RedHat_EL6-20.0.0-3288.x86_64.zip"
#download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-RedHat_EL6-20.0.0-3313.x86_64.zip"
download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-Windows-20.0.1-9400.x86_64.zip"
download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-Windows-20.0.1-9400.i386.zip"
#download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-Windows-20.0.0-3288.x86_64.zip"
download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-RedHat_EL9-20.0.1-9400.x86_64.zip"
download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-Ubuntu_18.04-20.0.1-13100.x86_64.zip"
#download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-Ubuntu_18.04-20.0.0-3295.x86_64.zip"
#download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-Ubuntu_18.04-20.0.0-3288.x86_64.zip"
download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-RedHat_EL8-20.0.1-9400.x86_64.zip"
download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-RedHat_EL8-20.0.1-13090.x86_64.zip"
#download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-RedHat_EL8-20.0.0-3288.x86_64.zip"
#download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-RedHat_EL8-20.0.0-3297.x86_64.zip"
download -O "https://files.trendmicro.com/products/deepsecurity/en/20.0/Agent-RedHat_EL9-20.0.1-9400.x86_64.zip"
download -O "http://files.trendmicro.com/products/deepsecurity/en/20.0/KernelSupport-RedHat_EL9-20.0.1-13260.x86_64.zip"

# make a properties file
echo "$(date) -- creating dsm properties file"
echo "AddressAndPortsScreen.ManagerPort=443" >> dsm.props
echo "AddressAndPortsScreen.HeartbeatPort=4120" >> dsm.props
echo "AddressAndPortsScreen.ManagerAddress=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" >> dsm.props
echo "CredentialsScreen.Administrator.Username=${dsmuser}" >> dsm.props
echo "CredentialsScreen.UseStrongPasswords=False" >> dsm.props
echo "CredentialsScreen.Administrator.Password=${dsmpw}" >> dsm.props
echo "SecurityUpdatesScreen.UpdateComponents=True" >> dsm.props
echo "DatabaseScreen.DatabaseType=PostgreSQL" >> dsm.props
echo "DatabaseScreen.Hostname=localhost:5432" >> dsm.props
echo "DatabaseScreen.Username=postgres" >> dsm.props
echo "DatabaseScreen.Password=${dbpw}" >> dsm.props
echo "DatabaseScreen.DatabaseName=dsm" >> dsm.props
echo "SecurityUpdateScreen.UpdateComponents=true" >> dsm.props
echo "SecurityUpdateScreen.UpdateSoftware=true" >> dsm.props
echo "SmartProtectionNetworkScreen.EnableFeedback=false" >> dsm.props
echo "SmartProtectionNetworkScreen.IndustryType=blank" >> dsm.props
echo "RelayScreen.Install=True" >> dsm.props
echo "RelayScreen.AntiMalware=True" >> dsm.props
echo "Override.Automation=True" >> dsm.props
echo "LicenseScreen.License.-1=${ActivationCode}" >> dsm.props
echo "Override.SecurityProfilesFilename=/opt/ChallengePolicies.xml" >> dsm.props

# install manager
echo "$(date) -- installing manager"
chmod 755 Manager-Linux.sh
./Manager-Linux.sh -q -console -varfile dsm.props 
if [ $? -ne 0 ]; then 
  echo "$(date) -- manager install FAILED"
  cat /opt/fastdsm/DeepSecurityInstallerReport.csv 
  exit -1
fi
echo "$(date) -- manager install complete"
chkconfig dsm_s on

# customize dsm
yum -y install perl-XML-Twig
echo "$(date) -- starting manager customization"
download -O https://s3.amazonaws.com/trend-micro-quick-start/v5.1/Common/Scripts/set-aia-settings.sh
chmod 755 set-aia-settings.sh
download -O https://s3.amazonaws.com/trend-micro-quick-start/v3.7/Common/Scripts/set-lbSettings
chmod 755 set-lbSettings
download -O https://raw.githubusercontent.com/deep-security/ops-tools/master/deepsecurity/manager-apis/bash/ds10-rest-cloudAccountCreateWithInstanceRole.sh
chmod 755 ds10-rest-cloudAccountCreateWithInstanceRole.sh
download https://s3.amazonaws.com/trend-micro-quick-start/v5.2/Common/Scripts/dsm_s.service -o /etc/systemd/system/dsm_s.service
chmod 755 /etc/systemd/system/dsm_s.service

​#Create DSMURL in local file for automation
DSMURL=`curl http://169.254.169.254/latest/meta-data/public-hostname`
echo "https://${DSMURL}" > /opt/DSMURL
# Run scripts to customize manager
echo "$(date) -- waiting for manager startup to complete"
until curl -vk https://127.0.0.1:443/rest/status/manager/current/ping; do echo \"manager not started yet\" >> /tmp/4-check-service; service dsm_s start >> /tmp/4-check-service; sleep 30; done
echo "$(date) -- manager startup complete. continuing with API call customizations"
./set-aia-settings.sh ${dsmuser} ${dsmpw} localhost 443
name=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
if [ -z ${name} ]; then name=$(curl http://169.254.169.254/latest/meta-data/public-ipv4); fi
./set-lbSettings ${dsmuser} ${dsmpw} ${name} 443 4120
./ds10-rest-cloudAccountCreateWithInstanceRole.sh ${dsmuser} ${dsmpw} localhost 443

echo "$(date) -- completed manager customizations"
