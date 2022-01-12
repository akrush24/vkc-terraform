terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.45.0"
    }
  }
}

data "openstack_images_image_v2" "image" {
  name = var.image_name
}

resource "openstack_blockstorage_volume_v3" "volumes" {
  for_each = var.volumes

  image_id             = each.value.from_image ? data.openstack_images_image_v2.image.id : ""
  name                 = "${each.key}-${var.instance_name}"
  size                 = each.value.size
  volume_type          = each.value.type
  availability_zone    = var.availability_zone
  enable_online_resize = true
}


data "openstack_networking_network_v2" "networks" {
  for_each = var.interfaces

  name = each.value.name
}

data "openstack_networking_subnet_v2" "subnets" {
  for_each = var.interfaces

  name = each.value.subnet
}


resource "openstack_networking_port_v2" "ports" {
  for_each = var.interfaces

  name = "${var.instance_name}_${each.key}"

  network_id = data.openstack_networking_network_v2.networks[each.key].id

  # fixed_ip {
  #   subnet_id  = data.openstack_networking_subnet_v2.subnets[each.key].id
  #   ip_address = each.value.ip != "" ? each.value.ip : null
  # }
  no_security_groups    = each.value.port_security_enabled ? false : true
  port_security_enabled = each.value.port_security_enabled
  security_group_ids    = each.value.port_security_enabled ? each.value.security_group : []

  dynamic "allowed_address_pairs" {
    for_each = each.value.port_security_enabled ? each.value.allowed_address_pairs : []

    content {
      ip_address = allowed_address_pairs.value
    }
  }

}

# create instance
resource "openstack_compute_instance_v2" "instance" {
  name         = var.instance_name
  key_pair     = var.key_pair
  flavor_name  = var.flavor_name
  config_drive = true

  dynamic "network" {
    for_each = var.interfaces

    content {
      name = network.value.name
      port = openstack_networking_port_v2.ports[network.key].id
      #access_network = network.value.access_network
    }
  }

  dynamic "block_device" {
    for_each = var.volumes

    content {
      uuid                  = openstack_blockstorage_volume_v3.volumes[block_device.key].id
      source_type           = "volume"
      destination_type      = "volume"
      delete_on_termination = false
      boot_index            = block_device.value.from_image == true ? 0 : 1
    }

  }

  user_data = var.user_data != "" ? var.user_data : null

  # do not delete the instance if the user_data has changed
  lifecycle {
    ignore_changes = [
      #user_data
    ]
  }
}

output "volumes" {
  value = openstack_blockstorage_volume_v3.volumes
}

output "port" {
  value = openstack_networking_port_v2.ports
}

data "openstack_networking_network_v2" "ext_net" {
  name = "external"
}

data "openstack_networking_subnet_ids_v2" "ext_subnets" {
  network_id = data.openstack_networking_network_v2.ext_net.id
}

resource "openstack_networking_floatingip_v2" "floatip" {
  count = var.fip ? 1 : 0

  pool       = data.openstack_networking_network_v2.ext_net.name
  subnet_ids = data.openstack_networking_subnet_ids_v2.ext_subnets.ids
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  count = var.fip ? 1 : 0

  floating_ip           = openstack_networking_floatingip_v2.floatip[0].address
  instance_id           = openstack_compute_instance_v2.instance.id
  wait_until_associated = true
}

output "floatip" {
  value = openstack_networking_floatingip_v2.floatip
}

output "vms_network" {
  value = openstack_compute_instance_v2.instance
}

output "vms_ports" {
  value = openstack_networking_port_v2.ports
}
