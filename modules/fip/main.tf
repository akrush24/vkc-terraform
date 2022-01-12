terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.45.0"
    }
  }
}

data "openstack_networking_network_v2" "network" {
  name = var.net
}

data "openstack_networking_subnet_v2" "subnet" {
  name = var.subnet
}

resource "openstack_networking_port_v2" "ports" {
  dns_name   = var.name
  network_id = data.openstack_networking_network_v2.network.id
  # fixed_ip {
  #   subnet_id  = data.openstack_networking_subnet_v2.subnet.id
  #   ip_address = var.ip
  # }
  no_security_groups    = var.port_security_enabled ? false : true
  port_security_enabled = var.port_security_enabled
  security_group_ids    = var.port_security_enabled ? var.security_group : []
}

data "openstack_networking_network_v2" "ext_net" {
  name = var.external_network_name
}

data "openstack_networking_subnet_ids_v2" "ext_subnets" {
  network_id = data.openstack_networking_network_v2.ext_net.id
}

resource "openstack_networking_floatingip_v2" "floatip" {
  count = var.fip ? 1 : 0

  pool       = data.openstack_networking_network_v2.ext_net.name
  subnet_ids = data.openstack_networking_subnet_ids_v2.ext_subnets.ids
}

resource "openstack_networking_floatingip_associate_v2" "fip_1" {
  count = var.fip ? 1 : 0

  floating_ip = openstack_networking_floatingip_v2.floatip[0].address
  port_id     = openstack_networking_port_v2.ports.id
}

output "float_ip" {
  value = openstack_networking_floatingip_v2.floatip
}

output "vip_ip" {
  value = openstack_networking_port_v2.ports.dns_assignment
}
