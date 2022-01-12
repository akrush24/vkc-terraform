### Terraform for deploy new OpenStack stand
Prepare environments

requirements:
- terraform
- git
- unzip
- ./id_rsa # ssh privat key for new stand

```bash
$> ~/source your-openrc-file.sh
$> terraform workspace new overcloud
$> terraform init
```

Create only stand:
```bash
$> terraform apply -var-file=./stage_vars.tfvars
```

Example show output:
```bash
$> terraform output --json vms_fip | jq -r '.[][].address'
10.10.30.56
```

Example create stand and deploy openstack:
```bash
$> ./files/create_stand.sh
```
or if Nexus exist (10.120.120.51 = local nexus ip)
```bash
$> ./files/create_stand.sh 10.120.120.51
```

Destroy stand
```bash
$> terraform destroy -var-file=./stage_vars.tfvars
```
