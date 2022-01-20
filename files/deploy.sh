#!/bin/bash

set -x
set -e

DEPLOY_NODE_IP_ADDR=${1}


######################
### Deploy product ###
source "/home/centos/venv/bin/activate"
KOLLA=~/kolla-ansible/tools/kolla-ansible
KOLLA_INV=/etc/kolla/multinode-mcs
ansible -i /etc/kolla/multinode-mcs compute -b -m shell -a 'yum install -y lvm2;pvcreate /dev/vdb;vgcreate cinder-volumes /dev/vdb'

EXTRA_OPTS='--diff' ${KOLLA} -i ${KOLLA_INV} bootstrap-servers
EXTRA_OPTS='--diff' ${KOLLA} -i ${KOLLA_INV} prechecks
EXTRA_OPTS='--diff' ${KOLLA} -i ${KOLLA_INV} deploy --tags chrony,haproxy,mariadb,rabbitmq,memcached,etcd,keycloak
EXTRA_OPTS='--diff' ${KOLLA} -i ${KOLLA_INV} deploy --tags mcs-tarantool,mcs-nginx,mcs-static,mcs-zephyr,mcs-frost,mcs-sundog,mcs-owl,mlscs-ocean,mcs-haar
set +e
EXTRA_OPTS='--diff' ${KOLLA} -i ${KOLLA_INV} deploy --tags keystone
set -e
EXTRA_OPTS='--diff' ${KOLLA} -i ${KOLLA_INV} deploy --tags keystone
EXTRA_OPTS='--diff -b' ${KOLLA} -i ${KOLLA_INV} deploy
EXTRA_OPTS='--diff' ${KOLLA} -i ${KOLLA_INV} post-deploy
ansible -i /etc/kolla/multinode-mcs control,compute -b -m shell -a 'usermod -aG docker centos'
docker run -d -t \
    --name kolla_ansible \
    -v /etc/hosts:/etc/hosts \
    -v /etc/kolla:/etc/kolla \
    -v ~/.ssh:/home/kolla/.ssh \
    -v ~/kolla-ansible/:/home/kolla/kolla-ansible/ \
    --restart no \
    -h kolla-ansible \
    -e 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
    -e 'sh' \
    --entrypoint "bash" \
${DEPLOY_NODE_IP_ADDR}:5000/box/kolla-ansible
docker exec -i kolla_ansible bash -c 'source ~/kolla-venv/bin/activate;~/kolla-ansible/tools/kolla-ansible -i /etc/kolla/multinode-mcs mcs-post-deploy'


# #################
# ### Configure ###
source /etc/kolla/admin-openrc.sh
openstack aggregate create --zone AZ1 AZ1
openstack aggregate add host AZ1 compute01
### Create ext-net
openstack network create --external --share --mtu 1400 ext-net
openstack subnet create \
    --dhcp \
    --subnet-range 192.168.1.0/24 \
    --gateway 192.168.1.1 \
    --allocation-pool start=192.168.1.100,end=192.168.1.150 \
    --network ext-net \
ext-subnet
### configuration Octavia interfaces ###
set +e
/home/centos/octavia.sh
set -e

# ###################
# ### Quick check ###
ansible -i /etc/kolla/multinode-mcs control -b -m shell -a 'docker ps -a | grep -v Up'
openstack endpoint list
openstack service list
openstack compute service list
openstack host list
openstack network agent list
openstack network list
openstack volume service list
openstack volume type list
