terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.45.0"
    }
  }
}

## create network
resource "openstack_networking_network_v2" "network" {
  name           = var.network_name
  admin_state_up = var.admin_state_up
}

## create subnet
resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${var.network_name}_subnet"
  network_id      = openstack_networking_network_v2.network.id
  cidr            = var.cidr
  dns_nameservers = var.dns_nameservers
  enable_dhcp     = var.enable_dhcp
  ip_version      = 4
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  count     = var.routed ? 1 : 0
  router_id = var.router_id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}


output "networks" {
  value = openstack_networking_network_v2.network
}
