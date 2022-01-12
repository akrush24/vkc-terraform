terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.45.0"
    }
  }
}


data "openstack_networking_network_v2" "ext_net" {
  name = var.external_network_name
}

module "create_network" {
  for_each = var.networks

  source = "./modules/network"

  network_name    = each.key
  gateway_ip      = each.value.gateway_ip
  dns_nameservers = each.value.dns_nameservers
  cidr            = each.value.cidr
  routed          = each.value.routed
  enable_dhcp     = each.value.enable_dhcp
  admin_state_up  = each.value.admin_state_up
  router_id       = openstack_networking_router_v2.router.id
  mtu             = each.value.mtu
}

module "fip" {
  for_each = var.vip

  source                = "./modules/fip"
  name                  = each.key
  fip                   = each.value.fip
  ip                    = each.value.ip
  net                   = each.value.net
  subnet                = each.value.subnet
  port_security_enabled = each.value.port_security_enabled
  security_group        = each.value.security_group
  external_network_name = var.external_network_name
  depends_on = [
    module.create_network
  ]
}

resource "openstack_networking_router_v2" "router" {
  admin_state_up      = true
  name                = var.router_name
  external_network_id = data.openstack_networking_network_v2.ext_net.id
}

resource "openstack_compute_keypair_v2" "autodeploykeypair" {
  name       = var.public_key_name
  public_key = var.public_key
}

module "create_instance" {
  for_each = var.instances

  source = "./modules/instance"

  instance_name     = each.key
  volumes           = each.value.volumes
  interfaces        = each.value.interfaces
  networks          = module.create_network
  availability_zone = var.availability_zone
  image_name        = var.image_name
  flavor_name       = each.value.flavor_name
  key_pair          = openstack_compute_keypair_v2.autodeploykeypair.name
  user_data         = each.value.user_data
  depends_on = [
    module.create_network,
    openstack_compute_keypair_v2.autodeploykeypair
  ]
  fip = each.value.fip
}

output "vms_fip" {
  value = [
    for ip in module.create_instance : ip.floatip if ip.floatip != []
  ]
}

output "vip_ip" {
  value = [
    for ip in module.fip : ip.vip_ip if ip.vip_ip != []
  ]
}

output "vip_fip" {
  value = [
    for ip in module.fip : ip.float_ip if ip.float_ip != []
  ]
}

output "vms_network" {
  sensitive = true
  value = [
    for inst in module.create_instance : inst.vms_network
  ]
}

output "vms_ports" {
  value = [
    for inst in module.create_instance : inst.vms_ports
  ]
}
