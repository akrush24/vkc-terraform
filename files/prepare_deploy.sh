#!/bin/bash
# ./prepare_deploy.sh <DEPLOY_NODE_IP:REQ> <PREARE_NEXUS:YES>

set -e
set -x

NEXUS3_VERSION=3.36.0
RELEASE="202201"
DEPLOY_USER="centos"

DEPLOY_NODE_IP_ADDR=${1}
DEPLOY_NEXUS=${2}
export DEPLOY_NODE_IP_ADDR

echo -e "Host *\n    StrictHostKeyChecking no" > /home/centos/.ssh/config
chmod 0600 /home/centos/.ssh/config
chmod 0600 /home/centos/.ssh/id_rsa

if [[ -z ${DEPLOY_NEXUS} ]]; then

    ################################################
    ### Download NEXUS Isolate Box2.0 repositoyr ###
    export https_proxy="http://rs1.stage.dev-compute.i:13128"
    curl http://distro-box2.0.hb.bizmrg.com/${RELEASE}/nexus-${RELEASE}.tar -o nexus-${RELEASE}.tar
    unset https_proxy
    tar xf nexus-${RELEASE}.tar
    ##

    cd nexus-${RELEASE}
    tar xvf docker-rpms.tar.gz
    cd docker-rpms/
    sudo yum install *.rpm -y
    sudo usermod -aG docker ${DEPLOY_USER}
    sudo systemctl enable --now docker
    cd ..
    sudo docker load -i nexus3_${NEXUS3_VERSION}.tar.gz
    sudo docker volume create nexus
    sudo tar -xvf volume-nexus.tar.gz --directory /
    sudo -E bash -c '
    cat >/etc/docker/daemon.json <<EOF
{   
    "insecure-registries": [
        "127.0.0.1:5000",
        "${DEPLOY_NODE_IP_ADDR}:5000"
    ],
    "log-opts": {
        "max-file": "5",
        "max-size": "50m"
    }
}
EOF
'
    sudo systemctl restart docker

    ############################
    #### Run Nexus container ###
    sudo docker run --name nexus3 \
        --runtime runc \
        --net host \
        -v nexus:/nexus-data \
        --restart always \
        -e 'SONATYPE_WORK=/opt/sonatype/sonatype-work' \
        -e 'NEXUS_DATA=/nexus-data' \
        -e 'INSTALL4J_ADD_VM_PARAMS=-Xms1200m -Xmx1200m -XX:MaxDirectMemorySize=2g -Djava.util.prefs.userRoot=/nexus-data/javaprefs' \
        -e 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
        -e 'container=oci' \
        -e 'SONATYPE_DIR=/opt/sonatype' \
        -e 'NEXUS_CONTEXT=' \
        -e 'DOCKER_TYPE=rh-docker' \
        -e 'NEXUS_HOME=/opt/sonatype/nexus' \
        -d sonatype/nexus3:${NEXUS3_VERSION} 'sh' '-c' '${SONATYPE_DIR}/start-nexus-repository-manager.sh'

    sleep 120

    curl ${DEPLOY_NODE_IP_ADDR}:5000/v2/_catalog
    curl ${DEPLOY_NODE_IP_ADDR}:8081
    docker login -uadmin -ppassw0rd 127.0.0.1:5000
fi

##########################
### Prepare repository ###
for file in $(/bin/ls -1 /etc/yum.repos.d/*.repo | grep -v Nexus-Local); do 
    sudo mv $file $file.bkp
done
sudo -E bash -c '
cat > /etc/yum.repos.d/Nexus-Local.repo <<EOF
#Base repo
[nexus-base]
name=CentOS-7 - Base
baseurl=http://${DEPLOY_NODE_IP_ADDR}:8081/repository/yum-base/7/os/x86_64/
gpgcheck=0
[nexus-updates]
name=CentOS-7 - Updates
baseurl=http://${DEPLOY_NODE_IP_ADDR}:8081/repository/yum-updates/7/updates/x86_64/
gpgcheck=0
[nexus-extras]
name=CentOS-7 - Extras
baseurl=http://${DEPLOY_NODE_IP_ADDR}:8081/repository/yum-extras/7/extras/x86_64/
gpgcheck=0
[nexus-centosplus]
name=CentOS-7 - Plus
baseurl=http://${DEPLOY_NODE_IP_ADDR}:8081/repository/yum-centosplus/7/centosplus/x86_64/
gpgcheck=0
enabled=0
#EPEL repo
[nexus-epel]
name=CentOS-7 - Base
baseurl=http://${DEPLOY_NODE_IP_ADDR}:8081/repository/yum-epel/7/x86_64/
gpgcheck=0
[nexus-epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - x86_64 - Debug
baseurl=http://${DEPLOY_NODE_IP_ADDR}:8081/repository/yum-epel/7/x86_64/debug
failovermethod=priority
enabled=0
gpgcheck=0
[nexus-epel-source]
name=Extra Packages for Enterprise Linux 7 - x86_64 - Source
baseurl=http://${DEPLOY_NODE_IP_ADDR}:8081/repository/yum-epel/7/SRPMS
failovermethod=priority
enabled=0
gpgcheck=0
[nexus-docker-ce-stable]
name=Docker CE Stable - x86_64
baseurl=http://${DEPLOY_NODE_IP_ADDR}:8081/repository/yum-docker-ce-stable/7/x86_64/stable
enabled=1
gpgcheck=0
EOF
'
sudo yum -y install python-pip python3 python3-devel gcc jq
mkdir -pv ~/.pip
cat >  ~/.pip/pip.conf<<EOF
[global]
index = http://${DEPLOY_NODE_IP_ADDR}:8081/repository/kolla-pip/pypi
index-url = http://${DEPLOY_NODE_IP_ADDR}:8081/repository/kolla-pip/simple
trusted-host = ${DEPLOY_NODE_IP_ADDR}
EOF
cd ~/
curl -o venv.tar.gz "http://${DEPLOY_NODE_IP_ADDR}:8081/repository/share/venv.tar.gz"
tar xf venv.tar.gz
source ~/venv/bin/activate
ansible --version

ansible -i /etc/kolla/multinode-mcs control,compute -b -m shell -a 'for file in $(/bin/ls -1 /etc/yum.repos.d/*.repo | grep -v Nexus-Local); do mv $file $file.bkp;done'
ansible -i /etc/kolla/multinode-mcs control,compute -b -m copy -a 'src=/etc/yum.repos.d/Nexus-Local.repo dest=/etc/yum.repos.d/Nexus-Local.repo'

### ставим докер на деплой узел, если нексус идет удаленный
if [[ ! -z ${DEPLOY_NEXUS} ]]; then
    sudo yum -y install docker-ce
    sudo usermod -aG docker centos
    sudo mkdir -p /etc/docker/
    sudo -E bash -c '
    cat >/etc/docker/daemon.json <<EOF
{   
    "insecure-registries": [
        "127.0.0.1:5000",
        "${DEPLOY_NODE_IP_ADDR}:5000"
    ],
    "log-opts": {
        "max-file": "5",
        "max-size": "50m"
    }
}
EOF
'
    sudo systemctl enable docker --now
fi
