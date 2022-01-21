#!/bin/bash

set -e
set -x


DEPLOY_USER="centos"
DOMAIN="private.infra.devmail.ru"

# private SSH key for all nodes
# public key stored in overcloud.tfvars parameter public_key
SSH_PARAMS="-i ./id_rsa -o StrictHostKeyChecking=no"


##############
# Create stand
terraform apply -auto-approve -var-file=./overcloud.tfvars
sleep 120


####################
# Prepare for deploy
DEPLOY_EXT_IP=$(terraform output --json vms_fip | jq -r '.[][].address')
KOLLA_EXTERNAL_VIP_ADDRESS=$(terraform output --json vip_ip | jq -r '.[][] | select(."hostname"=="ext") | .ip_address')
KOLLA_INTERNAL_VIP_ADDRESS=$(terraform output --json vip_ip | jq -r '.[][] | select(."hostname"=="int") | .ip_address')
KOLLA_EXTERNAL_VIP_ADDRESS_FIP=$(terraform output --json vip_fip | jq -r '.[][].address')
STAGE=$(terraform output --json vip_fip | jq -r '.[][].address' | awk -F\. '{print $NF}')
if [[ -z ${1} ]]; then
    NEXUS_SERVER=$(terraform output --json vms_network | jq -r '.[] | (.network | .[] | select(."name"=="shared") | .fixed_ip_v4), .name' | awk 'NR%2{printf "%s ",$0;next;}1' | grep deploy | awk '{print $1}')
else
    NEXUS_SERVER=${1}
fi

scp ${SSH_PARAMS} ./id_rsa ${DEPLOY_USER}@${DEPLOY_EXT_IP}:~${DEPLOY_USER}/.ssh/

terraform output --json vms_network | jq -r '.[] | (.network | .[] | select(."name"=="shared") | .fixed_ip_v4), .name' | awk 'NR%2{printf "%s ",$0;next;}1' | ssh ${SSH_PARAMS} ${DEPLOY_USER}@${DEPLOY_EXT_IP} 'sudo tee -a /etc/hosts'

curl -o kolla_overcloud_box2.zip http://nexus.private.infra.devmail.ru/repository/share/kolla_overcloud_box2.zip
rm -rf ./kolla
unzip -P passw0rd ./kolla_overcloud_box2.zip


###################
# Prepare variables
sed -E -i "s#^(kolla_external_vip_address:)\ (.+)#\1\ ${KOLLA_EXTERNAL_VIP_ADDRESS}#" ./kolla/globals.yml
sed -E -i "s#^(kolla_internal_vip_address:)\ (.+)#\1\ ${KOLLA_INTERNAL_VIP_ADDRESS}#" ./kolla/globals.yml
sed -E -i "s#^(deploy_server:)\ (.+)#\1\ \"${NEXUS_SERVER}\"#" ./kolla/globals.yml
sed -E -i "s#(kolla_external_fqdn):\ (.+)#\1:\ \"overcloud${STAGE}.${DOMAIN}\"#" ./kolla/globals.yml
sed -E -i "s#(overcloud)[0-9]{1,3}#\1${STAGE}#" ./kolla/config/mcs-nginx/configuration.json
ssh ${SSH_PARAMS} ${DEPLOY_USER}@${DEPLOY_EXT_IP} 'sudo mkdir /etc/kolla -p;sudo chown centos /etc/kolla;sudo ln -s /home/centos /home/kolla || exit 0'
echo "${KOLLA_INTERNAL_VIP_ADDRESS} int-overcloud${STAGE}.${DOMAIN}" | ssh ${SSH_PARAMS} ${DEPLOY_USER}@${DEPLOY_EXT_IP} 'sudo tee -a /etc/hosts'
echo "${KOLLA_EXTERNAL_VIP_ADDRESS_FIP} overcloud${STAGE}.${DOMAIN}" | ssh ${SSH_PARAMS} ${DEPLOY_USER}@${DEPLOY_EXT_IP} 'sudo tee -a /etc/hosts'
scp ${SSH_PARAMS} -r ./kolla/* ${DEPLOY_USER}@${DEPLOY_EXT_IP}:/etc/kolla


#############################
# Get last kolla-ansible code
rm -rf ./kolla-ansible
GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" \
git clone -b 'release/mcs/private/v2.0.0' git@gitlab.corp.mail.ru:infra/private/kolla-ansible.git kolla-ansible
scp ${SSH_PARAMS} -r kolla-ansible ${DEPLOY_USER}@${DEPLOY_EXT_IP}:/home/${DEPLOY_USER}
scp ${SSH_PARAMS} ./files/octavia.sh ${DEPLOY_USER}@${DEPLOY_EXT_IP}:/home/${DEPLOY_USER}/
scp ${SSH_PARAMS} ./files/prepare_deploy.sh ${DEPLOY_USER}@${DEPLOY_EXT_IP}:/home/${DEPLOY_USER}/
scp ${SSH_PARAMS} ./files/deploy.sh ${DEPLOY_USER}@${DEPLOY_EXT_IP}:/home/${DEPLOY_USER}/


####################
# Run product deploy
ssh ${SSH_PARAMS} ${DEPLOY_USER}@${DEPLOY_EXT_IP} "bash /home/${DEPLOY_USER}/prepare_deploy.sh ${NEXUS_SERVER} ${1}" 
ssh ${SSH_PARAMS} ${DEPLOY_USER}@${DEPLOY_EXT_IP} "bash /home/${DEPLOY_USER}/deploy.sh ${NEXUS_SERVER}"


###############
# Finish output
set +x
echo "URL: https://overcloud${STAGE}.${DOMAIN}"
echo "DEPLOY_EXT_IP: ${DEPLOY_EXT_IP}"
echo "KOLLA_EXTERNAL_VIP_ADDRESS: ${KOLLA_EXTERNAL_VIP_ADDRESS}"
echo "KOLLA_INTERNAL_VIP_ADDRESS: ${KOLLA_INTERNAL_VIP_ADDRESS}"
echo "NEXUS_SERVER: ${NEXUS_SERVER}"


###############################################
# Here will be the launch of cloud test scripts


###  Destroy Stand
# set -x
# terraform destroy -auto-approve -var-file=./overcloud.tfvars
