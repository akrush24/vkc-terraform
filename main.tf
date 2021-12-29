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
}

module "fip" {
  for_each = var.vip

  source = "./modules/fip"

  fip                   = each.value.fip
  ip                    = each.value.ip
  net                   = each.value.net
  port_security_enabled = each.value.port_security_enabled
  security_group        = each.value.security_group
  external_network_name = var.external_network_name
}

resource "openstack_networking_router_v2" "router" {
  admin_state_up      = true
  name                = var.router_name
  external_network_id = data.openstack_networking_network_v2.ext_net.id
}

module "create_instance" {
  for_each = var.instances

  source = "./modules/instance"

  instance_name     = each.key
  volumes           = each.value.volumes
  interfaces        = each.value.interfaces
  networks          = module.create_network #var.networks
  availability_zone = var.availability_zone
  image_name        = var.image_name
  flavor_name       = each.value.flavor_name
  key_pair          = var.key_pair
}

# output "volumes" {
#   value = module.create_instance["vkc01ctrl02"].volumes
# }

# output "port" {
#   value = module.create_instance["vkc01ctrl02"].port
# }

# output "network" {
#   value = module.create_network
# }
