#!/bin/bash

source "/home/centos/venv/bin/activate"
source "/etc/kolla/admin-openrc.sh"
KOLLA=~/kolla-ansible/tools/kolla-ansible
KOLLA_INV=/etc/kolla/multinode-mcs

openstack network create --no-share --internal --project service octavia-int-net
openstack subnet create \
    --project service \
    --ip-version 4 \
    --network octavia-int-net \
    --gateway 172.31.0.1 \
    --allocation-pool start=172.31.1.10,end=172.31.250.200 \
    --subnet-range 172.31.0.0/16 \
    octavia-int-subnet

for i in $(seq 3); do
    openstack port create --network octavia-int-net --fixed-ip subnet=octavia-int-subnet,ip-address=172.31.0.1${i} --device octavia-lb --device-owner octavia:lb --host controller0${i} ''
done

for port in $(openstack port list --network octavia-int-net -f value | grep 172.31.0.1[1-3] | awk '{print $1}');
do 
    openstack port show ${port} -c binding_host_id -c id -c mac_address -c fixed_ips -f value | awk 'NR%4{printf "%s ",$0;next;}1';
done | \
    while read port;
    do 
        echo -e "#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#\n"
        ID=$(echo $port | awk '{print $6}');
        MAC=$(echo $port | awk '{print $NF}');
        HOST=$(echo $port | awk '{print $1}');
        IP=$(echo $port | awk -F \' '{print $8}');
        echo "HOST: ${HOST}"
        echo "
ssh ${HOST} 'echo \"HOSTANME: \${HOSTNAME}\";
docker exec -i openvswitch_vswitchd sh -c \
\"ovs-vsctl -- --may-exist add-port br-int tapoctavia1 -- \
set Interface tapoctavia1 type=internal -- \
set Interface tapoctavia1 external-ids:iface-id=${ID} -- \
set Interface tapoctavia1 external-ids:iface-status=active -- \
set Interface tapoctavia1 external-ids:attached-mac=${MAC}\";
echo | sudo tee /etc/sysconfig/network-scripts/ifcfg-tapoctavia1<<EOF
DEVICE=tapoctavia1
ONBOOT=yes
DEVICETYPE=ovs
TYPE=OVSIntPort
OVS_BRIDGE=br-int
OVS_EXTRA=\"set Interface ${DEVICE} type=internal external-ids:iface-id=${ID} external-ids:iface-status=active external-ids:attached-mac=${MAC}\"
NETMASK1=255.255.0.0
IPADDR1=${IP}
MACADDR=${MAC}
MTU=1400
EOF
sudo ifup tapoctavia1'" | bash;
    done


### Check
ansible -i /etc/kolla/multinode-mcs control -b -m shell -a 'ls -l /etc/sysconfig/network-scripts/ifcfg-tapoctavia1'
ansible -i /etc/kolla/multinode-mcs control -b -m shell -a 'docker exec -it openvswitch_vswitchd sh -c "ovs-vsctl get interface tapoctavia1 external-ids:attached-mac;ovs-vsctl get interface tapoctavia1 external-ids:iface-id"'


######################
### Deploy Octavia ###
sed -E -i 's/^enable_octavia:.+/enable_octavia: true/' /etc/kolla/globals.yml
EXTRA_OPTS='--diff' ${KOLLA} -i ${KOLLA_INV} deploy --tags octavia || exit 0
